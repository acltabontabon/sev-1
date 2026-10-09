extends SceneTree
## Staged rendering evidence, not a human pacing or combat-feel test.

var scene: Node3D
var player: CharacterBody3D
var incident: Node3D


func _initialize() -> void:
	_run.call_deferred()


func shot(name_: String) -> void:
	for index in range(30):
		await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png("res://builds/incident_" + name_ + ".png")
	if error != OK:
		push_error(error_string(error))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds")
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	# Keep native mouse movement from changing a reproducible capture/benchmark.
	player.camera_rig.set_process_unhandled_input(false)
	await shot("intro")
	player.camera_rig.capture_changed.disconnect(scene._on_capture_changed)
	player.camera_rig.controls_active = true
	incident._enter(incident.Stage.ENCOUNTER_ONE)
	incident._enter(incident.Stage.INVESTIGATION)
	player.position = Vector3(-1.7, .05, -11)
	incident.inspect_console()
	await shot("investigation")
	incident.choose_system(3)
	incident._enter(incident.Stage.BOSS)
	incident._spawn()
	var boss: CharacterBody3D = incident.active_enemy
	boss.position = Vector3(0, .05, 0)
	player.position = Vector3(0, .05, 5)
	boss.phase_time = 5
	boss.exposed = true
	boss.receive_damage(360, player.position)
	boss.marker.text = "◆  VERIFIED ORIGINAL\nOPEN — STRIKE NOW"
	await shot("boss")
	if "--measure" in OS.get_cmdline_user_args():
		player.max_health = 100000
		player.health = 100000
		boss.health = 100000
		boss.max_health = 100000
		paused = false
		var samples: Array[float] = []
		var start: int = Time.get_ticks_usec()
		var previous: int = start
		while Time.get_ticks_usec() - start < 25000000:
			await process_frame
			var now: int = Time.get_ticks_usec()
			if now - start > 5000000:
				samples.append(float(now - previous) / 1000)
			previous = now
			player.camera_rig.controls_active = true
			if not player.melee.attacking or player.melee.remaining_time() < .18:
				player.request_attack()
		var total: float = 0
		for sample in samples:
			total += sample
		samples.sort()
		var report: Dictionary = {
			"resolution": str(root.size), "samples": samples.size(),
			"mean_fps": 1000.0 / (total / samples.size()),
			"median_ms": samples[samples.size() / 2],
			"p95_ms": samples[int(samples.size() * .95)], "max_ms": samples.back(),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"renderer": "Forward+ / Metal, MSAA 2x, SSAO, glow, fog",
			"scenario": "25s Variance with two projections, elevated health; 5s warmup excluded; screenshots excluded"
		}
		print(JSON.stringify(report))
		var output: FileAccess = FileAccess.open("res://builds/incident_performance.json", FileAccess.WRITE)
		output.store_string(JSON.stringify(report, "\t"))
	paused = true
	player.max_health = 100
	player.health = 100
	player.camera_rig.reset_view()
	player.position = Vector3(0, .05, 5)
	boss.position = Vector3(0, .05, 0)
	boss.exposed = true
	boss.receive_damage(1000000, player.position)
	await shot("resolved")
	scene.reset_encounter()
	incident.fail()
	await shot("failed")
	player.get_node("HitSound").stop()
	player.get_node("HurtSound").stop()
	scene.queue_free()
	paused = false
	await create_timer(.25).timeout
	quit()
