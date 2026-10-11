extends Node3D
## The final blow, as a cutscene: when the engineer lands what would kill The Variance,
## the fight cuts to a duel. A wide standoff across the vault and a close-up on him; the
## charge; a shaft lock, ducked trident sweep, riposte and blocked smash; the boss throws
## him back, he recovers and charges again. The action keeps one camera side. Then,
## screaming "CLOSED! AS! WON'T! FIX!", he takes it apart a word at a time: an arm, the
## other arm, the head, and a leaping slam that splits what is left in half. The limbs
## fly and stay where they land. The real boss dies there (sliced, already missing what
## the duel took) and the finale (all_hands.gd) takes over. The staged monster plays the
## duel; the real one is hidden and still until the cut. Real time; TAB lands the blow.

const STANDOFF: Array[Vector3] = [Vector3(9.0, .05, -33.6), Vector3(9.0, .05, -41.4)]
const MEET: Vector3 = Vector3(9.0, 1.4, -37.6)
## Where the monster's chest is once they are locked together.
const CHEST: Vector3 = Vector3(9.0, 1.5, -38.6)
## One readable side of the action axis throughout the exchange. Contacts are
## authored in world space and both rigs are sampled before the impact is emitted.
const CONTACTS: Array[float] = [3.65, 7.55, 8.8, 9.25]
var guard: Transform3D = Transform3D(Basis.from_euler(Vector3(.15, -.3, -.5)), Vector3(.13, 1.12, -.48))
var loaded: Transform3D = Transform3D(Basis.from_euler(Vector3(1.25, -.7, .45)), Vector3(.34, 1.3, .12))
var cut: Transform3D = Transform3D(Basis.from_euler(Vector3(-.15, .2, -.2)), Vector3(.02, 1.0, -.7))
var low: Transform3D = Transform3D(Basis.from_euler(Vector3(-.4, -.6, .3)), Vector3(.3, .55, -.35))
## "CLOSED! AS! WON'T! FIX!": [word, when it lands after the line starts, camera offset
## from the monster's chest, swing style, what comes off ("" for the split), fov]. Each
## angle shows the side that is about to lose something.
const WORDS: Array = [
	["CLOSED", .1, Vector3(-3.0, .1, 1.6), 0, "UpperArm.L", 46.0],
	["AS", .65, Vector3(3.1, -.4, 1.4), 1, "UpperArm.R", 46.0],
	["WON'T", 1.15, Vector3(1.6, 1.9, 2.4), 0, "Head", 42.0],
	["FIX", 1.65, Vector3(-1.4, 3.6, 4.4), 2, "", 50.0]]
## What the duel took, so the real Variance dies without them too.
const SEVERED: Array[String] = ["UpperArm.L", "UpperArm.R", "Head"]
const SHOUT_AT: float = 13.2
const GORE_LAYER: int = 1 << 7

var story: Node
var incident: Node
var player: CharacterBody3D
var character: Node3D
var boss: CharacterBody3D
var demon: Node3D
var clock: float = 0.0
var done: bool = false
var beat: String = "standoff"
var contact: Vector3 = Vector3.ZERO
var boss_skeleton: Skeleton3D
var boss_iks: Array[TwoBoneIK3D] = []
var boss_targets: Array[Node3D] = []
var boss_poles: Array[Node3D] = []
var previous_modifier_mode: int
var cleaned: bool = false
var trident: Node3D
var trident_frame: Transform3D = Transform3D.IDENTITY
var trident_root: Transform3D = Transform3D.IDENTITY
## Measured from the trident mesh's Middle1.L skin bind; points on its shaft.
const SHAFT_CONTACT: Vector3 = Vector3(-.35, .18, -.13)
const SHAFT_SUPPORT: Vector3 = Vector3(.2, .1, -.13)
var weapon_contact: Vector3 = Vector3.ZERO
var wrist_rotation: Quaternion = Quaternion.IDENTITY
var shout: AudioStreamPlayer


func _init(presentation: Node, real_boss: CharacterBody3D) -> void:
	story = presentation
	incident = presentation.incident
	player = incident.player
	character = player.get_node("Visual/Character")
	boss = real_boss
	demon = presentation.demon
	name = "Duel"


## Put back what a duel took off the staged monster (it is reused next run).
static func restore(monster: Node3D) -> void:
	var skeleton: Skeleton3D = monster.model.find_child("Skeleton3D", true, false)
	for bone in SEVERED:
		skeleton.set_bone_pose_scale(skeleton.find_bone(bone), Vector3.ONE)
	# And the stumps stop bleeding.
	for blood in monster.get_children():
		if blood is CPUParticles3D:
			blood.queue_free()


func start() -> void:
	boss.moves.cancel()
	boss.hide()
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	for copy in incident.copies:
		if is_instance_valid(copy):
			copy.hide()
	restore(demon)
	_setup_contacts()
	demon.global_position = STANDOFF[1]
	demon.rotation.y = PI
	demon.show()
	demon.animator.play(demon.clips.attack, .1)
	player.global_position = STANDOFF[0]
	player.velocity = Vector3.ZERO
	player.visual.rotation.y = 0.0
	player.narrative_hold = true
	character.story_pose = character.Pose.ARMED
	character.weapon.show()
	ElementFx.flash(incident, STANDOFF[0] + Vector3.UP * 1.2, Color(1, .8, .3), 5.0, 6.0, .4)
	story.sting(preload("res://assets/audio/sfx/low_boom.ogg"), -2)
	shout = AudioStreamPlayer.new()
	shout.bus = &"Voice"
	shout.stream = load("res://assets/audio/voices/talk/call_wontfix.ogg")
	add_child(shout)


## Returns false once the blow has landed.
func tick(delta: float) -> bool:
	if done:
		return false
	var real: float = delta / maxf(Engine.time_scale, .01)
	var before: float = clock
	clock += real
	var t: float = clock
	player.narrative_hold = true
	player.invulnerable_left = maxf(player.invulnerable_left, .3)
	incident.main.get_node("HUD").visible = false
	var camera: Camera3D = story.camera
	var hero: Vector3 = player.global_position
	camera.rotation.z = 0.0
	if t < SHOUT_AT:
		_exchange(t, camera)
		for index in CONTACTS.size():
			if before < CONTACTS[index] and t >= CONTACTS[index]:
				_impact(index)
	else:
		# "CLOSED! AS! WON'T! FIX!": a word, a cut, a slash, and something comes off.
		if before < SHOUT_AT:
			_clear_contacts()
			character.end_duel()
			if DisplayServer.get_name() != "headless":
				shout.play()
			ElementFx.flash(incident, hero + Vector3.UP * 1.2, Color(1, .8, .3), 6.0, 8.0, .3)
		beat = "finisher"
		demon.animator.advance(real)
		var word: Array = WORDS[0]
		for entry: Array in WORDS:
			if t >= SHOUT_AT + entry[1]:
				word = entry
			if before < SHOUT_AT + entry[1] and t >= SHOUT_AT + entry[1]:
				_slash(entry)
		var since: float = t - SHOUT_AT - word[1]
		character.finish_progress = clampf(since / (.6 if word[3] == 2 else .45), 0.0, 1.0)
		player.global_position = MEET + Vector3(0, -1.35, 1.0)
		if word[3] == 2:
			# The leap: up and down onto it.
			player.global_position += Vector3.UP * sin(clampf(since / .5, 0.0, 1.0) * PI) * 1.4
		camera.global_position = CHEST + word[2] + (CHEST - (CHEST + word[2])).normalized() * since * .4
		camera.look_at(CHEST + Vector3.UP * (.4 if word[3] == 2 else 0.0))
		camera.fov = word[5]
		if t >= SHOUT_AT + WORDS[-1][1] + .55:
			land()
			return false
	camera.make_current()
	return true


## The blow lands: the real Variance takes the monster's place, missing what the duel
## took, and is cut in half.
func land() -> void:
	if done:
		return
	done = true
	_clear_contacts()
	character.end_duel()
	# The finale starts when it dies; it starts from a clear beat.
	story.beat_shot = ""
	ElementFx.release_freeze()
	character.story_pose = 0
	character.finish_progress = 0.0
	demon.hide()
	boss.process_mode = Node.PROCESS_MODE_PAUSABLE
	boss.global_position = Vector3(MEET.x, STANDOFF[1].y, MEET.z - 1.0)
	boss.visual.rotation.y = PI
	var skeleton: Skeleton3D = boss.rig.model.find_child("Skeleton3D", true, false)
	for bone in SEVERED:
		skeleton.set_bone_pose_scale(skeleton.find_bone(bone), Vector3.ONE * .001)
	boss.show()
	boss.set_meta("kill_style", "slice")
	boss.knockback = Vector3.FORWARD * 6.0
	player.global_position = MEET + Vector3(0, -1.35, 1.0)
	ElementFx.bolt(incident, MEET + Vector3(0, 2.2, -1.0), MEET + Vector3(0, -1.3, -1.0), Color(1, .97, .85), .4, .12)
	ElementFx.flash(incident, MEET, Color(1, .95, .85), 10.0, 14.0, .4)
	story.sting(preload("res://assets/audio/sfx/whoosh_slice.ogg"), -1)
	boss.final_blow()
	queue_free()


## These temporary IK modifiers live only for this duel, never in combat AI.
func _setup_contacts() -> void:
	boss_skeleton = demon.model.find_child("Skeleton3D", true, false)
	trident = demon.model.find_child("Trident", true, false) as Node3D
	wrist_rotation = boss_skeleton.get_bone_pose_rotation(boss_skeleton.find_bone("Middle1.L"))
	previous_modifier_mode = boss_skeleton.modifier_callback_mode_process
	boss_skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	for side: String in ["L", "R"]:
		var target: Node3D = Node3D.new()
		var pole: Node3D = Node3D.new()
		add_child(target)
		add_child(pole)
		boss_targets.append(target)
		boss_poles.append(pole)
		var ik: TwoBoneIK3D = TwoBoneIK3D.new()
		ik.name = "Duel" + side
		ik.setting_count = 1
		boss_skeleton.add_child(ik)
		ik.set_root_bone_name(0, "UpperArm." + side)
		ik.set_middle_bone_name(0, "LowerArm." + side)
		ik.set_end_bone_name(0, "Middle1." + side)
		ik.set_target_node(0, ik.get_path_to(target))
		ik.set_pole_node(0, ik.get_path_to(pole))
		ik.influence = 0.0
		boss_iks.append(ik)
	boss_iks[-1].modification_processed.connect(_measure_trident)
	_measure_trident()


func _clear_contacts() -> void:
	if cleaned:
		return
	cleaned = true
	for ik in boss_iks:
		ik.active = false
		ik.queue_free()
	if is_instance_valid(boss_skeleton):
		boss_skeleton.modifier_callback_mode_process = previous_modifier_mode
		boss_skeleton.set_bone_pose_rotation(boss_skeleton.find_bone("Middle1.L"), wrist_rotation)
	if is_instance_valid(character) and character.duel_active:
		character.end_duel()


func _exit_tree() -> void:
	_clear_contacts()


## Snapshot the final wrist pose while modifiers are applied (the skeleton restores
## its input afterward). The authored trident is skinned entirely to this left wrist.
func _measure_trident() -> void:
	trident_frame = boss_skeleton.global_transform * boss_skeleton.get_bone_global_pose(boss_skeleton.find_bone("Middle1.L"))
	trident_root = demon.global_transform
	weapon_contact = trident_frame * SHAFT_CONTACT


func _phase(t: float, start_at: float, end_at: float) -> float:
	return clampf((t - start_at) / (end_at - start_at), 0.0, 1.0)


func _boss_pose(role: String, progress: float, left: Vector3, right: Vector3, influence: float) -> void:
	var clip: String = demon.clips.get(role, demon.clips.idle)
	if demon.animator.current_animation != clip:
		demon.animator.play(clip, 0.0)
	demon.animator.seek(demon.animator.get_animation(clip).length * clampf(progress, 0.0, .999), true)
	var wrist: int = boss_skeleton.find_bone("Middle1.L")
	var roll: float = sin(_phase(clock, 5.6, 6.8) * PI) * PI * .5 if beat == "duck" else 0.0
	boss_skeleton.set_bone_pose_rotation(wrist, wrist_rotation * Quaternion(Vector3.UP, roll))
	for index in 2:
		boss_targets[index].global_position = left if index == 0 else right
		boss_poles[index].global_position = demon.global_position + Vector3(-1.7 if index == 0 else 1.7, 1.3, -.2)
		boss_iks[index].influence = influence
		boss_iks[index].active = influence > .001
	boss_skeleton.advance(0.0)


## The engineer faces -Z, the boss +Z. Position curves keep their feet planted
## during holds; clips supply weight transfer and IK supplies shared contacts.
func _exchange(t: float, camera: Camera3D) -> void:
	var hero_at: Vector3 = MEET + Vector3(0, -1.35, 1.15)
	var boss_at: Vector3 = MEET + Vector3(0, -1.35, -1.13)
	var blade: Transform3D = guard
	var hero_clip: String = "sword_block"
	var hero_phase: float = .45
	var body: Vector3 = Vector3.ZERO
	var ribbon: bool = false
	var boss_role: String = "idle"
	var boss_phase: float = .2
	var grip: float = 0.0
	var camera_at: Vector3 = MEET + Vector3(5.4, .3, 2.0)
	var focus: Vector3 = MEET
	var fov: float = 50.0
	var punch: Vector3 = MEET + Vector3(0, -.1, .2)
	if t < 1.7:
		beat = "standoff"
		hero_at = STANDOFF[0]
		boss_at = STANDOFF[1]
		blade = loaded
		hero_clip = "sword_block"
		hero_phase = .45
		camera_at = MEET + Vector3(5.9 - t * .3, -.3, .4)
		fov = 60.0
		if t >= .9:
			camera_at = hero_at + Vector3(-.7, 1.55, -1.7)
			focus = hero_at + Vector3.UP * 1.35
			fov = 36.0
	elif t < 3.0:
		beat = "charge"
		var u: float = smoothstep(1.7, 3.0, t)
		hero_at = STANDOFF[0].lerp(hero_at, u)
		boss_at = STANDOFF[1].lerp(boss_at, u)
		blade = loaded
		hero_clip = "run"
		hero_phase = fmod((t - 1.7) * 1.8, 1.0)
		boss_role = "run"
		boss_phase = fmod((t - 1.7) * 1.3, 1.0)
		camera_at = MEET + Vector3(6.6, -.6, 1.0)
		fov = 60.0
	elif t < 4.8:
		beat = "catch"
		var swing: float = smoothstep(3.15, 3.65, t)
		blade = loaded.interpolate_with(cut, swing)
		hero_clip = "sword_a"
		hero_phase = lerpf(.36, .53, swing)
		boss_role = "attack"
		boss_phase = lerpf(.15, .43, swing)
		grip = smoothstep(3.35, 3.65, t)
		ribbon = t < 3.65
		camera_at = MEET + Vector3(4.1, .0, 1.5).lerp(Vector3(3.3, .15, 1.2), _phase(t, 3.65, 4.8))
		fov = 44.0
	elif t < 5.6:
		beat = "break"
		var u: float = smoothstep(4.8, 5.6, t)
		hero_at += Vector3(.65, 0, .55) * u
		boss_at += Vector3(.2, 0, .3) * u
		blade = cut.interpolate_with(low, u)
		hero_clip = "hit"
		hero_phase = u * .65
		boss_role = "attack"
		boss_phase = lerpf(.43, .65, u)
	elif t < 6.8:
		beat = "duck"
		var u: float = _phase(t, 5.6, 6.8)
		hero_at += Vector3(.65, 0, .55)
		boss_at += Vector3(.2, 0, .3)
		body.y = -.45 * sin(u * PI)
		blade = low
		hero_clip = "roll"
		hero_phase = lerpf(.05, .25, sin(u * PI))
		boss_role = "attack"
		boss_phase = lerpf(.15, .8, u)
		punch = hero_at + Vector3(lerpf(-1.2, 1.2, u), 1.55, -.1)
		grip = sin(u * PI)
		camera_at = MEET + Vector3(4.6, -.3, 2.8)
	elif t < 8.0:
		beat = "riposte"
		var u: float = smoothstep(6.8, 7.55, t)
		hero_at += Vector3(.65, 0, .55).lerp(Vector3(.35, 0, -.7), u)
		boss_at += Vector3(.2, 0, .3).lerp(Vector3(-.25, 0, -.15), smoothstep(7.55, 8.0, t))
		blade = low.interpolate_with(cut, u)
		hero_clip = "sword_a"
		hero_phase = lerpf(.36, .64, u)
		ribbon = t < 7.75
		boss_role = "hit" if t >= 7.55 else "attack"
		boss_phase = _phase(t, 7.55, 8.0) * .6 if t >= 7.55 else .75
		camera_at = MEET + Vector3(4.4, -.4, 2.3)
	elif t < 9.25:
		beat = "block"
		var u: float = smoothstep(8.0, 8.8, t)
		hero_at += Vector3(.35, 0, -.7).lerp(Vector3(.35, 0, -.15), u)
		boss_at += Vector3(-.25, 0, -.15).lerp(Vector3(.0, 0, .45), u)
		blade = cut.interpolate_with(guard, u)
		boss_role = "attack"
		boss_phase = lerpf(.12, .45, u)
		grip = smoothstep(8.45, 8.8, t)
		camera_at = MEET + Vector3(3.6, .5, 2.4)
		fov = 46.0
	elif t < 10.5:
		beat = "knockback"
		var u: float = 1.0 - pow(1.0 - _phase(t, 9.25, 10.5), 3.0)
		hero_at += Vector3(.35, 0, -.15).lerp(Vector3(.5, 0, 3.1), u)
		boss_at += Vector3(0, 0, .45).lerp(Vector3(-.25, 0, -.15), u)
		blade = guard.interpolate_with(low, u)
		hero_clip = "hit"
		hero_phase = lerpf(.05, .85, u)
		body.y = -.2 * u
		boss_role = "attack"
		boss_phase = lerpf(.45, .85, u)
		camera_at = MEET + Vector3(4.8, -.2, 4.8)
		focus = MEET + Vector3(0, -.2, 1.1)
		fov = 58.0
	elif t < 12.3:
		beat = "recover"
		hero_at += Vector3(.5, 0, 3.1)
		boss_at += Vector3(-.25, 0, -.15)
		var u: float = smoothstep(10.5, 11.6, t)
		body.y = lerpf(-.2, 0.0, u)
		blade = low.interpolate_with(loaded, u)
		hero_clip = "sword_block"
		hero_phase = .45
		camera_at = hero_at + Vector3(-.7, 1.45, -1.65)
		focus = hero_at + Vector3.UP * 1.25
		fov = 35.0
	else:
		beat = "comeback"
		var u: float = smoothstep(12.3, SHOUT_AT, t)
		hero_at += Vector3(.5, 0, 3.1).lerp(Vector3(0, 0, -.15), u)
		boss_at += Vector3(-.25, 0, -.15).lerp(Vector3(0, 0, .25), u)
		blade = loaded
		hero_clip = "sword_dash"
		hero_phase = lerpf(.05, .4, u)
		boss_role = "attack"
		boss_phase = lerpf(.05, .2, u)
		camera_at = MEET + Vector3(5.0, -.5, 2.0)
		fov = 58.0
	player.global_position = hero_at
	player.visual.rotation.y = 0.0
	demon.global_position = boss_at
	demon.rotation.y = PI
	character.pose_duel(hero_clip, hero_phase, blade, body, 0.0, ribbon)
	# Frame the actual animated head: the sword clip's torso shifts away from the
	# controller origin, especially as he lifts the blade after the skid.
	if beat == "recover" or beat == "standoff" and t >= .9:
		focus = character.skeleton.global_transform * character.skeleton.get_bone_global_pose(character.bones["Head"]).origin
		camera_at = focus + Vector3(-1.2, .1, -2.4)
		fov = 38.0
	contact = character.weapon.global_transform * Vector3(0, 0, -.65)
	var carried: Transform3D = demon.global_transform * trident_root.affine_inverse() * trident_frame
	var left: Vector3 = contact + Vector3(-.12, .04, 0)
	var right: Vector3 = carried * SHAFT_SUPPORT
	if beat == "duck":
		left = punch
	_boss_pose(boss_role, boss_phase, left, right, grip)
	if beat in ["catch", "block"] and grip > .01:
		# Meet the shaft, rather than pretending the armed monster catches a blade
		# in its palm. Both of the engineer's hands follow the corrected sword.
		var shaft: Vector3 = carried * SHAFT_CONTACT
		blade.origin += character.global_basis.inverse() * (shaft - contact) * grip
		character.pose_duel(hero_clip, hero_phase, blade, body, 0.0, ribbon)
		contact = character.weapon.global_transform * Vector3(0, 0, -.65)
	camera.global_position = camera_at
	camera.look_at(focus)
	camera.fov = fov
	for at: float in CONTACTS:
		var recoil: float = 1.0 - _phase(t, at, at + .22) if t >= at else 0.0
		camera.position += Vector3(sin(t * 83.0), cos(t * 67.0), 0) * recoil * .035


func _impact(index: int) -> void:
	var at: Vector3 = contact
	if index == 1:
		at = demon.global_position + Vector3(0, 1.1, .35)
		Blood.burst(incident, at, Vector3.BACK, 18)
	elif index == 3:
		at = player.global_position + Vector3.UP
		ElementFx.shockwave(incident, player.global_position, Color(1, .35, .12), 2.5, .3)
	else:
		ElementFx.shards(incident, at, Color(1, .85, .4), 16, 4.0, .35)
	ElementFx.flash(incident, at, Color(1, .85, .6), 3.0, 4.0, .1)
	# Local contact holds are baked into the motion curves; this accent does not
	# slow the real-time director or introduce a gameplay damage event.
	var sound: AudioStream = preload("res://assets/audio/sfx/metal_block.ogg")
	if index == 1:
		sound = preload("res://assets/audio/sfx/whoosh_slice.ogg")
		boss.bark("hurt", 1.0)
	elif index == 3:
		sound = preload("res://assets/audio/sfx/heavy_impact.ogg")
	story.sting(sound, -2)


func _slash(word: Array) -> void:
	character.story_pose = character.Pose.FINISH
	character.finish_style = word[3]
	character.finish_progress = 0.0
	demon.animator.play(demon.clips.get("hit", demon.clips.attack), .03)
	var across: Vector3 = Vector3(randf_range(-1.0, 1.0), randf_range(-.6, .6), 0).normalized() * 1.6
	ElementFx.bolt(incident, CHEST - across, CHEST + across, Color(1, .3, .25), .25, .08)
	ElementFx.glyphs(incident, CHEST + Vector3(0, 1.4, .6), Color(1, .85, .35), [word[0]], .9, 0.0)
	Blood.burst(incident, CHEST, Vector3(0, .4, -1), 36)
	if not str(word[4]).is_empty():
		_sever(word[4])
	ElementFx.freeze(incident, .08 if word[3] != 2 else .18)
	story.sting(preload("res://assets/audio/sfx/whoosh_slice.ogg"), -4)


## Off it comes: the monster loses the bone's branch, and a copy that keeps only that
## branch flies off, bleeding, and stays where it lands (until the next run).
func _sever(bone: String) -> void:
	var skeleton: Skeleton3D = demon.model.find_child("Skeleton3D", true, false)
	var index: int = skeleton.find_bone(bone)
	var stump: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(index).origin
	var root: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Body")).origin
	var copy: Node3D = demon.model.duplicate()
	var piece: RigidBody3D = RigidBody3D.new()
	piece.collision_layer = GORE_LAYER
	piece.collision_mask = 1
	piece.mass = 1.5
	piece.angular_damp = 1.0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var ball: SphereShape3D = SphereShape3D.new()
	ball.radius = .28
	shape.shape = ball
	piece.add_child(shape)
	incident.add_child(piece)
	piece.global_position = stump
	piece.add_child(copy)
	copy.global_transform = demon.model.global_transform
	var copy_player: AnimationPlayer = copy.find_child("AnimationPlayer", true, false)
	if copy_player != null:
		copy_player.active = false
	var copy_skeleton: Skeleton3D = copy.find_child("Skeleton3D", true, false)
	for each in skeleton.get_bone_count():
		copy_skeleton.set_bone_pose_position(each, skeleton.get_bone_pose_position(each))
		copy_skeleton.set_bone_pose_rotation(each, skeleton.get_bone_pose_rotation(each))
		copy_skeleton.set_bone_pose_scale(each, skeleton.get_bone_pose_scale(each))
	# Everything else shrinks to nothing at the hips; the branch is scaled back up, so it
	# alone is left, sitting at the hips: move the copy so it sits where it was cut.
	for rest in ["Body", "Foot.L", "Foot.R"]:
		copy_skeleton.set_bone_pose_scale(copy_skeleton.find_bone(rest), Vector3.ONE * .001)
	copy_skeleton.set_bone_pose_scale(index, Vector3.ONE * 1000.0)
	copy.global_position += stump - root
	skeleton.set_bone_pose_scale(index, Vector3.ONE * .001)
	var away: Vector3 = (stump - demon.global_position) * Vector3(1, 0, 1)
	away = away.normalized() if away.length() > .05 else Vector3.LEFT
	piece.linear_velocity = away * 4.5 + Vector3.UP * (6.5 if bone == "Head" else 4.0) + Vector3.BACK * 1.5
	piece.angular_velocity = Vector3(randf_range(-9, 9), randf_range(-6, 6), randf_range(-9, 9))
	Blood.burst(incident, stump, away + Vector3.UP * .6, 50)
	Blood.spurt(piece, Vector3.ZERO, -away, .8)
	Blood.spurt(demon, demon.to_local(stump), away + Vector3.UP * .5, 1.2)
	Blood.splat(incident, Vector3(stump.x, .02, stump.z) + away * 1.2, Vector3.UP, 1.2)
	story.duel_pieces.append(piece)
