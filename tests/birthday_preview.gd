extends SceneTree
## Screenshots of the birthday pantry, its scene and the cake ambush into builds/, or add
## -- --play to start the investigation at the pantry door with ordinary controls.


func _initialize() -> void:
	_run.call_deferred()


func _wait(count: int) -> void:
	for index in range(count):
		await process_frame


func _capture(name: String) -> void:
	await _wait(3)
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://builds/birthday_" + name + ".png")
	print("CAPTURE birthday_", name)


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var scene: Node3D = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var incident: Node = scene.get_node("Incident")
	var player: CharacterBody3D = scene.get_node("Player")
	incident.presentation.skip()
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	if "--play" in OS.get_cmdline_user_args():
		player.position = Vector3(16.3, .05, 8.5)
		player.camera_rig.set_capture(true)
		paused = false
		return
	DirAccess.make_dir_recursive_absolute("res://builds")
	scene.get_node("HUD").hide()
	incident.presentation.feed.hide()
	player.position = Vector3(21.0, .05, 7.0)
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.fov = 68
	camera.make_current()
	paused = false
	await _wait(40)
	for shot: Array in [["room", Vector3(19.2, 3.1, 3.2), Vector3(26.0, 1.0, 12.5)],
			["table", Vector3(25.2, 1.9, 10.2), Vector3(26.5, 1.0, 13.6)],
			["cake", Vector3(26.5, 1.6, 12.4), Vector3(26.5, .86, 13.35)],
			["kitchen", Vector3(22.0, 2.4, 10.5), Vector3(30.0, 1.2, 6.5)],
			["door", Vector3(15.0, 1.9, 4.6), Vector3(18.4, 2.0, 9.5)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		await _capture(shot[0])
	# The scene itself, every line: the cutscene camera frames each speaker.
	incident.party_in_headless = true
	player.position = incident.room.get_node("SpawnPoints/PartyJoin").position
	incident.use("party")
	await _wait(30)
	scene.get_node("HUD").hide()
	for step in range(incident.party_scene.STEPS.size()):
		await _wait(20)
		if step == 5:
			incident.set_candles(false)
		await _capture("scene_%d" % step)
		if step < incident.party_scene.STEPS.size() - 1:
			incident.party_scene._next()
	incident.party_scene.finish()
	player.camera_rig.set_capture(true)
	scene.get_node("HUD").hide()
	await _wait(50)
	await _capture("outbreak")
	for wait in range(600):
		if incident.presentation.beat_shot.is_empty():
			break
		await process_frame
	await _wait(60)
	camera.position = Vector3(24.0, 2.6, 9.0)
	camera.look_at(Vector3(26.5, .8, 13.0))
	camera.make_current()
	await _capture("aftermath")
	print("PREVIEW done")
	quit()
