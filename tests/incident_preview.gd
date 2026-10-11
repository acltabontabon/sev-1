extends SceneTree
## Staged rendering evidence, not a human pacing or combat-feel test.

var scene: Node3D
var player: CharacterBody3D
var incident: Node3D
var preview_prefix: String = "incident"


func _initialize() -> void:
	_run.call_deferred()


func shot(name_: String) -> void:
	for index in range(30):
		await process_frame
	# A paused/background window may stop automatic draws; never wait indefinitely.
	RenderingServer.force_draw()
	var error: Error = root.get_texture().get_image().save_png("res://builds/" + preview_prefix + "_" + name_ + ".png")
	if error != OK:
		push_error(error_string(error))


func clear_operations() -> void:
	incident.presentation.skip()
	await process_frame


func _run() -> void:
	if "--debt" in OS.get_cmdline_user_args() or "--burnout" in OS.get_cmdline_user_args():
		preview_prefix = "burnout" if "--burnout" in OS.get_cmdline_user_args() else "debt"
	DirAccess.make_dir_recursive_absolute("res://builds")
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	if "--composed" in OS.get_cmdline_user_args():
		incident.run.hit_burnout = 0
	# Keep native mouse movement from changing a reproducible capture/benchmark.
	player.camera_rig.set_process_unhandled_input(false)
	await shot("intro")
	player.camera_rig.capture_changed.disconnect(scene._on_capture_changed)
	player.camera_rig.controls_active = true
	incident._enter(incident.Stage.ENCOUNTER_ONE)
	if preview_prefix in ["debt", "burnout"]:
		incident._offer_upgrade(incident.Stage.INVESTIGATION)
		await shot("selection")
		incident.choose_upgrade(0)
	else:
		incident._enter(incident.Stage.INVESTIGATION)
	player.position = Vector3(-1.7, .05, -11)
	incident.inspect_console()
	await shot("investigation")
	await clear_operations()
	await shot("management")
	incident.choose_corporate(0 if preview_prefix == "burnout" else 1)
	if preview_prefix == "burnout":
		incident.run.change_burnout(70, "Overload preview")
		incident.run.apply_to(player)
	await shot("containment")
	if preview_prefix in ["debt", "burnout"]:
		incident._complete_containment()
		incident._offer_upgrade(incident.Stage.BOSS)
		await shot("second_selection")
		incident.choose_upgrade(0)
		await shot("applied")
	else:
		incident._enter(incident.Stage.BOSS)
	if preview_prefix == "burnout":
		incident.run.change_burnout(100, "Overload preview")
		incident.run.apply_to(player)
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
			"burnout": incident.run.burnout, "debt": incident.run.debt, "resolution": str(root.size), "samples": samples.size(),
			"mean_fps": 1000.0 / (total / samples.size()),
			"median_ms": samples[samples.size() / 2],
			"p95_ms": samples[int(samples.size() * .95)], "max_ms": samples.back(),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"renderer": "Forward+ / Metal, MSAA 2x, SSAO, glow, fog",
			"scenario": "25s Variance with two projections, elevated health; 5s warmup excluded; screenshots excluded"
		}
		print(JSON.stringify(report))
		var output: FileAccess = FileAccess.open("res://builds/" + preview_prefix + "_performance.json", FileAccess.WRITE)
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
