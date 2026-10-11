extends SceneTree
## Screenshots, or add -- --play to start beside the pantry appliances.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var scene: Node3D = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var incident: Node = scene.get_node("Incident")
	incident.presentation.skip()
	incident._cleanup()
	var room: Node3D = incident.room
	var pantry: Node3D = room.get_node("PantryAntics")
	if "--play" in OS.get_cmdline_user_args():
		incident._enter(incident.Stage.INVESTIGATION)
		scene.get_node("Player").position = Vector3(22.5, .05, 7.0)
		scene.get_node("Player").camera_rig.set_capture(true)
		paused = false
		return
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(19.6, 3.0, 14.0)
	camera.look_at(Vector3(24.8, 1.2, 6.8))
	camera.fov = 65
	camera.make_current()
	scene.get_node("HUD").hide()
	incident.presentation.feed.hide()
	incident.presentation.feed.modulate.a = 0.0
	scene.get_node("Player").position = Vector3(16, .05, 8)
	paused = false
	DirAccess.make_dir_recursive_absolute("res://builds")
	for key: String in ["room", "microwave", "vending", "fridge", "poster"]:
		if key == "microwave":
			camera.position = Vector3(27.1, 2.4, 6.8)
			camera.look_at(Vector3(30.0, 1.8, 8.8))
		elif key == "vending":
			camera.position = Vector3(23.6, 2.2, 12.5)
			camera.look_at(Vector3(20.4, 1.6, 14.5))
		elif key == "fridge":
			camera.position = Vector3(26.8, 2.4, 9.6)
			camera.look_at(Vector3(29.8, 1.8, 11.55))
		elif key == "poster":
			camera.position = Vector3(21.0, 2.4, 6.5)
			camera.look_at(Vector3(23.4, 1.9, 2.1))
		if key != "room":
			pantry.react(key, incident.coworkers)
		for index in range(45):
			await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://builds/pantry_" + key + ".png")
		print("CAPTURE pantry_", key)
	# Warm, fixed-room graphical sample; ordinary-run performance is a separate gate.
	camera.position = Vector3(19.6, 3.0, 14.0)
	camera.look_at(Vector3(24.8, 1.2, 6.8))
	pantry.react("microwave", incident.coworkers)
	var samples: Array[float] = []
	var previous: int = Time.get_ticks_usec()
	for index in range(180):
		await process_frame
		var now: int = Time.get_ticks_usec()
		samples.append((now - previous) / 1000.0)
		previous = now
	samples.sort()
	var total: float = 0.0
	for ms: float in samples:
		total += ms
	print("PANTRY PERF: 1600x900 Forward+ warm fixed-camera sample; mean %.2f ms, p95 %.2f ms, max %.2f ms" % [total / samples.size(), samples[int(samples.size() * .95)], samples.back()])
	quit()
