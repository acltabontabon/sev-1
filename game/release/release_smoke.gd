extends Node
## Opt-in packaged smoke probe. Runs only with -- --release-smoke.
## Elevated health and staged positions test reliability, never game balance.
var failures: int = 0
var app: Node
func _ready() -> void:
	_run.call_deferred()
func frames(count: int) -> void:
	for index in range(count):
		await get_tree().physics_frame
		await get_tree().process_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)
func key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		get_tree().root.push_input(event, true)
		await frames(2)
func capture(title: String) -> void:
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_png("user://package_" + title + ".png")


func _run() -> void:
	check(not ResourceLoader.exists("res://tests/release_tests.gd"), "development tests excluded from package")
	app = get_parent()
	check(app.progress.path != "user://chapter_progress.json", "packaged smoke isolates chapter saves from player progress")
	if app.progress.path == "user://chapter_progress.json":
		get_tree().quit(1)
		return
	DirAccess.remove_absolute(app.progress.path)
	app.progress.load_progress()
	app.show_page("main")
	await frames(10)
	check(app.page == "main", "packaged main scene reaches title")
	capture("title")
	app.show_page("tester_unlock")
	capture("tester_unlock")
	var unlock: Button
	for button: Node in app.box.find_children("*", "Button", true, false):
		if button.text == "Unlock Stage One Completion":
			unlock = button
	check(unlock != null, "packaged earlier tester unlock is available")
	if unlock != null:
		unlock.pressed.emit()
		await frames(3)
		check(app.progress.stage_one_completed and app.page == "main", "packaged earlier tester unlock saves completion and returns to title")
	if "--menus-only" in OS.get_cmdline_user_args():
		capture("saved_title")
		var replay_button: Button
		for button: Node in app.box.find_children("*", "Button", true, false):
			if button.text == "Replay Stage One":
				replay_button = button
		check(replay_button != null, "packaged completed title offers Replay Stage One")
		if replay_button != null:
			replay_button.pressed.emit()
			await frames(3)
			check(app.session != null and app.session.get_node("Incident").stage == app.session.get_node("Incident").Stage.ALERT and app.progress.stage_one_completed, "packaged menu replay starts Stage One and keeps completion")
			app.main_menu()
			await frames(3)
		var menu_save: RefCounted = load("res://game/release/chapter_progress.gd").new()
		menu_save.path = app.progress.path
		menu_save.load_progress()
		check(menu_save.stage_one_completed, "packaged menu replay keeps completion on disk")
		DirAccess.remove_absolute(app.progress.path)
		_finish_probe()
		return
	# Clear only this disposable fixture so victory tests a fresh completion write.
	DirAccess.remove_absolute(app.progress.path)
	app.progress.load_progress()
	app.show_page("main")
	app.start_incident()
	var scene: Node = app.session
	var player: CharacterBody3D = scene.get_node("Player")
	var incident: Node = scene.get_node("Incident")
	for entry: Dictionary in incident.voice.lines.values():
		if entry.status != "missing":
			check(ResourceLoader.exists(entry.audio) and load(entry.audio) is AudioStream, "packaged voice resolves: " + entry.id)
	player.max_health = 10000
	player.health = 10000
	await frames(30)
	if app.page == "pause":
		app.resume_incident()
		await frames(3)
	capture("opening")
	incident.presentation.skip_unlocked = true
	await key(KEY_TAB)
	var captured_boss: bool = false
	var captured_combat: bool = false
	var started: int = Time.get_ticks_msec()
	for tick in range(14400):
		if incident.terminal():
			break
		if app.page == "pause":
			app.resume_incident()
		if incident.upgrade_pending:
			await key(KEY_1)
		elif incident.decision_pending:
			await key(KEY_2)
		elif incident.stage == incident.Stage.INVESTIGATION:
			player.position = incident.CONSOLE_POSITION
			await key(KEY_E)
			await key(KEY_3)
			await key(KEY_TAB)
		elif incident.stage == incident.Stage.BOSS and not incident.boss_triggered:
			player.position = Vector3(9, .05, -31.5)
			await frames(3)
		elif is_instance_valid(incident.active_enemy):
			var foe: CharacterBody3D = incident.active_enemy
			if not captured_combat:
				capture("combat")
				captured_combat = true
			if incident.stage == incident.Stage.BOSS and not captured_boss and not incident.copies.is_empty():
				capture("boss")
				captured_boss = true
			if not player.melee.attacking and not player.dodging:
				player.position = Vector3(0, .05, 5)
				foe.position = Vector3(0, .05, 3.4)
				player.camera_rig.reset_view()
			if not player.melee.attacking or player.melee.remaining_time() < .18:
				await key(KEY_F)
		await frames(1)
	await frames(3)
	check(incident.stage == incident.Stage.RESOLVED and app.page == "report", "packaged real-melee run reaches victory and report")
	var saved: RefCounted = load("res://game/release/chapter_progress.gd").new()
	saved.path = app.progress.path
	saved.load_progress()
	check(saved.stage_one_completed, "packaged victory persists Stage One completion")
	check(incident.run.choices.size() == 2 and incident.corporate_choice == 1 and incident.enemies_defeated == 11, "packaged run traverses two upgrades, management, and every authored wave")
	print("SIMULATED RUN WALL MS: ", Time.get_ticks_msec() - started)
	for button: Node in app.box.find_children("*", "Button", true, false):
		check(get_viewport().get_visible_rect().encloses(button.get_global_rect()), "postmortem action fits viewport: " + button.text)
	capture("victory")
	app.restart_incident()
	await frames(3)
	check(incident.run.debt == 0 and incident.run.burnout == 0 and not get_tree().paused, "packaged restart clears pressure and resumes")
	player.receive_damage(100000, Vector3.ZERO)
	await frames(3)
	check(app.page == "report" and incident.stage == incident.Stage.FAILED, "packaged damage/death reaches defeat report")
	app.main_menu()
	await frames(3)
	check(app.session == null and get_tree().get_nodes_in_group("players").is_empty(), "packaged return to title frees incident")
	var replay: Button
	var menu_text: String = ""
	for button: Node in app.box.find_children("*", "Button", true, false):
		if button.text == "Replay Stage One":
			replay = button
	for label: Node in app.box.find_children("*", "Label", true, false):
		menu_text += label.text + "\n"
	check(replay != null and "Progress saved. Stage Two coming soon." in menu_text, "packaged title offers replay and the saved-progress message")
	capture("saved_title")
	if replay != null:
		replay.pressed.emit()
		await frames(3)
		check(app.session != null and app.session.get_node("Incident").stage == app.session.get_node("Incident").Stage.ALERT and app.progress.stage_one_completed, "packaged Replay Stage One keeps completion and starts a fresh incident")
		app.main_menu()
		await frames(3)
	saved.load_progress()
	check(saved.stage_one_completed, "packaged replay preserves completion on disk")
	DirAccess.remove_absolute(app.progress.path)
	_finish_probe()


func _finish_probe() -> void:
	var result: FileAccess = FileAccess.open("user://release_smoke.json", FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures": failures, "version": ProjectSettings.get_setting("application/config/version"), "graphical": DisplayServer.get_name() != "headless"}))
	result.close()
	print("RESULT: ", failures, " failure(s)")
	app.quit_game() if failures == 0 else get_tree().quit(1)
