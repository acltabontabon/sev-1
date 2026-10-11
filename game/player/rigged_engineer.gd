extends Node3D
## The on-call engineer: Quaternius CC0 body and motion, plus an optional locally
## licensed two-handed attack. Reads combat state only; never starts attacks or applies
## damage. Same contract as the native fallback (character_presentation.gd): reset_pose(),
## defeat(), story_pose, sit, crouch and the keyboard `weapon`.
##
## Full-body combat clips follow the melee clock. The sword follows an authored arc
## in character space and two-bone IK pulls both arms onto its grip, so the visible
## strike matches the damage window. Shoulder carry returns between fights.

enum Pose { NONE, LOOK_DOWN, LOOK_UP, TYPING, ALERT, SLUMP, SIP, RELAX, GLANCE, ARMED, FINISH, RAGE }
const SEATED: Array[int] = [Pose.TYPING, Pose.ALERT, Pose.SLUMP, Pose.SIP, Pose.RELAX, Pose.GLANCE]
const ANIMATIONS: AnimationLibrary = preload("res://game/player/engineer_animations.res")
## The developer outfit: hoodie, joggers and sneakers on the stock body's own skin.
const OUTFIT: ArrayMesh = preload("res://assets/characters/hero_outfit/dev_hoodie.res")
const SWORD_TRIAL: String = "res://assets/characters/kevin_trial/sword_trial.res"
## Source clip phases: anticipation ends, cutting motion ends. The melee clock owns
## playback, including hit-stop; animation never drives damage or controller travel.
const SWORD_PHASES: Vector2 = Vector2(.36, .64)
const KEVIN_PHASES: Vector2 = Vector2(.44, .65)
## Weapon space: where each fist closes on the grip.
const RIGHT_GRIP: Vector3 = Vector3(0, 0, -.2)
const LEFT_GRIP: Vector3 = Vector3(0, 0, -.08)
## Desk staging: the chair sits at the origin, the keyboard about half a metre ahead.
## The combo's elements, one per step: wind, lightning, fire. Presentation only.
const ELEMENTS: Array[Dictionary] = [
	{"call": "FORCE PUSH", "color": Color(.55, 1, .92)},
	{"call": "HOT RELOAD", "color": Color(.72, .52, 1)},
	{"call": "HOTFIX", "color": Color(1, .52, .14)},
]
## Fist centres clear the .8225 m tabletop and the keyboard, including hand thickness.
const DESK_HANDS: Array[Vector3] = [Vector3(-.17, .9, -.5), Vector3(.13, .9, -.5)]
## Hidden during seated desk staging; the existing rest transform remains available.
const SEATED_SWORD: Transform3D = Transform3D(Basis(Vector3.RIGHT, -PI * .5), Vector3(1.45, 2.34, -.87))
## The sitting clip was authored for a lower stool set further back: seated, the body
## places the skinned trouser seat at the .56 m cushion, not just the pelvis bone.
const SEATED_OFFSET: Vector3 = Vector3(0, .24, -.3)


@export var model_scale: float = .64
@export var use_local_sword_trial: bool = true
## Ground speed the run clip's planted feet travel at rate 1.0 (measured: about 3 m/s);
## playback scales from it so the feet stay planted instead of skating.
@export var run_reference_speed: float = 3.4
var story_pose: int = 0
## Local cinematic prop contacts, in character space. Empty during gameplay.
var story_hand_targets: Array[Vector3] = []
## Staged travel has no move_and_slide floor update; its pace drives the walk clip.
var story_walk_speed: float = 0.0
var story_sit_progress: float = -1.0
var sit: float = 0.0
var crouch: float = 0.0
## 0..1, set by the incident's battle-mode director: eyes and keyboard light up.
var battle: float = 0.0
var clock: float = 0.0
var phase: float = -1.0
var step_clip: StringName = &""
## The finisher kill cam's swing (Pose.FINISH): which authored strike (0 cleave, 1
## spinning backhand, 2 leaping slam) and how far through it (0..1), set by the camera.
var finish_style: int = 0
var finish_progress: float = 0.0
## A local duel director samples the body and sword together on its real-time clock.
var duel_active: bool = false
## The finisher's timeline as fractions: wind-up, strike, then the follow-through.
const FINISH_TIMING: Vector3 = Vector3(.16, .5, .34)
## Attacks and specials snap the body's facing to the aim at once (hitboxes need it);
## the model catches up over a few frames instead of flipping in one.
var yaw_lag: float = 0.0
var last_facing: float = 0.0
const YAW_CATCH_UP: float = 22.0
var previous_position: Vector3
var actor: CharacterBody3D
var hands: Array[Vector3] = DESK_HANDS.duplicate()
var head_turn: Vector2 = Vector2.ZERO
var lean: float = 0.0
var spin: float = 0.0
## Visual-only body offsets for the moves: forward lunge and leap height.
var lunge: float = 0.0
var lift: float = 0.0
var held: float = 1.0
var right_reach: float = 0.0
var left_reach: float = 0.0
var standing_left: float = 0.0
var shoulder_rest: float = 0.0
var was_seated: bool = false
var skeleton: Skeleton3D
var animator: AnimationPlayer
var right_ik: TwoBoneIK3D
var left_ik: TwoBoneIK3D
var eye_material: StandardMaterial3D
var hair_material: StandardMaterial3D
## Unpaid Overtime: the form he takes after watching the night shift die. Gold hair and
## eyes, a gold flame aura and crackling arcs, until the run restarts. Presentation only.
var overtime_on: bool = false
var overtime_aura: Node3D
var overtime_crackle: float = 0.0
var overtime_strength: float = 0.0
var overtime_hair: Node3D
var overtime_hair_material: StandardMaterial3D
var rim_materials: Array[StandardMaterial3D] = []
## Outfit lights as [material, idle energy, battle energy]: LEDs, lenses, soles.
var gear_glow: Array[Array] = []
var print_labels: Array[Label3D] = []
var watch_screen: StandardMaterial3D
var back_kit: Node3D
var bones: Dictionary = {}
var striking: bool = false
var called_out: bool = false
var hit_hooked: bool = false
## Fist bone space to weapon pivot, measured once from the idle grip (see _measure_grip).
var hand_to_weapon: Transform3D = Transform3D.IDENTITY
@onready var model: Node3D = $Model
@onready var weapon: Node3D = $WeaponPivot
@onready var blade_art: Node3D = $WeaponPivot/EscalationBlade
@onready var trail: MeshInstance3D = $WeaponTrail
@onready var right_target: Node3D = $RightTarget
@onready var left_target: Node3D = $LeftTarget
@onready var right_pole: Node3D = $RightPole
@onready var left_pole: Node3D = $LeftPole


func _ready() -> void:
	# Null outside a player, e.g. the menu desk: the scene is then staged only.
	actor = get_parent().get_parent() as CharacterBody3D
	# Read the completed controller/melee tick, including hit-stop and cancellation.
	process_physics_priority = 10
	skeleton = model.find_child("Skeleton3D", true, false)
	animator = model.find_child("AnimationPlayer", true, false)
	animator.add_animation_library("rig", ANIMATIONS)
	if use_local_sword_trial and ResourceLoader.exists(SWORD_TRIAL):
		var trial: AnimationLibrary = load(SWORD_TRIAL) as AnimationLibrary
		if trial != null and trial.has_animation("kevin_2h"):
			animator.add_animation_library("sword_trial", trial)
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	for bone in ["Body", "Abdomen", "Torso", "Head", "Fist.R"]:
		bones[bone] = skeleton.find_bone(bone)
	right_ik = _ik("UpperArm.R", "LowerArm.R", "Fist.R", right_target, right_pole)
	left_ik = _ik("UpperArm.L", "LowerArm.L", "Fist.L", left_target, left_pole)
	trail.source = weapon
	_dress()
	_measure_grip()
	reset_pose()


func reset_pose() -> void:
	duel_active = false
	story_hand_targets.clear()
	story_walk_speed = 0.0
	story_sit_progress = -1.0
	if actor != null:
		process_mode = Node.PROCESS_MODE_INHERIT
	phase = -1.0
	finish_progress = 0.0
	yaw_lag = 0.0
	last_facing = get_parent().rotation.y if get_parent() != null else 0.0
	clock = 0.0
	crouch = 0.0
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	sit = 0.0
	lean = 0.0
	spin = 0.0
	lunge = 0.0
	lift = 0.0
	head_turn = Vector2.ZERO
	held = 1.0
	right_reach = 0.0
	left_reach = 0.0
	standing_left = 0.0
	was_seated = false
	previous_position = actor.global_position if actor != null else global_position
	trail.clear()
	striking = false
	ElementFx.clear_from(self)
	animator.play("rig/idle", 0.0)
	animator.seek(0.0, true)
	_solve(0.0)


func defeat() -> void:
	# The fall plays out before the report (headless suites settle on the last frame).
	crouch = .48
	held = 0.0
	right_reach = 0.0
	left_reach = 0.0
	# Let go of the shoulder carry: the keyboard stays where it drops.
	shoulder_rest = 0.0
	trail.clear()
	animator.play("rig/death", .12)
	animator.speed_scale = 1.0
	# The report pauses the game; the fall keeps playing behind it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		animator.seek(animator.current_animation_length, true)
	# The keyboard clatters to the carpet beside the body.
	weapon.position = Vector3(.45, .06, -.35)
	weapon.rotation = Vector3(0, .5, 0)
	_solve(0.0)


## Where the keyboard sits when the right fist simply holds it.
## The hero pose: the blade resting on the right shoulder, pointing back and up.
func shoulder_transform() -> Transform3D:
	# Guts-style: the blade stands edge-on, its lower edge resting on the outer right
	# shoulder and the flat facing sideways; it runs back, up and a little outward (clear
	# of the big head), the grip low in front of the chest.
	var along: Vector3 = Vector3(.25, .5, .83).normalized()
	var basis: Basis = Basis.looking_at(along, Vector3.RIGHT)
	var edge: Vector3 = Vector3(.43, 1.27, .02)
	# Width (local X) points up: lift the centre line half a blade above the resting edge.
	var center: Vector3 = edge + basis.x * .12
	return Transform3D(basis, center - along * .75)


func carry_transform() -> Transform3D:
	var to_character: Transform3D = global_transform.affine_inverse() * skeleton.global_transform
	var fist: Transform3D = (to_character * skeleton.get_bone_global_pose(bones["Fist.R"])).orthonormalized()
	return fist * hand_to_weapon


## Hold the keyboard like a sword in the idle stance: blade up and forward, keys facing
## outward, grip centred in the fist. Every other clip then carries it consistently.
func _measure_grip() -> void:
	animator.play("rig/idle", 0.0)
	animator.seek(0.0, true)
	var to_character: Transform3D = global_transform.affine_inverse() * skeleton.global_transform
	var fist: Transform3D = (to_character * skeleton.get_bone_global_pose(bones["Fist.R"])).orthonormalized()
	var blade: Vector3 = Vector3(.5, .3, -.81).normalized()
	var grip: Vector3 = fist.origin + fist.basis.y * .07
	var held_pose: Transform3D = Transform3D(Basis.looking_at(blade, Vector3.RIGHT), grip - blade * .22)
	hand_to_weapon = fist.affine_inverse() * held_pose


## Preview tooling only: hold a library clip at a fraction of its length, IK off.
var preview_clip: String = ""
var preview_at: float = 0.0


func overtime(on: bool) -> void:
	overtime_on = on
	overtime_strength = 1.0 if on else 0.0
	_shape_overtime_hair(overtime_strength)
	if hair_material != null:
		hair_material.albedo_color = Color(1, .8, .25) if on else Color(.05, .04, .04)
		hair_material.emission_energy_multiplier = 1.1 if on else 0.0
		_blend_overtime_hair(overtime_strength)
	if eye_material != null:
		eye_material.emission = Color(1, .8, .3) if on else Color(.35, .95, 1.0)
	if is_instance_valid(overtime_aura):
		overtime_aura.queue_free()
		overtime_aura = null
	if not on:
		return
	overtime_aura = Node3D.new()
	add_child(overtime_aura)
	var flames: CPUParticles3D = CPUParticles3D.new()
	flames.amount = 70
	flames.lifetime = .7
	flames.mesh = ElementFx._dot_mesh(.3)
	flames.local_coords = false
	flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flames.emission_sphere_radius = .45
	flames.position = Vector3.UP * .8
	flames.direction = Vector3.UP
	flames.spread = 12.0
	flames.gravity = Vector3.UP * 2.5
	flames.initial_velocity_min = 1.2
	flames.initial_velocity_max = 2.6
	flames.scale_amount_min = .7
	flames.scale_amount_max = 1.5
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(1, .95, .6, .9))
	ramp.set_color(1, Color(1, .55, .1, 0.0))
	flames.color_ramp = ramp
	overtime_aura.add_child(flames)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.light_color = Color(1, .75, .3)
	glow.light_energy = 2.2
	glow.omni_range = 4.0
	glow.position = Vector3.UP * 1.1
	overtime_aura.add_child(glow)


## Cinematic buildup: the form only locks in when the charge reaches one.
func overtime_charge(amount: float) -> void:
	if not is_instance_valid(overtime_aura):
		overtime(true)
	overtime_strength = clampf(amount, 0.0, 1.0)
	overtime_on = overtime_strength >= .999
	var gold: float = smoothstep(.35, 1.0, overtime_strength)
	_shape_overtime_hair(overtime_strength)
	hair_material.albedo_color = Color(.05, .04, .04).lerp(Color(1, .8, .25), gold)
	hair_material.emission_energy_multiplier = gold * 1.1
	_blend_overtime_hair(overtime_strength)
	eye_material.emission = Color(.35, .95, 1.0).lerp(Color(1, .8, .3), gold)
	for child in overtime_aura.get_children():
		if child is CPUParticles3D:
			child.scale_amount_min = .7 * overtime_strength
			child.scale_amount_max = 1.5 * overtime_strength
		elif child is OmniLight3D:
			child.light_energy = 2.2 * overtime_strength


## The gold runs out slowly: the aura thins, the light and the hair dim, then he is just
## a tired engineer again.
func overtime_fade(seconds: float) -> void:
	if not overtime_on or not is_instance_valid(overtime_aura):
		overtime(false)
		return
	var fade: Tween = create_tween()
	fade.set_parallel(true)
	for child in overtime_aura.get_children():
		if child is CPUParticles3D:
			fade.tween_property(child, "scale_amount_max", .05, seconds * .8)
			fade.tween_property(child, "scale_amount_min", .02, seconds * .8)
			fade.tween_property(child, "initial_velocity_max", .4, seconds * .8)
		elif child is OmniLight3D:
			fade.tween_property(child, "light_energy", 0.0, seconds)
	if hair_material != null:
		fade.tween_property(hair_material, "emission_energy_multiplier", 0.0, seconds)
		fade.tween_property(hair_material, "albedo_color", Color(.05, .04, .04), seconds)
	fade.tween_method(_shape_overtime_hair, 1.0, 0.0, seconds)
	fade.tween_method(_blend_overtime_hair, 1.0, 0.0, seconds)
	fade.chain().tween_callback(overtime.bind(false))


var conversing: bool = false


func _physics_process(delta: float) -> void:
	# Hide only the artwork: finale prop ownership can still hide the whole pivot.
	blade_art.visible = not story_pose in SEATED
	# The back print and sticky note would show through the chair's backrest.
	back_kit.visible = not story_pose in SEATED
	if conversing:
		clock += delta
		crouch = 0.0
		position = Vector3.ZERO
		_loop("idle_casual", 1.0, .2, delta)
		right_ik.active = false
		left_ik.active = false
		skeleton.advance(delta)
		return
	if overtime_strength > .2:
		# Arcs crackle round him, and the light breathes with them.
		overtime_crackle -= delta
		if overtime_crackle <= 0.0 and is_inside_tree():
			overtime_crackle = randf_range(.18, .45) / maxf(.2, overtime_strength)
			var at: Vector3 = global_position + Vector3(randf_range(-.4, .4), randf_range(.4, 1.6), randf_range(-.4, .4))
			ElementFx.bolt(self, at, at + Vector3(randf_range(-.5, .5), randf_range(-.4, .4), randf_range(-.5, .5)), Color(1, .9, .45), .08, .025)
	if duel_active:
		return
	if not preview_clip.is_empty():
		_scrub(preview_clip, animator.get_animation(_clip_name(preview_clip)).length * preview_at, 0.0, delta)
		right_ik.active = false
		left_ik.active = false
		skeleton.advance(delta)
		return
	if actor == null:
		clock += delta
		_staged(delta)
		_solve(delta)
		return
	if actor.health <= 0:
		if animator.current_animation == "rig/death":
			animator.advance(delta)
		return
	var distance: float = Vector2(actor.global_position.x - previous_position.x, actor.global_position.z - previous_position.z).length()
	previous_position = actor.global_position
	if actor.hitstop_left > 0:
		return
	clock += delta
	var speed: float = distance / maxf(delta, .001)
	if story_walk_speed > 0.0 or actor.narrative_hold:
		speed = story_walk_speed
	# Omnislash blinks teleport; they are not a burst of running.
	if actor.specials != null and actor.specials.omnislashing():
		speed = 0.0
	var target_crouch: float = .30 if actor.dodging and actor.dodge_elapsed < actor.dodge_duration else 0.0
	crouch = move_toward(crouch, target_crouch, delta * 4.5)
	if story_pose >= Pose.TYPING:
		yaw_lag = 0.0
		_staged(delta)
	else:
		_gameplay(speed, delta)
	last_facing = get_parent().rotation.y
	_footsteps(speed)
	_solve(delta)


## Steps land on the clip's footfalls (run and walk plant a foot at 0 and half-way).
func _footsteps(speed: float) -> void:
	var clip: StringName = animator.current_animation
	var striding: bool = clip in [&"rig/run", &"rig/walk"] and actor.is_on_floor() and not actor.dodging
	var now: float = animator.current_animation_position / maxf(animator.current_animation_length, .001) if striding else -1.0
	if striding and phase >= 0.0 and int(phase * 2) != int(now * 2) and speed > 1.0 and DisplayServer.get_name() != "headless":
		actor.get_node("StepSound").pitch_scale = 1.04 if now < .5 else .96
		actor.get_node("StepSound").play()
	phase = now if clip == step_clip else -1.0
	step_clip = clip


func _gameplay(speed: float, delta: float) -> void:
	var melee: Node3D = actor.melee
	var hold_goal: float = 1.0
	left_reach = move_toward(left_reach, 0.0, delta * 8.0)
	head_turn = head_turn.lerp(Vector2(.22 if story_pose == Pose.LOOK_DOWN else -.08, -.3 if story_pose == Pose.LOOK_DOWN else .4) if story_pose > 0 else Vector2.ZERO, 1.0 - exp(-8.0 * delta))
	if actor.dodging:
		var total: float = actor.dodge_duration + actor.dodge_recovery * actor.dodge_recovery_multiplier
		_scrub("roll", clampf(actor.dodge_elapsed / total, 0, 1) * .92, .05, delta)
	elif actor.hurt_left > 0:
		_scrub("hit", (1.0 - actor.hurt_left / maxf(actor.hurt_duration, .01)) * .35, .04, delta)
	elif not actor.is_on_floor() and story_walk_speed <= 0.0 and not actor.narrative_hold:
		_scrub("jump", .45, .12, delta)
	elif melee.attacking:
		# _pose_swing samples the whole-body strike below, once, on the melee clock.
		pass
	elif actor.specials != null and actor.specials.counter_left > 0.0:
		_scrub("sword_block", ANIMATIONS.get_animation("sword_block").length * .45, .08, delta)
	elif speed > 2.6:
		_loop("run", clampf(speed / run_reference_speed, .8, 1.9), .14, delta)
	elif speed > .35 or story_walk_speed > 0.0:
		_loop("walk", clampf(speed / 1.6, .08 if story_walk_speed > 0.0 else .6, 1.6), .25 if story_walk_speed > 0.0 else .14, delta)
	else:
		_loop("idle", 1.0, .2, delta)
	spin = 0.0
	lunge = 0.0
	lift = 0.0
	if not hit_hooked:
		melee.hit_landed.connect(_on_hit_landed)
		hit_hooked = true
	var active: bool = melee.attacking and melee.is_active()
	if active and not striking:
		_cast_element(maxi(actor.combo_index, 0))
	striking = active
	if melee.attacking:
		hold_goal = 0.0
		_swing(melee, delta)
	elif actor.specials != null and actor.specials.counter_left > 0.0:
		hold_goal = 0.0
		left_reach = 1.0
		weapon.transform = Transform3D(Basis.from_euler(Vector3(.15, -.3, -.5)), Vector3(.13, 1.12, -.48))
		trail.emitting = false
	else:
		trail.emitting = false
	held = move_toward(held, hold_goal, delta * (30.0 if hold_goal == 0.0 else 7.0))
	right_reach = 1.0 - held
	var jump: float = angle_difference(last_facing, get_parent().rotation.y)
	if absf(jump) > .9 and not (actor.specials != null and actor.specials.omnislashing()):
		yaw_lag = wrapf(yaw_lag - jump, -PI, PI)
	yaw_lag *= exp(-YAW_CATCH_UP * delta)
	rotation.y = spin + yaw_lag
	position = Vector3(0, lift, -lunge)
	_turn("Head", Vector3.RIGHT, head_turn.x)
	_turn("Head", Vector3.UP, head_turn.y)


## Authored moves for the three combo steps, phased exactly on the melee windows:
## a lunging diagonal slash, a spinning backhand, and a leap into an overhead slam.
## Wind-ups ease into anticipation; strikes start at full speed.
func _swing(melee: Node3D, delta: float) -> void:
	_pose_swing(maxi(actor.combo_index, 0), melee.elapsed, melee.windup, melee.active_time, melee.recovery, delta)


## Specials resolve after the rig's tick. Pose the contact before hit-stop holds it,
## so a counter/pulse never freezes the previous wind-up or shoulder-rest pose.
func refresh_skill_contact() -> void:
	if actor == null or not actor.melee.attacking or story_pose >= Pose.TYPING:
		return
	held = 0.0
	shoulder_rest = 0.0
	right_reach = 1.0
	left_reach = 0.0
	spin = 0.0
	lunge = 0.0
	lift = 0.0
	yaw_lag = 0.0
	animator.advance(0.0)
	_swing(actor.melee, 0.0)
	rotation.y = spin
	position = Vector3(0, lift, -lunge)
	_solve(0.0)


## One authored strike at `elapsed` seconds into its wind-up/strike/recovery timeline:
## the combo steps on the melee clock, the finisher on the kill cam's.
func _pose_swing(index: int, elapsed: float, windup_time: float, active_time: float, recovery: float, delta: float = 0.0) -> void:
	_sword_body(index, elapsed, windup_time, active_time, recovery, delta)
	var windup: float = clampf(elapsed / windup_time, 0, 1)
	var strike: float = (elapsed - windup_time) / active_time
	var settle: float = clampf((elapsed - windup_time - active_time) / recovery, 0, 1)
	var striking_now: bool = elapsed >= windup_time and strike < 1.0
	var carry: Transform3D = carry_transform()
	var target: Transform3D
	var twist: float = 0.0
	var dip: float = 0.0
	var anticipation: float = smoothstep(0.0, .85, windup)
	var release: float = 1.0 - ease(settle, 2.0)
	left_reach = 1.0
	trail.color = ELEMENTS[index].color
	match index:
		0:
			# High over the right shoulder, cut down across the body, step into it.
			var back: Transform3D = Transform3D(Basis.from_euler(Vector3(1.25, -.7, .45)), Vector3(.34, 1.3, .12))
			var middle: Transform3D = Transform3D(Basis.from_euler(Vector3(-.15, .2, -.2)), Vector3(.02, 1.0, -.7))
			var front: Transform3D = Transform3D(Basis.from_euler(Vector3(-.95, 1.05, -.4)), Vector3(-.3, .62, -.4))
			if not striking_now and strike < 1.0:
				target = carry.interpolate_with(back, anticipation)
				twist = -.6 * anticipation
				dip = .06 * anticipation
			elif striking_now:
				var cut: float = ease(strike, .3)
				target = back.interpolate_with(middle, cut * 2.0) if cut < .5 else middle.interpolate_with(front, cut * 2.0 - 1.0)
				twist = lerpf(-.6, .75, cut)
				lunge = .5 * cut
				dip = .1
			else:
				target = front.interpolate_with(carry, 1.0 - release)
				twist = .75 * release
				lunge = .5 * release
				dip = .1 * release
		1:
			# Wind the keyboard across the body, then turn a full circle with it extended.
			var loaded: Transform3D = Transform3D(Basis.from_euler(Vector3(.15, 1.5, -.3)), Vector3(-.35, .98, .15))
			var extended: Transform3D = Transform3D(Basis.from_euler(Vector3(.05, 1.57, -.1)), Vector3(-.42, 1.0, -.15))
			if not striking_now and strike < 1.0:
				target = carry.interpolate_with(loaded, anticipation)
				twist = .7 * anticipation
				dip = .12 * anticipation
			elif striking_now:
				target = loaded.interpolate_with(extended, minf(1.0, strike * 3.0))
				spin = TAU * ease(strike, .45)
				lift = .25 * sin(strike * PI)
				dip = .05
			else:
				target = extended.interpolate_with(carry, 1.0 - release)
				spin = TAU
				dip = .12 * release
		_:
			# Leap: rise with the keyboard overhead in both hands, slam down on the strike.
			var overhead: Transform3D = Transform3D(Basis.from_euler(Vector3(1.95, 0, 0)), Vector3(.05, 1.6, .2))
			var slammed: Transform3D = Transform3D(Basis.from_euler(Vector3(-1.15, 0, 0)), Vector3(.05, .5, -.7))
			left_reach = 1.0
			if not striking_now and strike < 1.0:
				target = carry.interpolate_with(overhead, anticipation)
				# Up fast, hang, then drop so the feet land as the strike opens.
				lift = .7 * (ease(minf(1.0, windup / .55), .3) if windup < .7 else 1.0 - ease((windup - .7) / .3, 2.4))
			elif striking_now:
				target = overhead.interpolate_with(slammed, minf(1.0, ease(strike * 2.5, .4)))
				dip = .22
			else:
				target = slammed.interpolate_with(carry, 1.0 - release)
				dip = .22 * release
				left_reach = release
	# The ribbon marks the cut itself, not the wind-up.
	trail.emitting = elapsed >= windup_time * .9 and (strike < 1.0 or settle < .2)
	weapon.transform = target
	# The clips now supply weight transfer and torso motion; retain a small contact
	# correction for the engineer's proportions and the authored blade arc.
	_turn("Abdomen", Vector3.UP, twist * .15)
	_turn("Torso", Vector3.UP, twist * .2)
	_turn("Abdomen", Vector3.RIGHT, dip * .8)
	_drop(dip * .35)


## Retimed full-body motion under the blade/grip corrections. Root travel stays
## with CharacterBody3D. Dash gets its own pose; spins keep their authored full turn.
func _sword_body(index: int, elapsed: float, windup_time: float, active_time: float, recovery: float, delta: float) -> void:
	# Sword B dives too far forward on the short engineer during a full turn.
	# A supplies a planted cutting stance beneath the authored spinning backhand.
	var clip: String = "sword_a" if index < 2 else "jump_attack"
	var phases: Vector2 = SWORD_PHASES
	if index == 0 and animator.has_animation("sword_trial/kevin_2h"):
		clip = "sword_trial/kevin_2h"
		phases = KEVIN_PHASES
	if actor != null and actor.specials != null and actor.specials.dash_left > 0.0:
		clip = "sword_dash"
		phases = Vector2(.25, .6)
	var fraction: float
	if elapsed < windup_time:
		fraction = lerpf(0.0, phases.x, clampf(elapsed / maxf(windup_time, .001), 0.0, 1.0))
	elif elapsed < windup_time + active_time:
		fraction = lerpf(phases.x, phases.y, clampf((elapsed - windup_time) / maxf(active_time, .001), 0.0, 1.0))
	else:
		fraction = lerpf(phases.y, 1.0, clampf((elapsed - windup_time - active_time) / maxf(recovery, .001), 0.0, 1.0))
	if delta == 0.0:
		# Immediate skill contact must finish any locomotion blend before hit-stop.
		animator.play(_clip_name(clip), 0.0)
	_scrub(clip, animator.get_animation(_clip_name(clip)).length * fraction, .035, delta)


## Each strike releases its element along the swing; hits get their own impact.
func _cast_element(index: int) -> void:
	called_out = false
	var color: Color = ELEMENTS[index].color
	var facing: Basis = actor.visual.global_basis
	var forward: Vector3 = -facing.z
	var tip: Vector3 = weapon.global_transform * Vector3(0, 0, -1.3)
	match index:
		0:
			ElementFx.gust(self, global_position + Vector3.UP * 1.0 + forward * .3, facing, color, 4.2)
			ElementFx.motes(self, tip, color, 10, 3.0, .4, 0.0, .1)
		1:
			for fork in range(3):
				var end: Vector3 = global_position + forward * randf_range(1.4, 2.6) + facing.x * randf_range(-1.3, 1.3)
				ElementFx.bolt(self, tip, end + Vector3.UP * .05, color, .22)
			ElementFx.flash(self, tip, color, 4.0, 6.0, .2)
			ElementFx.motes(self, tip, color, 16, 5.0, .35, -4.0, .08)
		2:
			# Landing of the leap: fire ring, cracked floor, a jolt.
			ElementFx.flame_ring(self, global_position, 2.6, .75)
			ElementFx.cracks(self, global_position + forward * .6, color, 2.2, 6, 1.0)
			ElementFx.tremor(self, global_position, .45, 6.0)


func _on_hit_landed(target: Node3D) -> void:
	var index: int = maxi(actor.combo_index, 0)
	var color: Color = ELEMENTS[index].color
	var at: Vector3 = target.global_position + Vector3.UP * 1.1
	match index:
		0:
			ElementFx.motes(self, at, color, 18, 6.0, .45, 0.0, .18)
			ElementFx.shockwave(self, at, color, 1.6, .3, true)
		1:
			ElementFx.bolt(self, weapon.global_transform * Vector3(0, 0, -1.2), at, color, .25, .06)
			ElementFx.bolt(self, at + Vector3(randf_range(-.5, .5), 2.4, randf_range(-.5, .5)), at, Color(1, 1, 1), .18, .06)
			ElementFx.motes(self, at, color, 14, 5.0, .3, -6.0, .07)
		2:
			ElementFx.motes(self, at, color, 24, 5.0, .7, 2.5, .2)
			ElementFx.flash(self, at, color, 3.0, 4.0, .3)
			if not called_out:
				ElementFx.freeze(self, .08)
	if not called_out:
		called_out = true
		ElementFx.glyphs(self, global_position + Vector3.UP * 2.15, color, [ELEMENTS[index].call], .7, 0.0)


## Cinematic only: no melee request, hitbox, health change or source root travel.
func pose_duel(clip: String, progress: float, blade: Transform3D, offset: Vector3 = Vector3.ZERO, yaw: float = 0.0, ribbon: bool = false) -> void:
	duel_active = true
	story_pose = Pose.FINISH
	story_walk_speed = 0.0
	story_hand_targets.clear()
	position = offset
	rotation = Vector3(0, yaw, 0)
	held = 0.0
	shoulder_rest = 0.0
	right_reach = 1.0
	left_reach = 1.0
	_scrub(clip, animator.get_animation(_clip_name(clip)).length * clampf(progress, 0.0, .999), 0.0, 0.0)
	weapon.transform = blade
	trail.emitting = ribbon
	_solve(0.0)


func end_duel() -> void:
	duel_active = false
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	story_pose = Pose.ARMED
	trail.emitting = false
	trail.clear()


func _staged(delta: float) -> void:
	var seated: bool = story_pose in SEATED
	var blend: float = 1.0 - exp(-7.0 * delta)
	sit = lerpf(sit, 1.0 if seated else 0.0, blend)
	if seated and story_sit_progress >= 0.0:
		sit = clampf(story_sit_progress, 0.0, 1.0)
	if was_seated and not seated:
		standing_left = ANIMATIONS.get_animation("stand_up").length * .7
	was_seated = seated
	standing_left = maxf(0.0, standing_left - delta)
	var targets: Array[Vector3] = [DESK_HANDS[0] + Vector3(0, absf(sin(clock * 13.0)) * .018, 0), DESK_HANDS[1] + Vector3(0, absf(sin(clock * 11.0 + 1.3)) * .018, 0)]
	var look: Vector2 = Vector2(.12, 0)
	var target_lean: float = -.08
	var reach: float = 1.0
	match story_pose:
		Pose.ALERT:
			targets = [Vector3(-.2, .92, -.42), Vector3(.16, .92, -.42)]
			look = Vector2(-.04, 0)
			target_lean = -.04
		Pose.SLUMP:
			targets = [Vector3(-.22, .62, .25), Vector3(.22, .62, .25)]
			look = Vector2(.55, .05)
			target_lean = -.32
		Pose.SIP:
			targets = [DESK_HANDS[0], Vector3(.08, 1.18, -.22)]
			look = Vector2(-.12, .08)
			target_lean = .08
		Pose.RELAX:
			targets = [Vector3(-.2, .52, .12), Vector3(.2, .52, .12)]
			look = Vector2(-.22, 0)
			target_lean = -.06
		Pose.GLANCE:
			targets = [Vector3(-.2, .9, -.46), Vector3(.16, .9, -.46)]
			look = Vector2(.02, -.4)
			target_lean = -.05
		Pose.ARMED:
			look = Vector2(-.04, 0)
			target_lean = 0.0
			reach = 0.0
		Pose.RAGE:
			look = Vector2(lerpf(.28, -.08, overtime_strength), 0)
			target_lean = -.16
			reach = 0.0
		Pose.FINISH:
			look = Vector2(-.05, 0)
			target_lean = 0.0
			reach = 0.0
	# Hands on the desk stay on the desk while the body is lifted onto the cushion.
	var on_desk: Array[bool] = [story_pose != Pose.SLUMP and story_pose != Pose.RELAX, story_pose in [Pose.TYPING, Pose.ALERT, Pose.GLANCE]]
	for side in [0, 1]:
		hands[side] = hands[side].lerp(targets[side] - (SEATED_OFFSET * sit if on_desk[side] else Vector3.ZERO), blend)
		# Lift before crossing the desk edge, including transitions to/from the lap.
		if seated and hands[side].z + SEATED_OFFSET.z * sit < -.32:
			hands[side].y = maxf(hands[side].y, .9 - SEATED_OFFSET.y * sit)
	head_turn = head_turn.lerp(look, blend)
	lean = lerpf(lean, target_lean, blend)
	position = SEATED_OFFSET * sit
	if story_pose == Pose.RAGE:
		position.x += sin(clock * 45.0) * .012 * overtime_strength
		position.y += sin(clock * 32.0) * .008 * overtime_strength
	if story_pose == Pose.FINISH:
		# The finisher's clock samples its strike below; do not restart idle each frame.
		pass
	elif seated:
		_scrub("sit_down", ANIMATIONS.get_animation("sit_down").length * (clampf(story_sit_progress, 0.0, 1.0) if story_sit_progress >= 0.0 else 1.0), .3, delta)
	elif standing_left > 0:
		var length: float = ANIMATIONS.get_animation("stand_up").length
		_scrub("stand_up", length * .3 + (length * .7 - standing_left), .1, delta)
	else:
		_loop("idle", 1.0, .25, delta)
	right_reach = lerpf(right_reach, reach if seated else 0.0, blend)
	left_reach = lerpf(left_reach, reach if seated else 0.0, blend)
	right_target.position = hands[1]
	left_target.position = hands[0]
	right_pole.position = Vector3(.7, .2, .4)
	left_pole.position = Vector3(-.7, .2, .4)
	_turn("Abdomen", Vector3.RIGHT, -lean)
	_turn("Head", Vector3.RIGHT, head_turn.x)
	_turn("Head", Vector3.UP, head_turn.y)
	# Keep the sword planted beside the desk while the body settles onto its cushion.
	held = move_toward(held, 0.0 if seated else 1.0, delta * 3.0)
	if seated:
		weapon.transform = SEATED_SWORD
		weapon.position -= SEATED_OFFSET * sit
	if story_pose == Pose.FINISH:
		# The finisher is a cut: blade in hand at once, then one authored strike played
		# out across the kill cam in slow motion.
		held = 0.0
		shoulder_rest = 0.0
		spin = 0.0
		lunge = 0.0
		lift = 0.0
		right_reach = 1.0
		left_reach = 0.0
		var t: float = clampf(finish_progress, 0.0, 1.0)
		_pose_swing(finish_style, t, FINISH_TIMING.x, FINISH_TIMING.y, FINISH_TIMING.z, delta)
		rotation.y = spin
		position = Vector3(0, lift, -lunge)
	elif story_pose == Pose.RAGE:
		# Lower the blade while he grieves; his face stays clear for the buildup.
		held = 0.0
		shoulder_rest = 0.0
		right_reach = 1.0
		weapon.transform = Transform3D(Basis.looking_at(Vector3(.15, -.3, -1).normalized()), Vector3(.45, .75, 0))


func _solve(delta: float) -> void:
	var swinging: bool = actor != null and actor.melee != null and actor.melee.attacking or story_pose == Pose.FINISH
	var guarding: bool = actor != null and actor.specials != null and actor.specials.counter_left > 0.0
	if swinging or guarding or story_pose in SEATED:
		right_target.position = weapon.transform * RIGHT_GRIP if not story_pose in SEATED else hands[1]
		left_target.position = weapon.transform * LEFT_GRIP if not story_pose in SEATED else hands[0]
		right_pole.position = Vector3(.75, .35, .55)
		left_pole.position = Vector3(-.75, .35, .55)
	if story_hand_targets.size() == 2 and actor != null and actor.narrative_hold:
		left_target.position = story_hand_targets[0]
		right_target.position = story_hand_targets[1]
		left_reach = 1.0
		right_reach = 1.0
	right_ik.influence = clampf(right_reach, 0, 1)
	left_ik.influence = clampf(left_reach, 0, 1)
	right_ik.active = right_ik.influence > .001
	left_ik.active = left_ik.influence > .001
	# The Monolith rests on the right shoulder whenever it is not swinging; the right hand
	# goes up to hold it there.
	var resting: bool = (weapon.visible and story_pose < Pose.TYPING and actor != null and actor.melee != null \
		and not actor.melee.attacking and not guarding and not actor.dodging and actor.health > 0 and actor.hurt_left <= 0)
	shoulder_rest = move_toward(shoulder_rest, 1.0 if resting else 0.0, delta * (5.0 if resting else 12.0))
	if shoulder_rest > 0.0:
		right_target.position = shoulder_transform() * RIGHT_GRIP
		right_pole.position = Vector3(.8, .2, .3)
		# Same easing as the weapon below, so hand and grip travel together.
		right_ik.influence = maxf(right_ik.influence, smoothstep(0.0, 1.0, shoulder_rest))
		right_ik.active = true
	skeleton.advance(delta)
	if held > 0.0:
		weapon.transform = weapon.transform.interpolate_with(carry_transform(), held)
	if shoulder_rest > 0.0:
		weapon.transform = weapon.transform.interpolate_with(shoulder_transform(), smoothstep(0.0, 1.0, shoulder_rest))
	trail.sample()
	_glow()


func _glow() -> void:
	if eye_material == null:
		return
	eye_material.emission_energy_multiplier = maxf(2.6 * battle, 3.0 * overtime_strength)
	var hue: Color = Color.from_hsv(fmod(clock * .35, 1.0), .75, 1.0)
	for material in rim_materials:
		material.emission = Color(.08, .62, .66).lerp(hue, battle)
		material.emission_energy_multiplier = .25 + 2.6 * battle
	for entry: Array in gear_glow:
		(entry[0] as StandardMaterial3D).emission_energy_multiplier = lerpf(entry[1], entry[2], battle)
	# The pager never stops: the watch blinks twice a second.
	watch_screen.emission_energy_multiplier *= .45 + .55 * absf(sin(clock * 6.0))
	for label in print_labels:
		label.modulate.a = .72 + .28 * battle


func _clip_name(clip: String) -> String:
	return clip if clip.contains("/") else "rig/" + clip


func _scrub(clip: String, time: float, blend: float, delta: float) -> void:
	var name: String = _clip_name(clip)
	if animator.current_animation != name:
		animator.play(name, blend)
	animator.speed_scale = 1.0
	animator.seek(maxf(0.0, time - delta), false)
	animator.advance(delta)


func _loop(clip: String, rate: float, blend: float, delta: float) -> void:
	var name: String = _clip_name(clip)
	if animator.current_animation != name:
		animator.play(name, blend)
	animator.speed_scale = rate
	animator.advance(delta)


## Rotate a bone about an axis given in character space, on top of the clip's pose.
func _turn(bone: String, axis: Vector3, angle: float) -> void:
	if is_zero_approx(angle):
		return
	var index: int = bones[bone]
	var parent: int = skeleton.get_bone_parent(index)
	var to_skeleton: Basis = skeleton.global_basis.orthonormalized().inverse() * global_basis.orthonormalized()
	var parent_basis: Basis = skeleton.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	var local_axis: Vector3 = (parent_basis.inverse() * (to_skeleton * axis)).normalized()
	skeleton.set_bone_pose_rotation(index, (Quaternion(local_axis, angle) * skeleton.get_bone_pose_rotation(index)).normalized())


## Lower the whole body (hips) by a distance in metres, feet stay on the clip's marks.
func _drop(amount: float) -> void:
	if is_zero_approx(amount):
		return
	var index: int = bones["Body"]
	var parent: int = skeleton.get_bone_parent(index)
	var to_skeleton: Basis = skeleton.global_basis.inverse() * global_basis
	var parent_basis: Basis = skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	skeleton.set_bone_pose_position(index, skeleton.get_bone_pose_position(index) + parent_basis.inverse() * (to_skeleton * Vector3.DOWN * amount))


func _ik(root: String, middle: String, end: String, target: Node3D, pole: Node3D) -> TwoBoneIK3D:
	var ik: TwoBoneIK3D = TwoBoneIK3D.new()
	ik.name = root.replace(".", "") + "IK"
	ik.setting_count = 1
	skeleton.add_child(ik)
	ik.set_root_bone_name(0, root)
	ik.set_middle_bone_name(0, middle)
	ik.set_end_bone_name(0, end)
	ik.set_target_node(0, ik.get_path_to(target))
	ik.set_pole_node(0, ik.get_path_to(pole))
	ik.influence = 0.0
	return ik


## Identity pass: re-dress the stock body as the on-call developer and add his kit.
## The outfit mesh (tools/build_hero_outfit.gd) keeps the source skin and bind poses.
func _dress() -> void:
	var body: MeshInstance3D = skeleton.find_children("*", "MeshInstance3D", false, false)[0]
	body.mesh = OUTFIT
	var palette: Dictionary = {
		"Skin": Color(.56, .37, .26), "Glove": Color(.06, .065, .075), "Streak": Color(.1, .75, .85), "Hoodie": Color(.075, .08, .095), "Rib": Color(.045, .048, .056),
		"Pants": Color(.11, .12, .14), "Belt": Color(.03, .03, .035),
		"Shoe": Color(.9, .9, .88), "Sole": Color(.12, .95, .85),
		"Hair": Color(.05, .04, .04), "Face": Color(.03, .035, .04),
	}
	for surface in body.mesh.get_surface_count():
		var source: Material = body.mesh.surface_get_material(surface)
		if source == null or not palette.has(source.resource_name):
			continue
		var material: StandardMaterial3D = (source as StandardMaterial3D).duplicate()
		material.albedo_color = palette[source.resource_name]
		material.roughness = .85
		if source.resource_name == "Hair":
			material.emission_enabled = true
			material.emission = Color(1, .78, .2)
			material.emission_energy_multiplier = 0.0
			hair_material = material
		if source.resource_name == "Face":
			material.emission_enabled = true
			material.emission = Color(.35, .95, 1.0)
			material.emission_energy_multiplier = 0.0
			eye_material = material
		if source.resource_name == "Hoodie":
			# Brushed fleece: a soft sheen that lifts the silhouette off dark carpet.
			material.rim_enabled = true
			material.rim = .35
			material.rim_tint = .4
		if source.resource_name == "Sole":
			# Light-up sneakers: they idle softly and flare in battle mode.
			_glows(material, palette["Sole"], .5, 2.4)
		body.set_surface_override_material(surface, material)
	for edge in weapon.find_children("Edge*", "MeshInstance3D", false, false):
		var rim: StandardMaterial3D = ((edge as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
		(edge as MeshInstance3D).material_override = rim
		rim_materials.append(rim)
	var hoodie: StandardMaterial3D = _flat(palette["Hoodie"], .9)
	var rib: StandardMaterial3D = _flat(palette["Rib"], .95)
	var black: StandardMaterial3D = _flat(Color(.025, .025, .03), .35)
	var metal: StandardMaterial3D = _flat(Color(.7, .72, .75), .3)
	metal.metallic = .9
	var cyan: Color = Color(.15, .9, 1.0)
	var head: Node3D = _rest_attach("Head")
	_build_overtime_hair(_attach("Head", 1.0 / skeleton.global_basis.get_scale().x))
	_dress_glasses(head, black, cyan)
	_dress_headphones(head, black, cyan)
	var torso: Node3D = _rest_attach("Torso")
	_dress_hoodie(torso, _rest_attach("Abdomen"), _rest_attach("Neck"), hoodie, rib, metal)
	_dress_back(torso, cyan)
	_dress_badge(torso, metal)
	for side in [-1.0, 1.0]:
		# The sleeves are shoved up past the elbow, bunched for work.
		var elbow: Node3D = _rest_attach("LowerArm.L" if side < 0 else "LowerArm.R")
		var bunch: TorusMesh = TorusMesh.new()
		bunch.inner_radius = .062
		bunch.outer_radius = .108
		bunch.rings = 14
		bunch.ring_segments = 8
		_piece(elbow, bunch, hoodie, Vector3(side * .61, 1.2, .005), Vector3(.12, 0, PI * .5), Vector3(1, 1.25, 1))
		_piece(elbow, bunch, rib, Vector3(side * .645, 1.2, .005), Vector3(-.1, 0, PI * .5), Vector3(.85, .9, .85))
	_dress_watch(_rest_attach("LowerArm.L"), black)
	_dress_duck(_rest_attach("Hips"), metal)


## Gear placed on `bone` in character space at the bind rest pose (metres, facing -Z,
## arms out): the holder cancels the rest transform, so children follow every clip.
func _rest_attach(bone: String) -> Node3D:
	var attachment: BoneAttachment3D = BoneAttachment3D.new()
	attachment.name = bone + "Kit"
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	var holder: Node3D = Node3D.new()
	var to_character: Transform3D = global_transform.affine_inverse() * skeleton.global_transform
	holder.transform = (to_character * skeleton.get_bone_global_rest(skeleton.find_bone(bone))).affine_inverse()
	attachment.add_child(holder)
	return holder


func _piece(parent: Node3D, mesh: Mesh, material: Material, at: Vector3, turn: Vector3 = Vector3.ZERO, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var piece: MeshInstance3D = MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = material
	piece.position = at
	piece.rotation = turn
	piece.scale = size
	parent.add_child(piece)
	return piece


## A square-section rod from `from` to `to`, for frames, cords and zips.
func _rod(parent: Node3D, from: Vector3, to: Vector3, thickness: float, material: Material) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(thickness, from.distance_to(to), thickness)
	var piece: MeshInstance3D = _piece(parent, box, material, (from + to) * .5)
	var along: Vector3 = (to - from).normalized()
	var side: Vector3 = along.cross(Vector3.FORWARD if absf(along.z) < .9 else Vector3.RIGHT).normalized()
	piece.basis = Basis(side, along, side.cross(along)).orthonormalized()
	return piece


## Battle mode and the idle hum: emission between `idle` and `fight` energy.
func _glows(material: StandardMaterial3D, color: Color, idle: float, fight: float) -> void:
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = idle
	gear_glow.append([material, idle, fight])


## Thick black rectangular frames, wrapped to the big head, with lenses that catch
## monitor light (and become a HUD glow in battle mode).
func _dress_glasses(holder: Node3D, frame: StandardMaterial3D, cyan: Color) -> void:
	var head: Node3D = Node3D.new()
	head.name = "Glasses"
	holder.add_child(head)
	var lens: StandardMaterial3D = _flat(Color(.45, .75, 1.0, .05), .55)
	lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Blended specular is not scaled by alpha: without this the lenses go milky.
	lens.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	lens.metallic_specular = 0.0
	_glows(lens, cyan, .0, .22)
	var glass: QuadMesh = QuadMesh.new()
	glass.size = Vector2(.19, .14)
	for side in [-1.0, 1.0]:
		var rim: Node3D = Node3D.new()
		rim.position = Vector3(side * .165, 1.672, -.338)
		rim.rotation = Vector3(0, side * -.42, 0)
		head.add_child(rim)
		# A quad faces +Z; the lenses look forward along -Z.
		_piece(rim, glass, lens, Vector3.ZERO, Vector3(0, PI, 0))
		var w: float = .105
		var h: float = .08
		_rod(rim, Vector3(-w, h, 0), Vector3(w, h, 0), .034, frame)
		_rod(rim, Vector3(-w, -h, 0), Vector3(w, -h, 0), .026, frame)
		_rod(rim, Vector3(-w, -h, 0), Vector3(-w, h, 0), .026, frame)
		_rod(rim, Vector3(w, -h, 0), Vector3(w, h, 0), .026, frame)
		var hinge: Vector3 = Vector3(side * (.165 + .105 * cos(.42)), 1.7, -.338 + .105 * sin(.42))
		_rod(head, hinge, Vector3(side * .318, 1.69, -.02), .02, frame)
	_rod(head, Vector3(-.07, 1.705, -.36), Vector3(.07, 1.705, -.36), .022, frame)


## Big over-ear cans worn properly, cyan LED rings on the cups.
func _dress_headphones(holder: Node3D, plastic: StandardMaterial3D, cyan: Color) -> void:
	var head: Node3D = Node3D.new()
	head.name = "Headphones"
	holder.add_child(head)
	var points: Array[Vector3] = []
	for step in range(17):
		var angle: float = lerpf(-PI * .5, PI * .5, float(step) / 16.0)
		points.append(Vector3(sin(angle) * .395, 1.64 + cos(angle) * .55, .03))
	# Gunmetal so the band still reads over black hair.
	var band: StandardMaterial3D = _flat(Color(.36, .38, .42), .3)
	band.metallic = .8
	for index in range(points.size() - 1):
		_rod(head, points[index], points[index + 1], .045, band)
	var cushion: StandardMaterial3D = _flat(Color(.05, .05, .055), .95)
	var led: StandardMaterial3D = _flat(cyan, .3)
	_glows(led, cyan, 1.1, 3.2)
	for side in [-1.0, 1.0]:
		var shell: CylinderMesh = CylinderMesh.new()
		shell.top_radius = .1
		shell.bottom_radius = .115
		shell.height = .075
		shell.radial_segments = 20
		_piece(head, shell, plastic, Vector3(side * .385, 1.63, .03), Vector3(0, 0, side * PI * .5))
		var pad: CylinderMesh = CylinderMesh.new()
		pad.top_radius = .118
		pad.bottom_radius = .11
		pad.height = .05
		pad.radial_segments = 20
		_piece(head, pad, cushion, Vector3(side * .335, 1.63, .03), Vector3(0, 0, side * PI * .5))
		var ring: TorusMesh = TorusMesh.new()
		ring.inner_radius = .07
		ring.outer_radius = .088
		ring.rings = 24
		ring.ring_segments = 6
		_piece(head, ring, led, Vector3(side * .424, 1.63, .03), Vector3(0, 0, PI * .5))
		var arm: Vector3 = Vector3(side * .395, 1.64, .03)
		_rod(head, arm, arm + Vector3(0, .12, 0), .032, band)


## The open zip hoodie: hood bunched behind the neck, a ribbed collar, the white tee
## between metal zip tapes, drawstrings with metal aglets. Pieces below the ribs ride
## the abdomen so the front stays on the body when he twists into a swing.
func _dress_hoodie(torso: Node3D, abdomen: Node3D, neck: Node3D, fabric: StandardMaterial3D, rib: StandardMaterial3D, metal: StandardMaterial3D) -> void:
	var hood: SphereMesh = SphereMesh.new()
	hood.radius = .2
	hood.height = .4
	hood.radial_segments = 20
	hood.rings = 10
	_piece(torso, hood, fabric, Vector3(0, 1.315, .135), Vector3(-.35, 0, 0), Vector3(1.15, .62, .62))
	var lining: SphereMesh = hood.duplicate()
	_piece(torso, lining, rib, Vector3(0, 1.345, .1), Vector3(-.35, 0, 0), Vector3(.9, .42, .5))
	var collar: TorusMesh = TorusMesh.new()
	collar.inner_radius = .085
	collar.outer_radius = .14
	collar.rings = 20
	collar.ring_segments = 8
	_piece(neck, collar, fabric, Vector3(0, 1.29, .01), Vector3(.18, 0, 0), Vector3(1, .7, 1))
	var tee: StandardMaterial3D = _flat(Color(.86, .85, .8), .9)
	# The chest's centre line down to the hem: (height, depth).
	var edge: Array[Vector2] = [Vector2(1.27, -.09), Vector2(1.24, -.112), Vector2(1.18, -.134), Vector2(1.1, -.139), Vector2(1.0, -.143), Vector2(.89, -.146), Vector2(.79, -.145), Vector2(.73, -.15)]
	for index in range(edge.size() - 1):
		var part: Node3D = torso if edge[index + 1].x > .98 else abdomen
		var a: Vector3 = Vector3(0, edge[index].x, edge[index].y)
		var b: Vector3 = Vector3(0, edge[index + 1].x, edge[index + 1].y)
		var panel: MeshInstance3D = _rod(part, a, b, .01, tee)
		panel.scale = Vector3(.15 / .01, 1.02, .6)
		for side in [-1.0, 1.0]:
			var tape: Vector3 = Vector3(side * .078, 0, -.004)
			_rod(part, a + tape, b + tape, .016, metal)
	var prompt: Label3D = _print(">_", 64, .0014, Color(.1, .55, .25))
	prompt.position = Vector3(.012, 1.13, -.146)
	prompt.rotation = Vector3(0, PI, 0)
	torso.add_child(prompt)
	var cord: StandardMaterial3D = _flat(Color(.92, .92, .9), .8)
	for side in [-1.0, 1.0]:
		var top: Vector3 = Vector3(side * .1, 1.26, -.1)
		var tip: Vector3 = Vector3(side * .105, 1.05, -.152)
		_rod(torso, top, tip, .014, cord)
		_rod(torso, tip, tip + Vector3(0, -.04, -.004), .02, metal)
	var pull: BoxMesh = BoxMesh.new()
	pull.size = Vector3(.022, .05, .01)
	_piece(abdomen, pull, metal, Vector3(-.078, .76, -.158))


## The back the gameplay camera watches all run: a glowing </> mark, the reckless
## command he lives by, and the sticky note someone slapped on him.
func _dress_back(torso: Node3D, cyan: Color) -> void:
	back_kit = Node3D.new()
	back_kit.name = "BackKit"
	torso.add_child(back_kit)
	var mark: Label3D = _print("</>", 120, .0017, cyan)
	mark.position = Vector3(0, 1.06, .158)
	back_kit.add_child(mark)
	var line: Label3D = _print("git push --force", 30, .0017, cyan)
	line.position = Vector3(0, .955, .166)
	back_kit.add_child(line)
	for label: Label3D in [mark, line]:
		label.rotation = Vector3(.12, 0, 0)
		print_labels.append(label)
	var paper: BoxMesh = BoxMesh.new()
	paper.size = Vector3(.15, .15, .01)
	var note: MeshInstance3D = _piece(back_kit, paper, _flat(Color(.98, .86, .3), .9), Vector3(.115, .83, .165), Vector3(.1, 0, .16))
	note.name = "StickyNote"
	var text: Label3D = Label3D.new()
	text.text = "ON CALL\n(FOREVER)"
	text.font_size = 22
	text.pixel_size = .0014
	text.modulate = Color(.15, .12, .08)
	text.outline_size = 0
	text.position = Vector3(0, 0, .007)
	note.add_child(text)


func _print(text: String, size: int, pixel: float, color: Color) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = color
	label.outline_size = 0
	label.shaded = false
	return label


## The access badge on a retractable reel clipped to the hoodie edge.
func _dress_badge(torso: Node3D, metal: StandardMaterial3D) -> void:
	var reel: CylinderMesh = CylinderMesh.new()
	reel.top_radius = .028
	reel.bottom_radius = .028
	reel.height = .015
	_piece(torso, reel, _flat(Color(.85, .22, .12), .5), Vector3(-.13, 1.12, -.142), Vector3(PI * .5, 0, 0))
	_rod(torso, Vector3(-.13, 1.1, -.15), Vector3(-.135, 1.01, -.158), .006, metal)
	var card: BoxMesh = BoxMesh.new()
	card.size = Vector3(.085, .115, .008)
	var badge: MeshInstance3D = _piece(torso, card, _flat(Color(.93, .93, .9), .6), Vector3(-.135, .955, -.162), Vector3(.08, 0, .06))
	var stripe: BoxMesh = BoxMesh.new()
	stripe.size = Vector3(.085, .026, .004)
	_piece(badge, stripe, _flat(Color(.85, .16, .1), .6), Vector3(0, .042, -.005))
	var photo: BoxMesh = BoxMesh.new()
	photo.size = Vector3(.03, .036, .004)
	_piece(badge, photo, _flat(Color(.3, .32, .36), .6), Vector3(-.018, .0, -.005))
	var role: Label3D = _print("SRE", 40, .0008, Color(.08, .08, .1))
	role.position = Vector3(.018, -.002, -.0075)
	role.rotation = Vector3(0, PI, 0)
	badge.add_child(role)


## A smartwatch on the left wrist, the pager alert pulsing on its face.
func _dress_watch(forearm: Node3D, strap: StandardMaterial3D) -> void:
	var band: TorusMesh = TorusMesh.new()
	band.inner_radius = .062
	band.outer_radius = .079
	band.rings = 16
	band.ring_segments = 6
	_piece(forearm, band, strap, Vector3(-.765, 1.19, .008), Vector3(0, 0, PI * .5), Vector3(1, 1.4, 1))
	var case: BoxMesh = BoxMesh.new()
	case.size = Vector3(.06, .02, .065)
	_piece(forearm, case, strap, Vector3(-.765, 1.262, .008))
	var screen: BoxMesh = BoxMesh.new()
	screen.size = Vector3(.048, .004, .052)
	watch_screen = _flat(Color(1, .2, .12), .2)
	_glows(watch_screen, Color(1, .2, .12), 1.2, 3.0)
	_piece(forearm, screen, watch_screen, Vector3(-.765, 1.273, .008))


## Rubber-duck debugging: the duck hangs off a carabiner on his belt loop.
func _dress_duck(hips: Node3D, metal: StandardMaterial3D) -> void:
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = .014
	ring.outer_radius = .022
	_piece(hips, ring, metal, Vector3(.228, .705, -.02), Vector3(PI * .5, 0, 0), Vector3(1, 1.6, 1))
	_rod(hips, Vector3(.232, .68, -.02), Vector3(.236, .63, -.02), .008, metal)
	var yellow: StandardMaterial3D = _flat(Color(1, .82, .1), .45)
	var body_: SphereMesh = SphereMesh.new()
	body_.radius = .045
	body_.height = .07
	_piece(hips, body_, yellow, Vector3(.24, .585, -.02), Vector3.ZERO, Vector3(1, 1, 1.25))
	var head_: SphereMesh = SphereMesh.new()
	head_.radius = .03
	head_.height = .06
	_piece(hips, head_, yellow, Vector3(.24, .635, -.042))
	var beak: BoxMesh = BoxMesh.new()
	beak.size = Vector3(.026, .012, .03)
	_piece(hips, beak, _flat(Color(1, .45, .08), .5), Vector3(.24, .63, -.072))


## An original faceted, swept-up silhouette, attached to the animated head. The
## tufts rise out of the existing hair as the charge builds, then lower at the ending.
func _build_overtime_hair(head: Node3D) -> void:
	overtime_hair_material = hair_material.duplicate()
	overtime_hair = Node3D.new()
	overtime_hair.name = "OvertimeHair"
	head.add_child(overtime_hair)
	for index in range(9):
		var angle: float = float(index) * TAU / 8.0
		var outward: Vector3 = Vector3(cos(angle), 0, sin(angle))
		var root: Vector3 = outward * .23 + Vector3.UP * .25 if index < 8 else Vector3(0, .33, 0)
		var height: float = .42 + .13 * (1.0 + sin(angle)) * .5 if index < 8 else .66
		var width: float = .15 if index < 8 else .19
		var tip: Vector3 = root + Vector3.UP * height + outward * .25 if index < 8 else root + Vector3(.05, height, .12)
		var mesh: SurfaceTool = SurfaceTool.new()
		mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		for side in range(5):
			var a: float = side * TAU / 5.0
			var b: float = (side + 1) * TAU / 5.0
			var base_a: Vector3 = root + Vector3(cos(a), 0, sin(a)) * width
			var base_b: Vector3 = root + Vector3(cos(b), 0, sin(b)) * width
			var mid: Vector3 = root.lerp(tip, .45)
			var mid_a: Vector3 = mid + Vector3(cos(a), 0, sin(a)) * width * .75
			var mid_b: Vector3 = mid + Vector3(cos(b), 0, sin(b)) * width * .75
			for vertex: Vector3 in [base_a, mid_a, base_b, base_b, mid_a, mid_b, mid_a, tip, mid_b]:
				mesh.add_vertex(vertex)
		mesh.generate_normals()
		var tuft: MeshInstance3D = MeshInstance3D.new()
		tuft.mesh = mesh.commit()
		tuft.material_override = overtime_hair_material
		overtime_hair.add_child(tuft)
	_shape_overtime_hair(0.0)


func _shape_overtime_hair(amount: float) -> void:
	if not is_instance_valid(overtime_hair):
		return
	var rise: float = smoothstep(.22, .9, amount)
	overtime_hair.visible = rise > .01
	overtime_hair.scale = Vector3(lerpf(.65, 1.0, rise), maxf(.01, rise), lerpf(.65, 1.0, rise))


func _blend_overtime_hair(_amount: float) -> void:
	if overtime_hair_material == null:
		return
	# The swept tufts extend a full gold base; never expose the bald scalp under it.
	hair_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	var color: Color = hair_material.albedo_color
	color.a = 1.0
	hair_material.albedo_color = color
	color.a = 1.0
	overtime_hair_material.albedo_color = color
	overtime_hair_material.emission_energy_multiplier = hair_material.emission_energy_multiplier


func _attach(bone: String, unit: float) -> Node3D:
	var attachment: BoneAttachment3D = BoneAttachment3D.new()
	attachment.name = bone + "Gear"
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	var holder: Node3D = Node3D.new()
	holder.scale = Vector3.ONE * unit
	attachment.add_child(holder)
	return holder


func _flat(color: Color, roughness: float, glow: bool = false) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = .6
	return material
