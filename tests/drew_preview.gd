extends SceneTree
## Actual incident lighting and recruiter location; no gameplay state is saved.
var scene: Node3D
var incident: Node3D
var camera: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute("res://builds")
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	incident = scene.get_node("Incident")
	incident.presentation.skip()
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	var player: CharacterBody3D = scene.get_node("Player")
	player.camera_rig.capture_changed.disconnect(scene._on_capture_changed)
	player.set_physics_process(false)
	player.position = Vector3(7.0, 1.55, -7.0)
	scene.get_node("HUD").hide()
	paused = false
	var crew: Node3D = incident.coworkers
	crew.set_process(false)
	var person: Dictionary = crew.person("Recruiter")
	var body: Node3D = person.body
	var animator: AnimationPlayer = person.animator
	camera = Camera3D.new()
	camera.fov = 40.0
	scene.add_child(camera)
	camera.current = true
	var turn: Basis = Basis(Vector3.UP, body.rotation.y)
	camera.global_position = body.global_position + turn * Vector3(-2.1, 1.5, 3.6)
	camera.look_at(body.global_position + Vector3.UP * 1.1)
	for entry: Array in [["CharacterArmature|Idle", .5, "idle"], ["ual/talking", .8, "talking"], ["CharacterArmature|Defeat", .7, "cower"]]:
		animator.play(entry[0], 0.0)
		animator.seek(entry[1], true)
		animator.pause()
		await _grab("drew_" + entry[2])
	camera.current = false
	(player.get_node("CameraRig/SpringArm3D/Camera3D") as Camera3D).make_current()
	player.position = body.position + Vector3(0, .05, 1.6)
	var target: Dictionary = incident.talk_target()
	assert(target.get("name", "") == "Recruiter")
	incident.talk(target)
	assert(incident.dialogue.is_open())
	incident._talk_frame("them", .8, 1, "We're like a family here.")
	await _grab("drew_dialogue")
	incident.dialogue.close()
	scene.queue_free()
	await create_timer(.25).timeout
	quit()


func _grab(label: String) -> void:
	for index in range(90):
		await process_frame
	var times: Array[float] = []
	var previous: int = Time.get_ticks_usec()
	for index in range(120):
		await process_frame
		var now: int = Time.get_ticks_usec()
		times.append(float(now - previous) / 1000.0)
		previous = now
	times.sort()
	var total: float = 0.0
	for sample in times:
		total += sample
	print(label, " staged 1080p review: mean ", total / times.size(), " ms; p95 ", times[113], " ms (presentation/vsync included)")
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png("res://builds/" + label + ".png")
	assert(error == OK)
	print("CAPTURE ", label)
