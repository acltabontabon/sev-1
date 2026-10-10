extends Node3D
## The final blow, as a cutscene: when the engineer lands what would kill The Variance,
## the fight cuts to a duel. They face off across the vault, charge, and clash four times
## (hard cuts round them, sparks, the Monolith against the trident); it shoves him back;
## then, screaming "CLOSED! AS! WON'T! FIX!", he cuts it once a word and the last one,
## a leaping slam, splits it in half. The real boss dies there (sliced), and the finale
## (all_hands.gd) takes over. The staged monster plays the duel; the real one is hidden
## and still until the cut. Presentation only, real time; TAB lands the blow at once.

const STANDOFF: Array[Vector3] = [Vector3(9.0, .05, -33.6), Vector3(9.0, .05, -41.4)]
const MEET: Vector3 = Vector3(9.0, 1.4, -37.6)
## Clash times and their cuts: [time, camera offset from MEET, engineer swing style].
const CLASHES: Array = [[2.3, Vector3(1.7, -1.0, 1.3), 0], [2.9, Vector3(-2.2, .4, -.8), 1], [3.5, Vector3(.4, 1.6, 2.4), 0], [4.1, Vector3(-1.4, -.9, 1.9), 1]]
## "CLOSED! AS! WON'T! FIX!": when each word lands after the line starts, and its cut.
const WORDS: Array = [["CLOSED", .1, Vector3(2.0, .2, 1.4), 0], ["AS", .65, Vector3(-2.1, -.3, .9), 1], ["WON'T", 1.15, Vector3(.8, -1.1, 2.3), 0], ["FIX", 1.65, Vector3(-.6, 2.4, 2.8), 2]]
const SHOUT_AT: float = 5.3
const LENGTH: float = 7.6

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


func start() -> void:
	boss.moves.cancel()
	boss.hide()
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	for copy in incident.copies:
		if is_instance_valid(copy):
			copy.hide()
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
	if t < 1.6:
		# The standoff: side on, low, a slow push. Neither moves.
		camera.global_position = MEET + Vector3(5.6 - t * .5, -.7, 0)
		camera.look_at(MEET)
		camera.fov = 52.0
	elif t < 2.3:
		# The charge: both at once, the camera low between them, tracking.
		var run: float = smoothstep(1.6, 2.3, t)
		player.global_position = STANDOFF[0].lerp(MEET + Vector3(0, -1.35, 1.0), run)
		demon.global_position = STANDOFF[1].lerp(MEET + Vector3(0, -1.35, -1.0), run)
		if before < 1.6:
			demon.animator.play(demon.clips.run, .1)
			story.sting(preload("res://assets/audio/sfx/whoosh_dash.ogg"), -3)
		camera.global_position = MEET + Vector3(3.4, -.9, 0)
		camera.look_at(MEET)
		camera.fov = 64.0
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
			camera.global_position = hero + Vector3(1.1, 1.3, 2.4)
			camera.look_at(MEET + Vector3.UP * .4)
			camera.fov = 46.0
		else:
			camera.global_position = MEET + last[1]
			camera.look_at(MEET)
			camera.fov = 44.0
	else:
		# "CLOSED! AS! WON'T! FIX!": a word, a cut, a slash; the last a leaping slam.
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
		camera.global_position = MEET + word[2]
		camera.look_at(MEET + Vector3.UP * (.6 if word[3] == 2 else 0.0))
		camera.fov = 40.0
		if t >= SHOUT_AT + WORDS[-1][1] + .55:
			land()
			return false
	camera.make_current()
	return true


## The blow lands: the real Variance takes the monster's place and is cut in half.
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
	ElementFx.bolt(incident, MEET + Vector3(0, .2, -1.0) - across, MEET + Vector3(0, .2, -1.0) + across, Color(1, .3, .25), .25, .08)
	ElementFx.glyphs(incident, MEET + Vector3(0, 1.6, -.6), Color(1, .85, .35), [word[0]], .9, 0.0)
	Blood.burst(incident, MEET + Vector3(0, 0, -1.0), Vector3(0, .4, -1), 36)
	ElementFx.freeze(incident, .08 if word[3] != 2 else .18)
	story.sting(preload("res://assets/audio/sfx/whoosh_slice.ogg"), -4)
