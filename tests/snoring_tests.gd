extends "res://tests/incident_tests.gd"
## Proximity outcomes on the actual sleeper, independent of camera position.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	incident.presentation.skip()
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	await frames(3)
	player.set_physics_process(false)
	player.narrative_hold = false
	paused = false
	var crew: Node3D = incident.coworkers
	var sleeper: Node3D = crew.person("Sleeper").body
	var snore: AudioStreamPlayer3D = sleeper.get_node("Snoring")
	check(crew.find_children("Snoring", "AudioStreamPlayer3D", true, false).size() == 1, "only sleeping GARY snores")
	player.global_position = sleeper.global_position + Vector3(1, 0, 0)
	await frames(3)
	check(snore.playing and snore.volume_db > -20 and snore.volume_db <= -16, "approaching the sleeper starts a soft breath loop")
	var near_volume: float = snore.volume_db
	player.global_position = sleeper.global_position + Vector3(3, 0, 0)
	await frames(3)
	check(snore.playing and snore.volume_db < near_volume - 3, "snoring gets quieter across the nearby desks")
	player.global_position = sleeper.global_position + Vector3(6, 0, 0)
	await frames(3)
	check(not snore.playing and snore.volume_db <= -80, "walking beyond five metres silences snoring")
	check(not snore.sleep_hint.visible, "distant desks do not show GARY's sleep hint")
	player.global_position = sleeper.global_position + Vector3(1, 0, 0)
	await frames(3)
	check(snore.playing, "returning to the sleeper restores the loop")
	player.camera_rig.spring_arm.spring_length = 7.0
	player.camera_rig.rotation.y = PI
	await frames(3)
	check(is_equal_approx(snore.volume_db, near_volume), "orbiting or zooming the camera cannot change hero proximity gain")
	sleeper.hide()
	await frames(3)
	check(not snore.playing, "hidden sleeper is silent")
	check(not snore.sleep_hint.visible, "hidden sleeper has no floating hint")
	sleeper.show()
	player.narrative_hold = true
	await frames(3)
	check(not snore.playing, "story and dialogue holds silence ambient snoring")
	player.narrative_hold = false
	await frames(3)
	check(snore.playing, "leaving a story hold restores nearby snoring")
	player.health = 0
	await frames(3)
	check(not snore.playing, "dead engineer does not hear snoring")
	player.health = 100
	crew.reset()
	await frames(3)
	check(snore.playing and sleeper.find_children("Snoring", "AudioStreamPlayer3D", true, false).size() == 1, "retry keeps exactly one nearby snore source")
	var breath: AudioStreamWAV = snore.stream as AudioStreamWAV
	check(breath.loop_mode == AudioStreamWAV.LOOP_FORWARD and breath.loop_end > 0 and breath.get_length() >= 7.9, "both breaths loop without a finished-signal gap")
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
