extends SceneTree
## Rendered comparison of identical title animation at different frame budgets.
## sh tools/godot.sh --path . --resolution 1920x1080 --script tests/frame_budget_probe.gd
var app: Node
var results: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func sample(label: String, limit: int) -> void:
	Engine.max_fps = limit
	await create_timer(2.0, true, false, true).timeout
	print("SAMPLE ", label, " PID ", OS.get_process_id())
	var start: int = Time.get_ticks_usec()
	var count: int = 0
	while Time.get_ticks_usec() - start < 6000000:
		await process_frame
		count += 1
	var seconds: float = (Time.get_ticks_usec() - start) / 1000000.0
	results.append({"phase": label, "cap": limit, "fps": count / seconds})

func _run() -> void:
	app = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = "user://frame_budget_probe_nonexistent.cfg"
	root.add_child(app)
	current_scene = app
	# Keep the same animated desk and UI in every sample, isolating rendering cadence.
	app.set_process(false)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if not "--integration-only" in OS.get_cmdline_user_args():
		await sample("title_previous_120", 120)
		await sample("title_budget_30", app.frame_budget(true))
		await sample("background_budget_15", app.frame_budget(false))
	app.open_settings()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://builds/frame_budget_settings.png")
	print("FRAME BUDGET PROBE ", JSON.stringify({"resolution": str(root.size), "cpu": OS.get_processor_name(), "gpu": RenderingServer.get_video_adapter_name(), "results": results}))
	app.set_process(true)
	await process_frame
	await process_frame
	var expected: int = app.frame_budget(DisplayServer.window_is_focused())
	if Engine.max_fps != expected:
		push_error("Front end did not apply its rendering budget")
		quit(1)
		return
	print("APPLIED FRAME BUDGET ", Engine.max_fps)
	app.queue_free()
	paused = false
	await process_frame
	Engine.max_fps = 0
	quit()
