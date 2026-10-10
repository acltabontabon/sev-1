extends Node3D
## The final blow, as a cutscene: when the engineer lands what would kill The Variance,
## the fight cuts to a duel. A wide standoff across the vault and a close-up on him; the
## charge; four clashes, each a two-shot from a new side; it shoves him back. Then,
## screaming "CLOSED! AS! WON'T! FIX!", he takes it apart a word at a time: an arm, the
## other arm, the head, and a leaping slam that splits what is left in half. The limbs
## fly and stay where they land. The real boss dies there (sliced, already missing what
## the duel took) and the finale (all_hands.gd) takes over. The staged monster plays the
## duel; the real one is hidden and still until the cut. Real time; TAB lands the blow.

const STANDOFF: Array[Vector3] = [Vector3(9.0, .05, -33.6), Vector3(9.0, .05, -41.4)]
const MEET: Vector3 = Vector3(9.0, 1.4, -37.6)
## Where the monster's chest is once they are locked together.
const CHEST: Vector3 = Vector3(9.0, 1.5, -38.6)
## Clashes: [time, camera offset from MEET, engineer swing style, fov]. Two-shots, both
## of them whole in frame, from a new side every time.
const CLASHES: Array = [
	[2.3, Vector3(4.2, -.9, .3), 0, 50.0],
	[2.9, Vector3(-1.6, 1.3, -4.4), 1, 46.0],
	[3.5, Vector3(1.2, -.7, 4.4), 0, 48.0],
	[4.1, Vector3(-4.0, 1.9, .9), 1, 50.0]]
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
const SHOUT_AT: float = 5.3
const GORE_LAYER: int = 1 << 7

var story: Node
var incident: Node
var player: CharacterBody3D
var character: Node3D
var boss: CharacterBody3D
var demon: Node3D
var clock: float = 0.0
var done: bool = false
var shove: float = 0.0
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
	demon.global_position = STANDOFF[1]
	demon.rotation.y = PI
	demon.show()
	demon.animator.play(demon.clips.attack, .1)
	player.global_position = STANDOFF[0]
	player.velocity = Vector3.ZERO
	player.visual.rotation.y = 0.0
	player.narrative_hold = true
	character.story_pose = character.Pose.ARMED
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
	demon.animator.advance(real)
	var camera: Camera3D = story.camera
	var hero: Vector3 = player.global_position
	camera.rotation.z = 0.0
	if t < .9:
		# The standoff, wide and low from the side: the vault between them.
		camera.global_position = MEET + Vector3(9.5 - t * 1.2, -.55, .4)
		camera.look_at(MEET + Vector3(0, -.2, 0))
		camera.fov = 52.0
	elif t < 1.6:
		# Close on him: gold in his hair, the Monolith coming up.
		camera.global_position = hero + Vector3(-.55, 1.55, -1.6) + Vector3(.1, 0, .25) * (t - .9)
		camera.look_at(hero + Vector3.UP * 1.4)
		camera.fov = 34.0
	elif t < 2.3:
		# The charge: both at once, low and side on, tracking.
		var run: float = smoothstep(1.6, 2.3, t)
		player.global_position = STANDOFF[0].lerp(MEET + Vector3(0, -1.35, 1.0), run)
		demon.global_position = STANDOFF[1].lerp(MEET + Vector3(0, -1.35, -1.0), run)
		if before < 1.6:
			demon.animator.play(demon.clips.run, .1)
			story.sting(preload("res://assets/audio/sfx/whoosh_dash.ogg"), -3)
		camera.global_position = MEET + Vector3(5.2, -.8, 0)
		camera.look_at(MEET + Vector3(0, -.3, 0))
		camera.fov = 58.0
	elif t < SHOUT_AT:
		# The exchange: four clashes, a hard cut on each; then it shoves him back.
		for clash: Array in CLASHES:
			if before < clash[0] and t >= clash[0]:
				_clash(clash[2])
		var last: Array = CLASHES[0]
		for clash: Array in CLASHES:
			if t >= clash[0]:
				last = clash
		character.finish_progress = clampf((t - last[0]) / .55, 0.0, .55)
		if t >= 4.7:
			if before < 4.7:
				demon.animator.play(demon.clips.attack, .05)
				story.sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -2)
				ElementFx.shockwave(incident, MEET + Vector3.DOWN * 1.3, Color(1, .2, .15), 3.0, .4)
			shove = smoothstep(4.7, 5.1, t)
			player.global_position = (MEET + Vector3(0, -1.35, 1.0)).lerp(MEET + Vector3(0, -1.35, 2.6), shove)
			# Low behind him as he skids back towards the lens.
			camera.global_position = MEET + Vector3(1.4, -.7, 5.6)
			camera.look_at(MEET + Vector3(0, -.1, 0))
			camera.fov = 48.0
		else:
			camera.global_position = MEET + last[1]
			camera.look_at(MEET + Vector3(0, -.15, 0))
			camera.fov = last[3]
			camera.rotate_object_local(Vector3.BACK, deg_to_rad(6.0 * (1 if CLASHES.find(last) % 2 == 0 else -1)))
	else:
		# "CLOSED! AS! WON'T! FIX!": a word, a cut, a slash, and something comes off.
		if before < SHOUT_AT:
			if DisplayServer.get_name() != "headless":
				shout.play()
			ElementFx.flash(incident, hero + Vector3.UP * 1.2, Color(1, .8, .3), 6.0, 8.0, .3)
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


func _clash(style: int) -> void:
	character.story_pose = character.Pose.FINISH
	character.finish_style = style
	character.finish_progress = 0.0
	demon.animator.play(demon.clips.attack, .05)
	ElementFx.flash(incident, MEET, Color(1, .95, .8), 7.0, 8.0, .12)
	ElementFx.shards(incident, MEET, Color(1, .85, .4), 26, 7.0, .5)
	ElementFx.shards(incident, MEET, Color(1, .25, .15), 14, 5.0, .4)
	ElementFx.shockwave(incident, MEET, Color(1, .9, .6), 2.0, .25, true)
	ElementFx.freeze(incident, .1)
	story.sting(preload("res://assets/audio/sfx/metal_block.ogg"), -2)


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
