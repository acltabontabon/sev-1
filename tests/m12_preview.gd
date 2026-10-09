extends SceneTree
## Milestone 12 graphical probe: menu, opening shots. Captures for human visual review;
## it does not establish fun, comedy or audio quality.
## sh tools/godot.sh --path . --script tests/m12_preview.gd -- [--1080] [--only=menu]
var app: Node
var prefix: String = "m12_720"
var only: String = ""
var samples: Array[float] = []
var last: int = 0


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int = 10) -> void:
	for index in range(count):
		await process_frame


func sample() -> void:
	var now: int = Time.get_ticks_usec()
	if last > 0:
		samples.append((now - last) / 1000.0)
	last = now


func report(label: String) -> void:
	samples.sort()
	if samples.is_empty():
		return
	var total: float = 0.0
	for value in samples:
		total += value
	print("PERF %s: frames %d avg %.2f ms (%.1f fps) p95 %.2f ms max %.2f ms draw calls %d" % [label, samples.size(), total / samples.size(), 1000.0 * samples.size() / total, samples[int(samples.size() * .95)], samples[-1], RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	samples.clear()
	last = 0


func shot(title: String) -> void:
	await frames(2)
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://builds/" + prefix + "_" + title + ".png")
	print("CAPTURE ", title)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds")
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--1080":
			root.size = Vector2i(1920, 1080)
			prefix = "m12_1080"
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	DirAccess.remove_absolute("user://m12_preview_nonexistent.cfg")
	app = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = "user://m12_preview_nonexistent.cfg"
	root.add_child(app)
	current_scene = app
	await frames(30)
	await shot("menu")
	for index in range(150):
		await process_frame
		sample()
	report("menu")
	await shot("menu_notice")
	if only == "menu":
		quit()
		return
	app.start_incident()
	var story: CanvasLayer = app.session.get_node("Incident").presentation
	var incident: Node = app.session.get_node("Incident")
	var marks: Array = [[1.5, "op_wide"], [6.2, "op_monitor"], [9.8, "op_relax"], [12.6, "op_logoff"], [14.4, "op_alarm"], [17.8, "op_face"], [19.8, "op_eta"], [25.0, "op_tangina"], [27.3, "op_flicker"], [29.6, "op_emerge"], [31.6, "op_armed"], [33.8, "op_title"], [37.0, "op_handover"]]
	for mark: Array in marks:
		while incident.stage == incident.Stage.ALERT and incident.stage_time < mark[0]:
			app.session.get_node("Player/CameraRig").controls_active = true
			await process_frame
			sample()
		await shot(mark[1])
		last = 0
	report("opening")
	app.main_menu()
	await frames(5)
	app.queue_free()
	await frames(3)
	quit()
