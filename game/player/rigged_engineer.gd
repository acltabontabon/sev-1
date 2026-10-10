extends Node3D
## The on-call engineer: Quaternius CC0 body with CC0 Knight-pack motion retargeted by
## tools/build_engineer_rig.gd. Reads combat state only; never starts attacks or applies
## damage. Same contract as the native fallback (character_presentation.gd): reset_pose(),
## defeat(), story_pose, sit, crouch and the keyboard `weapon`.
##
## Between swings the keyboard rides in the right fist and every clip moves it naturally.
## During a swing the keyboard follows an authored arc in character space and two-bone IK
## pulls the arms onto its grip, so the visible strike always matches the damage window.

enum Pose { NONE, LOOK_DOWN, LOOK_UP, TYPING, ALERT, SLUMP, SIP, RELAX, GLANCE, ARMED, COOL }
const SEATED: Array[int] = [Pose.TYPING, Pose.ALERT, Pose.SLUMP, Pose.SIP, Pose.RELAX, Pose.GLANCE]
const ANIMATIONS: AnimationLibrary = preload("res://game/player/engineer_animations.res")
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
const DESK_HANDS: Array[Vector3] = [Vector3(-.17, .8, -.5), Vector3(.13, .8, -.5)]
## The sitting clip was authored for a lower stool set further back: seated, the body
## shifts up onto the cushion and forward off the backrest so the chair never cuts it.
const SEATED_OFFSET: Vector3 = Vector3(0, .17, -.3)


@export var model_scale: float = .64
@export var stride_length: float = 1.25
@export var run_reference_speed: float = 5.0
var story_pose: int = 0
var sit: float = 0.0
var crouch: float = 0.0
## 0..1, set by the incident's battle-mode director: eyes and keyboard light up.
var battle: float = 0.0
var clock: float = 0.0
var phase: float = 0.0
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
var rim_materials: Array[StandardMaterial3D] = []
var bones: Dictionary = {}
var striking: bool = false
var called_out: bool = false
var hit_hooked: bool = false
## Fist bone space to weapon pivot, measured once from the idle grip (see _measure_grip).
var hand_to_weapon: Transform3D = Transform3D.IDENTITY
@onready var model: Node3D = $Model
@onready var weapon: Node3D = $WeaponPivot
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
	phase = 0.0
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
	# Reports pause immediately. Settle into the final death frame before the signal.
	crouch = .48
	held = 0.0
	right_reach = 0.0
	left_reach = 0.0
	trail.clear()
	animator.play("rig/death", 0.0)
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
	var center: Vector3 = edge + basis.x * .22
	return Transform3D(basis, center - along * .75)


## The hero pose: point down in the floor at his right, pommel at shoulder height.
func planted_transform() -> Transform3D:
	var down: Vector3 = Vector3(.06, -1, .08).normalized()
	return Transform3D(Basis.looking_at(down, Vector3.BACK), Vector3(.62, 1.3, .1))


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


func _physics_process(delta: float) -> void:
	if not preview_clip.is_empty():
		_scrub(preview_clip, animator.get_animation("rig/" + preview_clip).length * preview_at, 0.0, delta)
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
		return
	var distance: float = Vector2(actor.global_position.x - previous_position.x, actor.global_position.z - previous_position.z).length()
	previous_position = actor.global_position
	if actor.hitstop_left > 0:
		return
	clock += delta
	var speed: float = distance / maxf(delta, .001)
	var old_half: int = int(phase * 2)
	if actor.is_on_floor() and not actor.dodging:
		phase = fmod(phase + distance / stride_length, 1.0)
	if old_half != int(phase * 2) and speed > 1.0 and DisplayServer.get_name() != "headless":
		actor.get_node("StepSound").pitch_scale = 1.04 if phase < .5 else .96
		actor.get_node("StepSound").play()
	var target_crouch: float = .30 if actor.dodging and actor.dodge_elapsed < actor.dodge_duration else 0.0
	crouch = move_toward(crouch, target_crouch, delta * 4.5)
	if story_pose >= Pose.TYPING:
		_staged(delta)
	else:
		_gameplay(speed, delta)
	_solve(delta)


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
	elif not actor.is_on_floor():
		_scrub("jump", .45, .12, delta)
	elif melee.attacking and actor.combo_index == 2 and melee.elapsed < melee.windup:
		_scrub("jump", .25 + .3 * melee.elapsed / melee.windup, .05, delta)
	elif speed > 2.6:
		_loop("run", clampf(speed / run_reference_speed, .7, 1.7), .14, delta)
	elif speed > .35:
		_loop("walk", clampf(speed / 1.6, .6, 1.6), .14, delta)
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
	else:
		trail.emitting = false
	held = move_toward(held, hold_goal, delta * (30.0 if hold_goal == 0.0 else 7.0))
	right_reach = 1.0 - held
	rotation.y = spin
	position = Vector3(0, lift, -lunge)
	_turn("Head", Vector3.RIGHT, head_turn.x)
	_turn("Head", Vector3.UP, head_turn.y)


## Authored moves for the three combo steps, phased exactly on the melee windows:
## a lunging diagonal slash, a spinning backhand, and a leap into an overhead slam.
## Wind-ups snap into a held anticipation pose; strikes start at full speed.
func _swing(melee: Node3D, _delta: float) -> void:
	var index: int = maxi(actor.combo_index, 0)
	var windup: float = clampf(melee.elapsed / melee.windup, 0, 1)
	var strike: float = (melee.elapsed - melee.windup) / melee.active_time
	var settle: float = clampf((melee.elapsed - melee.windup - melee.active_time) / melee.recovery, 0, 1)
	var striking_now: bool = melee.elapsed >= melee.windup and strike < 1.0
	var carry: Transform3D = carry_transform()
	var target: Transform3D
	var twist: float = 0.0
	var dip: float = 0.0
	var anticipation: float = ease(minf(1.0, windup / .7), .35)
	var release: float = 1.0 - ease(settle, 2.0)
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
	trail.emitting = melee.elapsed >= melee.windup * .9 and (strike < 1.0 or settle < .2)
	weapon.transform = target
	_turn("Abdomen", Vector3.UP, twist * .45)
	_turn("Torso", Vector3.UP, twist * .55)
	_turn("Abdomen", Vector3.RIGHT, dip * 2.5)
	_drop(dip)


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


func _staged(delta: float) -> void:
	var seated: bool = story_pose in SEATED
	var blend: float = 1.0 - exp(-7.0 * delta)
	sit = lerpf(sit, 1.0 if seated else 0.0, blend)
	if was_seated and not seated:
		standing_left = ANIMATIONS.get_animation("stand_up").length * .7
	was_seated = seated
	standing_left = maxf(0.0, standing_left - delta)
	var targets: Array[Vector3] = [DESK_HANDS[0] + Vector3(0, absf(sin(clock * 13.0)) * .018, 0), DESK_HANDS[1] + Vector3(0, absf(sin(clock * 11.0 + 1.3)) * .018, 0)]
	var look: Vector2 = Vector2(.12, 0)
	var target_lean: float = -.12
	var reach: float = 1.0
	match story_pose:
		Pose.ALERT:
			targets = [Vector3(-.2, .92, -.42), Vector3(.16, .92, -.42)]
			look = Vector2(-.04, 0)
			target_lean = .02
		Pose.SLUMP:
			targets = [Vector3(-.22, .62, -.25), Vector3(.22, .62, -.25)]
			look = Vector2(.55, .05)
			target_lean = -.32
		Pose.SIP:
			targets = [DESK_HANDS[0], Vector3(.08, 1.18, -.22)]
			look = Vector2(-.12, .08)
			target_lean = .08
		Pose.RELAX:
			targets = [Vector3(-.14, 1.45, .12), Vector3(.14, 1.45, .12)]
			look = Vector2(-.22, 0)
			target_lean = .25
		Pose.GLANCE:
			targets = [Vector3(-.2, .84, -.46), Vector3(.16, .84, -.46)]
			look = Vector2(.02, -.4)
			target_lean = -.05
		Pose.ARMED:
			look = Vector2(-.04, 0)
			target_lean = 0.0
			reach = 0.0
		Pose.COOL:
			# Turned away from the mess, arms folded, the Monolith planted beside him.
			look = Vector2(.12, -.3)
			target_lean = 0.0
			reach = 0.0
	# Hands on the desk stay on the desk while the body is lifted onto the cushion.
	var on_desk: Array[bool] = [story_pose != Pose.SLUMP and story_pose != Pose.RELAX, story_pose in [Pose.TYPING, Pose.ALERT, Pose.GLANCE]]
	for side in [0, 1]:
		hands[side] = hands[side].lerp(targets[side] - (SEATED_OFFSET * sit if on_desk[side] else Vector3.ZERO), blend)
	head_turn = head_turn.lerp(look, blend)
	lean = lerpf(lean, target_lean, blend)
	position = SEATED_OFFSET * sit
	if story_pose == Pose.COOL:
		_loop("fold_arms", 1.0, .2, delta)
	elif seated:
		_scrub("sit_down", ANIMATIONS.get_animation("sit_down").length, .3, delta)
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
	# The improvised weapon lies across the desk until the engineer reaches for it.
	held = move_toward(held, 0.0 if seated else 1.0, delta * 3.0)
	if seated:
		weapon.transform = Transform3D(Basis.from_euler(Vector3(0, -1.2, 0)), Vector3(.3, .8, -.62) - SEATED_OFFSET * sit)


func _solve(delta: float) -> void:
	var swinging: bool = actor != null and actor.melee != null and actor.melee.attacking
	if swinging or story_pose in SEATED:
		right_target.position = weapon.transform * RIGHT_GRIP if not story_pose in SEATED else hands[1]
		left_target.position = weapon.transform * LEFT_GRIP if not story_pose in SEATED else hands[0]
		right_pole.position = Vector3(.75, .35, .55)
		left_pole.position = Vector3(-.75, .35, .55)
	right_ik.influence = clampf(right_reach, 0, 1)
	left_ik.influence = clampf(left_reach, 0, 1)
	right_ik.active = right_ik.influence > .001
	left_ik.active = left_ik.influence > .001
	# The Monolith rests on the right shoulder whenever it is not swinging (and in the
	# finisher's hero pose); the right hand goes up to hold it there.
	var resting: bool = (story_pose < Pose.TYPING and actor != null and actor.melee != null \
		and not actor.melee.attacking and not actor.dodging and actor.health > 0 and actor.hurt_left <= 0)
	shoulder_rest = move_toward(shoulder_rest, 1.0 if resting else 0.0, delta * (5.0 if resting else 12.0))
	if shoulder_rest > 0.0:
		right_target.position = shoulder_transform() * RIGHT_GRIP
		right_pole.position = Vector3(.8, .2, .3)
		right_ik.influence = maxf(right_ik.influence, shoulder_rest)
		right_ik.active = true
	skeleton.advance(delta)
	if held > 0.0:
		weapon.transform = weapon.transform.interpolate_with(carry_transform(), held)
	if shoulder_rest > 0.0:
		weapon.transform = weapon.transform.interpolate_with(shoulder_transform(), smoothstep(0.0, 1.0, shoulder_rest))
	if story_pose == Pose.COOL:
		weapon.transform = planted_transform()
	trail.sample()
	_glow()


func _glow() -> void:
	if eye_material == null:
		return
	eye_material.emission_energy_multiplier = 2.6 * battle
	var hue: Color = Color.from_hsv(fmod(clock * .35, 1.0), .75, 1.0)
	for material in rim_materials:
		material.emission = Color(.08, .62, .66).lerp(hue, battle)
		material.emission_energy_multiplier = .25 + 2.6 * battle


func _scrub(clip: String, time: float, blend: float, delta: float) -> void:
	var name: String = "rig/" + clip
	if animator.current_animation != name:
		animator.play(name, blend)
	animator.speed_scale = 1.0
	animator.seek(maxf(0.0, time - delta), false)
	animator.advance(delta)


func _loop(clip: String, rate: float, blend: float, delta: float) -> void:
	var name: String = "rig/" + clip
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


## Identity pass: recolor the stock body into the on-call engineer and add his kit.
func _dress() -> void:
	var body: MeshInstance3D = skeleton.find_children("*", "MeshInstance3D", false, false)[0]
	var palette: Dictionary = {
		"Skin": Color(.56, .37, .26), "Shirt": Color(.15, .16, .19), "Pants": Color(.08, .11, .16),
		"Belt": Color(.05, .05, .06), "Hair": Color(.05, .04, .04), "Face": Color(.03, .035, .04),
	}
	for surface in body.mesh.get_surface_count():
		var source: Material = body.mesh.surface_get_material(surface)
		if source == null or not palette.has(source.resource_name):
			continue
		var material: StandardMaterial3D = (source as StandardMaterial3D).duplicate()
		material.albedo_color = palette[source.resource_name]
		material.roughness = .85
		if source.resource_name == "Face":
			material.emission_enabled = true
			material.emission = Color(.35, .95, 1.0)
			material.emission_energy_multiplier = 0.0
			eye_material = material
		body.set_surface_override_material(surface, material)
	for edge in weapon.find_children("Edge*", "MeshInstance3D", false, false):
		var rim: StandardMaterial3D = ((edge as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
		(edge as MeshInstance3D).material_override = rim
		rim_materials.append(rim)
	var unit: float = 1.0 / (skeleton.global_basis.get_scale().x if skeleton.is_inside_tree() else 100.0 * model_scale)
	var neck: Node3D = _attach("Neck", unit)
	var phones: MeshInstance3D = MeshInstance3D.new()
	var band: TorusMesh = TorusMesh.new()
	band.inner_radius = .1
	band.outer_radius = .135
	band.rings = 20
	band.ring_segments = 8
	band.material = _flat(Color(.04, .045, .05), .4)
	phones.mesh = band
	phones.position = Vector3(0, .02, 0)
	neck.add_child(phones)
	for side in [-1.0, 1.0]:
		var cup: MeshInstance3D = MeshInstance3D.new()
		var shell: CylinderMesh = CylinderMesh.new()
		shell.top_radius = .055
		shell.bottom_radius = .055
		shell.height = .05
		shell.material = _flat(Color(.08, .62, .66), .3, true)
		cup.mesh = shell
		cup.position = Vector3(side * .125, .02, .02)
		cup.rotation = Vector3(0, 0, PI * .5)
		neck.add_child(cup)
	var torso: Node3D = _attach("Torso", unit)
	var note: MeshInstance3D = MeshInstance3D.new()
	var paper: BoxMesh = BoxMesh.new()
	paper.size = Vector3(.15, .15, .01)
	paper.material = _flat(Color(.98, .86, .3), .9)
	note.mesh = paper
	note.name = "StickyNote"
	note.position = Vector3(-.03, .16, -.16)
	note.rotation = Vector3(0, PI, .12)
	torso.add_child(note)
	var text: Label3D = Label3D.new()
	text.text = "ON CALL\n(FOREVER)"
	text.font_size = 22
	text.pixel_size = .0014
	text.modulate = Color(.15, .12, .08)
	text.outline_size = 0
	text.position = Vector3(0, 0, .007)
	note.add_child(text)
	var badge: MeshInstance3D = MeshInstance3D.new()
	var card: BoxMesh = BoxMesh.new()
	card.size = Vector3(.08, .1, .01)
	card.material = _flat(Color(.72, .74, .67), .8)
	badge.mesh = card
	badge.position = Vector3(.1, .08, .17)
	torso.add_child(badge)


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
