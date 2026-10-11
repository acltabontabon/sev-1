extends "res://tests/incident_preview.gd"
## Direct retry and real Forward+ captures of the management update call.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	await create_timer(1.0).timeout
	incident.presentation.skip()
	player.camera_rig.capture_changed.disconnect(scene._on_capture_changed)
	player.camera_rig.controls_active = true
	paused = false
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	player.position = Vector3(-1.7, .05, -11.5)
	player.camera_rig.rotation.y = 0
	scene.get_node("HUD/CapturePrompt").hide()
	if "--play" in OS.get_cmdline_user_args():
		player.camera_rig.capture_changed.connect(scene._on_capture_changed)
		player.camera_rig.set_capture(true)
		return
	player.camera_rig.set_process_unhandled_input(false)
	preview_prefix = "operations"
	DirAccess.make_dir_recursive_absolute("res://builds")
	incident.inspect_console()
	await create_timer(1.0).timeout
	await shot("briefing")
	await create_timer(6.3).timeout
	await shot("commitment")
	await create_timer(6.8).timeout
	await shot("decision")
	incident.choose_corporate(2)
	await create_timer(.5).timeout
	await shot("consequence")
	quit()
