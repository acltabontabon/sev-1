extends "res://tests/incident_preview.gd"
## Direct playable checkpoint; --capture renders actual rollback, then a personal talk.


func _run() -> void:
	preview_prefix = "heart"
	DirAccess.make_dir_recursive_absolute("res://builds")
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	await create_timer(1).timeout
	player.camera_rig.set_capture(true)
	incident.presentation.skip_unlocked = true
	incident.presentation.skip()
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 5)
	player.camera_rig.rotation.y = 0
	player.health = player.max_health
	player.specials.add_focus(100)
	# Separate from authored wave accounting: killing a practice target cannot
	# complete containment or produce an out-of-order upgrade.
	var practice: Array[CharacterBody3D] = []
	var foe: CharacterBody3D = incident._spawn_entry(["record", "A1"], practice)
	foe.died.connect(func() -> void: incident.corpses[foe] = 3.0)
	foe.position = Vector3(0, .05, 2.5)
	foe.max_health = 2000
	foe.health = 2000
	if "--capture" not in OS.get_cmdline_user_args():
		return
	foe.set_physics_process(false)
	player.camera_rig.set_process_unhandled_input(false)
	await create_timer(1).timeout
	player.specials.rollback()
	await create_timer(5.5).timeout
	await shot("survey")
	await create_timer(7).timeout
	await shot("approved")
	incident.rollback_survey.reset()
	incident._cleanup()
	var person: Dictionary = incident.coworkers.person("Intern")
	player.position = person.body.position + Vector3(1, .05, 1)
	incident.talk({"body": person.body, "tree": incident.DIALOGUES.tree("Intern"), "name": "Intern", "standing": true, "animator": person.animator})
	incident.dialogue._go("good_days")
	await create_timer(2).timeout
	incident.dialogue.advance()
	await shot("off_the_clock")
	incident.dialogue.close()
	scene.queue_free()
	paused = false
	await process_frame
	quit()
