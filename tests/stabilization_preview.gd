extends "res://tests/incident_preview.gd"
## Graphical transition probe. Controlled damage stages transitions; not normal play.
var samples: Array[float] = []
var spikes: Array[Dictionary] = []
var operations: Array[Dictionary] = []
var phase: String = "scene_load"
var previous: int = 0
var recording: bool = false
var max_process_ms: float = 0
var max_physics_ms: float = 0
var peak_static_mib: float = 0
var peak_video_mib: float = 0
var peak_draw_calls: float = 0


func sample() -> void:
	var now: int = Time.get_ticks_usec()
	if recording and previous > 0:
		var frame_ms: float = float(now - previous) / 1000
		samples.append(frame_ms)
		if frame_ms > 16.667:
			spikes.append({"phase": phase, "frame_ms": frame_ms})
		max_process_ms = maxf(max_process_ms, Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
		max_physics_ms = maxf(max_physics_ms, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000)
		peak_static_mib = maxf(peak_static_mib, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576)
		peak_video_mib = maxf(peak_video_mib, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576)
		peak_draw_calls = maxf(peak_draw_calls, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	previous = now


func dwell(label_: String, count: int = 60) -> void:
	phase = label_
	for index in range(count):
		await process_frame


func spawn_measured(label_: String) -> void:
	phase = label_
	var start: int = Time.get_ticks_usec()
	incident._spawn()
	operations.append({"phase": phase, "cpu_ms": float(Time.get_ticks_usec() - start) / 1000})
	await dwell(label_)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds")
	process_frame.connect(sample)
	previous = Time.get_ticks_usec()
	recording = true
	var start: int = Time.get_ticks_usec()
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	operations.append({"phase": "scene_load", "cpu_ms": float(Time.get_ticks_usec() - start) / 1000})
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	player.camera_rig.set_process_unhandled_input(false)
	# Harness owns arrivals so every first-render cost has an explicit phase label.
	incident.set_process(false)
	await dwell("scene_first_render")
	for path in range(3):
		player.max_health = 10000
		player.health = 10000
		player.camera_rig.set_capture(true)
		incident._enter(incident.Stage.ENCOUNTER_ONE)
		for record in range(incident.first_records):
			await spawn_measured("run%d_first_spawn%d" % [path, record])
			incident.active_enemy.receive_damage(10000, player.position)
			await dwell("run%d_record_defeat%d" % [path, record])
		await dwell("run%d_upgrade_one" % path)
		incident.choose_upgrade(path)
		player.position = incident.CONSOLE_POSITION
		incident.inspect_console()
		incident.choose_system(3)
		await dwell("run%d_management" % path)
		incident.choose_corporate(path)
		var count: int = incident.remaining
		for record in range(count):
			await spawn_measured("run%d_containment_spawn%d" % [path, record])
			incident.active_enemy.receive_damage(10000, player.position)
			await dwell("run%d_containment_defeat%d" % [path, record])
		incident.choose_upgrade(path)
		await spawn_measured("run%d_boss_spawn" % path)
		var boss: CharacterBody3D = incident.active_enemy
		player.position = Vector3(0, .05, 5)
		boss.position = Vector3(0, .05, 3.4)
		boss.exposed = true
		boss.phase_time = 5
		phase = "run%d_clone_creation" % path
		start = Time.get_ticks_usec()
		boss.receive_damage(360, player.position)
		operations.append({"phase": phase, "cpu_ms": float(Time.get_ticks_usec() - start) / 1000})
		await dwell(phase)
		# Include combat/audio/effect work with real input timing, elevated health.
		for index in range(240):
			phase = "run%d_boss_combat" % path
			if not player.melee.attacking or player.melee.remaining_time() < .18:
				player.request_attack()
			await process_frame
		boss.exposed = true
		boss.receive_damage(10000, player.position)
		await dwell("run%d_victory" % path)
		phase = "run%d_restart" % path
		start = Time.get_ticks_usec()
		scene.reset_encounter()
		operations.append({"phase": phase, "cpu_ms": float(Time.get_ticks_usec() - start) / 1000})
		await dwell(phase)
		incident.fail()
		await dwell("run%d_failure" % path)
		scene.reset_encounter()
		await dwell("run%d_failure_restart" % path)
	recording = false
	var sorted: Array[float] = samples.duplicate()
	sorted.sort()
	var total: float = 0
	for value in samples:
		total += value
	var result: Dictionary = {
		"resolution": str(root.size), "renderer": "Forward+ / Metal, MSAA 2x, SSAO, glow, fog",
		"scenario": "Three staged lifecycle runs, one per corporate/upgrade path; controlled deaths, real boss combat, elevated player health; includes cold first render and UI pauses; no screenshots during samples",
		"samples": samples.size(), "mean_fps": 1000.0 * samples.size() / total,
		"median_ms": sorted[sorted.size() / 2], "p95_ms": sorted[int(sorted.size() * .95)], "p99_ms": sorted[int(sorted.size() * .99)], "max_ms": sorted.back(),
		"frames_over_16_667ms": spikes.size(), "max_process_ms": max_process_ms,
		"max_physics_ms": max_physics_ms, "peak_static_memory_mib": peak_static_mib,
		"peak_video_memory_mib": peak_video_mib, "peak_draw_calls": peak_draw_calls,
		"transition_cpu_times": operations, "slow_frames": spikes}
	var output: FileAccess = FileAccess.open("res://builds/stabilization_performance.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t"))
	print(JSON.stringify(result))
	scene.queue_free()
	paused = false
	await create_timer(.25).timeout
	quit()
