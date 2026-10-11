extends SceneTree
## Graphical chair fit review: unoccupied desk, conference seating, seated engineer.


func _initialize() -> void:
	_capture.call_deferred()


func _shot(name_: String) -> void:
	for index in range(90):
		await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png("res://builds/chair_" + name_ + ".png")
	if error != OK:
		push_error("Chair screenshot failed: " + error_string(error))


func _capture() -> void:
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute("res://builds")
	var scene: Node3D = load("res://game/release/menu_backdrop.tscn").instantiate()
	root.add_child(scene)
	# Title uses exactly the existing seated engineer, typing pose and task light.
	await _shot("title_fit")
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.current = true
	camera.fov = 48.0
	var views: Array[Array] = [
		["desk_fit", Vector3(-6.5, 1.5, 8), Vector3(-9, .65, 5.8)],
		["engineer_side", Vector3(-.3, 1.45, 11.1), Vector3(-2.5, .95, 10.1)],
		["conference_fit", Vector3(5.8, 2.8, -4), Vector3(8, 2.2, -7)]
	]
	# Restore office's regular cool ceiling lights for the desk and conference views.
	for index in range(6):
		scene.get_node("OfficeAfterHours/CeilingPool%d" % index).light_energy = 3.2
	for view in views:
		camera.position = view[1]
		camera.look_at(view[2])
		await _shot(view[0])
	quit()
