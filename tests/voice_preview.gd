extends SceneTree
## Graphical playback/layout probe; does not establish human listening quality.
var app: Node
var failures: int = 0
var prefix: String = "voice_720"
func _initialize() -> void:
	_run.call_deferred()
func frames(count: int = 10) -> void:
	for index in range(count):
		if app.session != null and app.page.is_empty():
			app.session.get_node("Player/CameraRig").controls_active = true
		await process_frame
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
func shot(title: String) -> void:
	await frames(3)
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://builds/" + prefix + "_" + title + ".png")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds")
	if "--1080" in OS.get_cmdline_user_args():
		root.size = Vector2i(1920, 1080)
		prefix = "voice_1080"
	app = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = "user://voice_preview_nonexistent.cfg"
	root.add_child(app)
	current_scene = app
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var voice: Node = incident.voice
	var camera: Node = app.session.get_node("Player/CameraRig")
	camera.set_process_unhandled_input(false)
	await frames(5)
	app.resume_incident()
	await frames(5)
	check(voice.using_audio and voice.flat.playing, "graphical opening uses real speech stream")
	await shot("opening")
	app.pause_incident()
	await frames(5)
	check(voice.flat.stream_paused, "real audio pauses on application pause")
	app.resume_incident()
	await frames(5)
	check(not voice.flat.stream_paused, "real audio resumes with incident")
	# Isolate natural audio completion from the authored opening clock.
	incident.presentation.set_process(false)
	voice.clear(true)
	voice.request("eta")
	await frames(5)
	var deadline: int = Time.get_ticks_msec() + 10000
	while not voice.current_line.is_empty() and Time.get_ticks_msec() < deadline:
		await frames(1)
	check(voice.current_line.is_empty(), "real finished signal clears subtitle and releases speech slot")
	incident.presentation.set_process(true)
	incident.presentation.skip()
	incident._offer_upgrade(incident.Stage.INVESTIGATION)
	await shot("choice")
	check(not incident.presentation.panel.visible and voice.suspended, "modal hides captions and suspends audio")
	incident.fail()
	await frames(8)
	await shot("report")
	check(voice.flat.playing and not voice.flat.stream_paused and not app.report_subtitle.text.is_empty(), "terminal audio and report subtitle run over paused game")
	for button: Node in app.box.find_children("*", "Button", true, false):
		check(root.get_visible_rect().encloses(button.get_global_rect()), "report action fits viewport: " + button.text)
	app.open_settings()
	await shot("settings")
	app.main_menu()
	await frames(3)
	app.queue_free()
	paused = false
	await process_frame
	print("RESULT: ", failures, " failure(s); playback observed, human listening pending")
	quit(0 if failures == 0 else 1)
