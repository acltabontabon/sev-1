extends "res://tests/incident_preview.gd"
## Forward+ guidance captures; --play leaves a retry at the investigation checkpoint.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	await create_timer(1).timeout
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	preview_prefix = "scene_flow"
	DirAccess.make_dir_recursive_absolute("res://builds")
	if "--play" not in OS.get_cmdline_user_args():
		player.camera_rig.set_process_unhandled_input(false)
		await create_timer(2.4).timeout
		await shot("outbreak")
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	player.position = Vector3(22, .05, 11)
	player.camera_rig.rotation.y = 0
	if "--play" in OS.get_cmdline_user_args():
		return
	player.camera_rig.set_process_unhandled_input(false)
	await shot("investigation")
	player.position = Vector3(17.7, .05, -8.75)
	player.camera_rig.rotation.y = -PI / 2
	await shot("optional")
	incident._enter(incident.Stage.ENCOUNTER_TWO)
	incident._cleanup()
	incident._enter(incident.Stage.BOSS)
	player.position = Vector3(9, .05, -10)
	player.camera_rig.rotation.y = 0
	await shot("corridor")
	player.position = Vector3(9, .05, -23)
	await shot("vault")
	quit()
