extends SceneTree
## Static actual-renderer tour; --before retains matching baseline views.


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node3D = load("res://game/main.tscn").instantiate()
	scene.set_script(null)
	for child in scene.get_children():
		if child.name not in [&"OfficeAfterHours", &"WorldEnvironment", &"KeyLight"]:
			scene.remove_child(child)
			child.free()
	root.add_child(scene)
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.current = true
	camera.fov = 70.0
	var suffix: String = "before" if "--before" in OS.get_cmdline_user_args() else "after"
	var views: Array[Array] = [
		["desks", Vector3(-3.2, 2.6, 13.5), Vector3(-7.5, 1.6, 2)],
		["floor", Vector3(3, 2.4, 10), Vector3(-1, 2.4, -10)],
		["conference", Vector3(6.5, 3.1, -4.2), Vector3(8, 2.8, -9)],
		["storage", Vector3(-5, 2.0, 11.5), Vector3(-10.8, 1.0, 15.1)]
	]
	DirAccess.make_dir_recursive_absolute("res://builds")
	for view in views:
		camera.position = view[1]
		camera.look_at(view[2])
		for index in range(90):
			await process_frame
		var samples: Array[float] = []
		var previous: int = Time.get_ticks_usec()
		for index in range(120):
			await process_frame
			var now: int = Time.get_ticks_usec()
			samples.append(float(now-previous)/1000.0)
			previous = now
		samples.sort()
		var total: float = 0.0
		for sample in samples:
			total += sample
		print("OFFICE %s %s 1920x1080: mean %.2f ms, p95 %.2f ms, draw calls %d; static, includes vsync" % [view[0], suffix, total/samples.size(), samples[113], Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
		await RenderingServer.frame_post_draw
		var error: Error = root.get_texture().get_image().save_png("res://builds/office_finish_%s_%s.png" % [view[0], suffix])
		if error != OK:
			push_error("Office capture failed: " + error_string(error))
			quit(1)
			return
	quit()
