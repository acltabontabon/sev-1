extends SceneTree
## Real-renderer inspection; images are saved outside the measured frame interval.

func _initialize() -> void:
	_run.call_deferred()


func _shot(name_: String) -> void:
	for index in range(30):
		await process_frame
	current_scene.get_node("HUD/CapturePrompt").hide()
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png("res://builds/office_" + name_ + ".png")
	if error != OK:
		push_error("Screenshot failed: " + error_string(error))


func _run() -> void:
	var scene: Node3D = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Enemy")
	player.camera_rig.capture_changed.disconnect(scene._on_capture_changed)
	player.camera_rig.controls_active = true
	scene.get_node("HUD").refresh()
	DirAccess.make_dir_recursive_absolute("res://builds")
	await _shot("start")
	scene.get_node("HUD").hide()
	var camera: Camera3D = Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.fov = 65
	var views: Array[Array] = [
		["workstations", Vector3(-.5, 2.2, 13), Vector3(-5, 1.0, 7)],
		["arena", Vector3(4, 3.3, 9), Vector3(-1, 1.7, -10)],
		["conference", Vector3(2, 3.0, -2), Vector3(8, 2.9, -8)],
		["operations", Vector3(-1, 2.5, -8), Vector3(-3, 2.2, -15)]
	]
	for view in views:
		camera.position = view[1]
		camera.look_at(view[2])
		await _shot(view[0])
	camera.queue_free()
	player.get_node("CameraRig/SpringArm3D/Camera3D").current = true
	scene.get_node("HUD").show()
	if "--measure" in OS.get_cmdline_user_args():
		player.max_health = 100000
		enemy.max_health = 100000
		scene.reset_encounter()
		player.position = Vector3(0, .05, 5)
		enemy.position = Vector3(0, .05, 3.4)
		paused = false
		var samples: Array[float] = []
		var start: int = Time.get_ticks_usec()
		var previous: int = start
		while Time.get_ticks_usec() - start < 25000000:
			await process_frame
			var now: int = Time.get_ticks_usec()
			if now - start > 5000000:
				samples.append(float(now - previous) / 1000.0)
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
			"renderer": "Forward+ / Metal; MSAA 2x; SSAO; glow; fog",
			"scenario": "25s office combat, elevated health; first 5s excluded; screenshots outside measurement"
		}
		print(JSON.stringify(report))
		var output: FileAccess = FileAccess.open("res://builds/office_performance.json", FileAccess.WRITE)
		output.store_string(JSON.stringify(report, "\t"))
	player.melee.cancel()
	enemy.melee.cancel()
	player.get_node("HitSound").stop()
	player.get_node("HurtSound").stop()
	scene.queue_free()
	paused = false
	await create_timer(.25).timeout
	quit()
