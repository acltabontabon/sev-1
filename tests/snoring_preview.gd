extends "res://tests/incident_preview.gd"
## Graphical/audio checkpoint beside GARY. --listen leaves time to hear both breaths.


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
	player.set_physics_process(false)
	player.narrative_hold = false
	paused = false
	player.camera_rig.set_capture(true)
	player.camera_rig.set_process_unhandled_input(false)
	var sleeper: Node3D = incident.coworkers.person("Sleeper").body
	player.global_position = sleeper.global_position + Vector3(1.5, .05, 1.5)
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.global_position = sleeper.global_position + Vector3(3, 2.8, 3)
	camera.look_at(sleeper.global_position + Vector3.UP, Vector3.UP)
	camera.make_current()
	preview_prefix = "snoring"
	await create_timer(4.6).timeout # Let the one-time coworker remark clear; catch the next inhale.
	await shot("gary")
	if "--listen" in OS.get_cmdline_user_args():
		await create_timer(17.0).timeout
	scene.queue_free()
	await process_frame
	quit()
