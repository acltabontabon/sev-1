extends SceneTree
## The overtime crew's haircuts where they actually work: each coworker framed head and
## shoulders in the office's own lighting, stitched into builds/hair_office.png.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var scene: Node3D = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var incident: Node3D = scene.get_node("Incident")
	incident.presentation.skip()
	incident._cleanup()
	incident.set_process(false)
	incident.presentation.set_process(false)
	incident.presentation.feed.hide()
	scene.get_node("HUD").hide()
	var player: CharacterBody3D = scene.get_node("Player")
	player.set_physics_process(false)
	player.position = Vector3(30, .05, 30)
	var crew: Node3D = incident.coworkers
	crew.set_process(false)
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.fov = 32
	camera.current = true
	DirAccess.make_dir_recursive_absolute("res://builds")
	var shots: Array[Image] = []
	for person: Dictionary in crew.people:
		for label in person.body.find_children("*", "Label3D", true, false):
			(label as Label3D).hide()
		var skeleton: Skeleton3D = person.body.find_child("Skeleton3D", true, false)
		await process_frame
		var head: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin
		var facing: Vector3 = person.body.global_basis.z.normalized()
		var size: float = person.body.global_basis.get_scale().x
		var eye: Vector3 = head + Vector3.UP * .45 * size
		camera.position = eye + (facing.rotated(Vector3.UP, .55) * 2.6 + Vector3.UP * .5) * size
		camera.look_at(eye)
		for index in range(6):
			await process_frame
		await RenderingServer.frame_post_draw
		var shot: Image = root.get_texture().get_image()
		shot.convert(Image.FORMAT_RGBA8)
		shot.resize(400, 225)
		shots.append(shot)
	var sheet: Image = Image.create(1600, 225 * ceili(shots.size() / 4.0), false, Image.FORMAT_RGBA8)
	for index in shots.size():
		sheet.blit_rect(shots[index], Rect2i(0, 0, 400, 225), Vector2i(400 * (index % 4), 225 * (index / 4)))
	assert(sheet.save_png("res://builds/hair_office.png") == OK)
	scene.queue_free()
	await process_frame
	quit()
