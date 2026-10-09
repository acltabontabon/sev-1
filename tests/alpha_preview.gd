extends SceneTree
## Real-renderer smoke/measurement run. Never use --fixed-fps for measurements.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Enemy")
	player.camera_rig.capture_changed.disconnect(scene._on_capture_changed)
	player.max_health = 100000
	enemy.max_health = 100000
	scene.reset_encounter()
	player.camera_rig.controls_active = true
	paused = false
	player.position = Vector3(0, 0.05, 5)
	enemy.position = Vector3(0, 0.05, 3.4)
	DirAccess.make_dir_recursive_absolute("res://builds")
	var samples: Array[float] = []
	var start: int = Time.get_ticks_usec()
	var previous: int = start
	while "--capture-only" not in OS.get_cmdline_user_args() and Time.get_ticks_usec() - start < 25000000:
		await process_frame
		var now: int = Time.get_ticks_usec()
		if now - start > 5000000:
			samples.append(float(now - previous) / 1000.0)
		previous = now
		player.camera_rig.controls_active = true
		if not player.melee.attacking or player.melee.remaining_time() < 0.18:
			player.request_attack()
	if not samples.is_empty():
		var total: float = 0
		for sample in samples:
			total += sample
		samples.sort()
		var report: Dictionary = {
			"resolution": str(root.size), "samples": samples.size(),
			"mean_fps": 1000.0 / (total / samples.size()),
			"median_ms": samples[samples.size() / 2],
			"p95_ms": samples[int(samples.size() * 0.95)],
			"max_ms": samples.back(), "renderer": "Forward+ / Metal",
			"scenario": "25s repeated close-range combo and active enemy; first 5s excluded; elevated health"
		}
		print(JSON.stringify(report))
		var output: FileAccess = FileAccess.open("res://builds/alpha_performance.json", FileAccess.WRITE)
		output.store_string(JSON.stringify(report, "\t"))
	# Capture separately so GPU readback and PNG encoding never enter frame samples.
	player.max_health = 100
	enemy.max_health = 180
	scene.reset_encounter()
	player.position = Vector3(0, 0.05, 5)
	enemy.position = Vector3(0, 0.05, 3.4)
	enemy.target = null
	player.camera_rig.controls_active = true
	for index in range(10):
		await physics_frame
		await process_frame
	player.request_attack()
	for index in range(9):
		await physics_frame
		await process_frame
	paused = true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/alpha_preview.png")
	player.melee.cancel()
	paused = false
	player.hitstop_left = 0
	player.request_dodge()
	for index in range(5):
		await physics_frame
		await process_frame
	paused = true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/alpha_dodge.png")
	player.melee.cancel()
	enemy.melee.cancel()
	player.get_node("HitSound").stop()
	player.get_node("HurtSound").stop()
	paused = false
	scene.queue_free()
	await create_timer(0.25).timeout
	quit()
