extends "res://tests/incident_preview.gd"

func shot(name_: String) -> void:
	for index in range(30):
		if not incident.terminal():
			player.camera_rig.controls_active = true
		await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://builds/" + preview_prefix + "_" + name_ + ".png")

func _run() -> void:
	preview_prefix = "narrative"
	DirAccess.make_dir_recursive_absolute("res://builds")
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	player.camera_rig.set_process_unhandled_input(false)
	player.camera_rig.capture_changed.disconnect(scene._on_capture_changed)
	player.camera_rig.controls_active = true
	paused = false
	await create_timer(2).timeout
	await shot("workstation")
	incident.stage_time = 6
	await shot("relief")
	incident.stage_time = 10
	await shot("alert")
	incident.stage_time = 15
	await shot("eta")
	incident.stage_time = 20
	await shot("reaction")
	incident.presentation.skip()
	await create_timer(2.5).timeout
	await shot("first_record")
	incident._cleanup()
	for next in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	player.position = Vector3(0, .05, 5)
	player.camera_rig.reset_view()
	await create_timer(4).timeout
	await shot("boss_title")
	incident.presentation.skip()
	await shot("boss_live")
	incident.active_enemy.exposed = true
	incident.active_enemy.receive_damage(10000, player.position)
	await shot("victory")
	scene.reset_encounter()
	incident.fail()
	await shot("defeat")
	scene.queue_free()
	paused = false
	await create_timer(.25).timeout
	quit()
