extends Node3D
## Three brief recollections before Unpaid Overtime. Fresh, intact bodies keep the
## flashback separate from the casualties in the vault. All assets are already local.
const CREW = preload("res://game/incidents/coworkers.gd")
const MOTION: AnimationLibrary = preload("res://game/player/engineer_animations.res")
const LENGTH: float = 8.4
const EACH: float = LENGTH / 3.0
const CAST: Array = [
	["SRE", Vector3(.2, 0, 9.7), "ual/interact", PI],
	["Intern", Vector3(3.0, 0, 9.8), "ual/yes", PI],
	["Manager", Vector3(-1.2, 0, 13.4), "ual/phone", PI],
	["Designer", Vector3(1.6, 0, 13.5), "ual/talking", PI],
	["Director", Vector3(4.4, 0, 13.5), "ual/talking", PI],
]
var story: Node
var shot: int = -1
var whisper: AudioStreamPlayer


func _init(presentation: Node) -> void:
	story = presentation


func _ready() -> void:
	for memory: Array in CAST:
		var entry: Dictionary = story.incident.coworkers.person(memory[0]).entry
		var body: Node3D = load(CREW.ROOT + entry.body).instantiate()
		add_child(body)
		body.position = memory[1]
		body.scale = Vector3.ONE * .62
		body.rotation.y = memory[3]
		CREW.dress(body, entry.palette, entry.get("outfit", "office"))
		var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
		animator.add_animation_library("ual", MOTION)
		animator.play(memory[2])
		animator.speed_scale = .65
	var light: OmniLight3D = OmniLight3D.new()
	light.position = Vector3(1.5, 2.6, 11.5)
	light.light_color = Color(1, .77, .48)
	light.light_energy = 3.0
	light.omni_range = 8.0
	add_child(light)
	whisper = AudioStreamPlayer.new()
	whisper.bus = &"Voice"
	add_child(whisper)


func tick(time: float) -> void:
	var next: int = mini(2, int(time / EACH))
	var within: float = fmod(time, EACH)
	if next != shot:
		shot = next
		whisper.stop()
		# Fragments of conversations already heard tonight, fading like a recollection.
		var line: String = ["talk_sre_a", "talk_intern_a", "talk_designer_a"][shot]
		whisper.stream = load("res://assets/audio/voices/talk/" + line + ".ogg")
		if DisplayServer.get_name() != "headless":
			whisper.play()
	whisper.volume_db = -10.0 - 30.0 * smoothstep(EACH - .8, EACH, within)
	var push: float = smoothstep(0.0, EACH, within)
	var eye: Vector3
	var focus: Vector3
	if shot < 2:
		focus = CAST[shot][1] + Vector3.UP * 1.45
		eye = focus + Vector3(.75, .05, -2.2).lerp(Vector3(.55, .08, -1.7), push)
	else:
		focus = Vector3(1.6, 1.3, 12.2)
		eye = Vector3(5.2, 2.4, 8.4).lerp(Vector3(4.8, 2.2, 8.7), push)
	story.camera.global_position = eye
	story.camera.look_at(focus)
	story.camera.fov = 44.0 if shot < 2 else 56.0
	story.crew_freeze.show()
	(story.crew_freeze.material as ShaderMaterial).set_shader_parameter("amount", .65)
	(story.crew_freeze.material as ShaderMaterial).set_shader_parameter("tint", Color(1, .83, .62))
	# A dark eyelid between memories; no rapid full-screen flashes.
	story.fade.show()
	story.fade.color = Color(0, 0, 0, (1.0 - smoothstep(0.0, .2, within)) * .8 + smoothstep(EACH - .18, EACH, within) * .8)


func finish() -> void:
	whisper.stop()
	story.crew_freeze.hide()
	story.fade.hide()
	hide()
	queue_free()
