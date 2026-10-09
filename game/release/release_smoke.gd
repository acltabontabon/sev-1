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
	await frames(10)
	check(app.page == "main", "packaged main scene reaches title")
	capture("title")
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
	var result: FileAccess = FileAccess.open("user://release_smoke.json", FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures": failures, "version": ProjectSettings.get_setting("application/config/version"), "graphical": DisplayServer.get_name() != "headless"}))
	result.close()
	print("RESULT: ", failures, " failure(s)")
	app.quit_game() if failures == 0 else get_tree().quit(1)
