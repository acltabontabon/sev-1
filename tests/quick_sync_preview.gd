extends "res://tests/incident_preview.gd"
## Render the expanded optional meeting and its floor challenge for visual review.


func shot(name_: String) -> void:
	for index in range(30):
		await process_frame
	scene.get_node("HUD/CapturePrompt").hide()
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://builds/quick_sync_" + name_ + ".png")


func _run() -> void:
	preview_prefix = "quick_sync"
	DirAccess.make_dir_recursive_absolute("res://builds")
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	await create_timer(1.0).timeout
	incident.presentation.skip()
	player.camera_rig.capture_changed.disconnect(scene._on_capture_changed)
	player.camera_rig.controls_active = true
	scene.get_node("HUD/CapturePrompt").hide()
	paused = false
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	player.camera_rig.set_process_unhandled_input(false)
	player.position = Vector3(17, .05, -8)
	if "--play" in OS.get_cmdline_user_args():
		player.camera_rig.capture_changed.connect(scene._on_capture_changed)
		player.camera_rig.rotation.y = -PI / 2.0
		player.camera_rig.set_process_unhandled_input(true)
		player.camera_rig.set_capture(true)
		return
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(19.3, 3.0, -4.2)
	camera.look_at(Vector3(26, 1.0, -10))
	camera.current = true
	await shot("open_floor")
	player.position = Vector3(24.5, .05, -8)
	incident._start_quick_sync()
	await create_timer(1.0).timeout
	await shot("standup")
	for index in range(1, 5):
		incident.standup_scene._next()
		await shot("standup_%d" % index)
	incident.standup_scene.finish()
	await create_timer(3.2).timeout
	incident.presentation.skip()
	incident.end_outbreak()
	for foe: CharacterBody3D in incident.sync_alive:
		foe.reveal_grace_left = 0
		foe.set_physics_process(false)
	incident.sync_action_left = 0
	incident._tick_quick_sync(.1)
	camera.current = true
	await shot("warning")
	await create_timer(2.0).timeout
	await shot("action_item")
	for foe: CharacterBody3D in incident.sync_alive.duplicate():
		foe.receive_damage(100000, player.position)
	incident.presentation.skip()
	camera.current = true
	await shot("minutes")
	scene.queue_free()
	paused = false
	await process_frame
	quit()
