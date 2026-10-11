extends SceneTree
## Fixed-camera review in the actual office lighting. Run with a graphics device.


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node3D = load("res://game/main.tscn").instantiate()
	if not scene.has_node("OfficeAfterHours/YourWorkstation/DetailedDesk"):
		push_error("The polished workstation did not load.")
		quit(1)
		return
	scene.set_script(null)
	for child in scene.get_children():
		if child.name not in [&"OfficeAfterHours", &"WorldEnvironment", &"KeyLight"]:
			scene.remove_child(child)
			child.free()
	root.add_child(scene)
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(-.15, 2.15, 12.2)
	camera.look_at(Vector3(-2.5, .95, 9.4))
	camera.fov = 48.0
	camera.current = true
	for index in range(90):
		await process_frame
	var frame_times: Array[float] = []
	var previous: int = Time.get_ticks_usec()
	for index in range(120):
		await process_frame
		var now: int = Time.get_ticks_usec()
		frame_times.append(float(now - previous) / 1000.0)
		previous = now
	frame_times.sort()
	var total: float = 0.0
	for frame_time in frame_times:
		total += frame_time
	print("Static office review, 1920x1080, Forward+: mean ", total / frame_times.size(), " ms, p95 ", frame_times[113], " ms. Includes presentation/vsync; no combat or actors.")
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds")
	var error: Error = root.get_texture().get_image().save_png("res://builds/workstation_after.png")
	quit(0 if error == OK else 1)
