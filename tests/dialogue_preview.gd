extends "res://tests/incident_preview.gd"


func _run() -> void:
	preview_prefix = "dialogue"
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	await create_timer(1.0).timeout
	incident.presentation.skip()
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	await create_timer(.5).timeout
	var host: Node3D = incident.sync_hosts[0]
	player.position = host.global_position + Vector3(1.4, .05, 0)
	await physics_frame
	incident.talk(incident.talk_target())
	await shot("standing")
	incident.dialogue.shown = 9999.0
	incident.dialogue.choose(0)
	await shot("reply")
	incident.dialogue.advance()
	incident.dialogue.advance()
	await shot("unhinged")
	incident.armed = false
	incident.dialogue.close()
	paused = false
	scene.queue_free()
	await process_frame
	quit()
