extends "res://tests/incident_preview.gd"
## Deterministic graphical checkpoint; does not establish aid balance.


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds")
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	await create_timer(1.0).timeout
	incident.presentation.skip()
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	player.camera_rig.set_capture(true)
	player.camera_rig.set_process_unhandled_input(false)
	player.set_physics_process(false)
	player.narrative_hold = false
	paused = false
	player.position = Vector3(0, .05, 5)
	var crew: Node3D = incident.coworkers
	crew.set_process(false)
	var helper: Dictionary = crew.person("Intern")
	helper.body.position = player.position + Vector3(2, 0, 0)
	player.health = 20
	crew.aid_chance = 1.0
	await physics_frame
	crew._emergency_aid(2.0, true)
	crew._process(.01)
	for index in range(8):
		await process_frame
	RenderingServer.force_draw()
	var error: Error = root.get_texture().get_image().save_png("res://builds/coworker_aid.png")
	if error != OK:
		push_error(error_string(error))
	scene.queue_free()
	await process_frame
	quit()
