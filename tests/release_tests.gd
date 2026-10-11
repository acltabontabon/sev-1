extends "res://tests/stabilization_tests.gd"

var app: Node
const TEST_SETTINGS: String = "user://release_test_settings.cfg"


func menu_button(title: String) -> Button:
	for child: Node in app.box.find_children("*", "Button", true, false):
		if child is Button and child.text == title:
			return child
	return null


func _run() -> void:
	DirAccess.remove_absolute(TEST_SETTINGS)
	DirAccess.remove_absolute(TEST_SETTINGS + ".chapters.json")
	app = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = TEST_SETTINGS
	root.add_child(app)
	current_scene = app
	await frames(3)
	check(app.page == "main" and app.session == null, "launch shows title without running an incident")
	await click_control(menu_button("Onboarding Docs"))
	check(app.page == "controls" and "Space      Sprint / jump" in app.CONTROLS, "pointer opens accurate controls")
	await key(KEY_ESCAPE)
	await click_control(menu_button("Corporate Policy"))
	check(app.page == "settings", "settings reachable from title")
	app.change_setting("master", .35)
	app.change_setting("effects", 0.0)
	app.change_setting("shake", 0.0)
	app.change_setting("sensitivity", 1.7)
	app.change_setting("flash", false)
	app.change_setting("quality", 0)
	var saved: RefCounted = load("res://game/release/preferences.gd").new()
	saved.path = TEST_SETTINGS
	saved.load_settings()
	check(saved.values == app.preferences.values and not saved.values.has("debt"), "fresh preference object loads saved device settings only")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")), "effects can be muted independently")
	await key(KEY_ESCAPE)
	await click_control(menu_button("Attempt to Log Off"))
	check(app.page == "logoff" and menu_button("Log Off Anyway") != null and menu_button("Stay") != null, "quit asks for one confirmation")
	await key(KEY_ESCAPE)
	check(app.page == "main" and app.backdrop != null and app.backdrop.is_inside_tree(), "Escape cancels log off back to the live title backdrop")
	for cycle in range(10):
		await click_control(menu_button("Replay Stage One" if app.progress.stage_one_completed else "Acknowledge Incident"))
		scene = app.session
		player = scene.get_node("Player")
		incident = scene.get_node("Incident")
		await frames(4)
		check(app.page == "" and not paused and player.camera_rig.controls_active and not player.melee.attacking, "cycle %d: start reaches gameplay without leaked attack" % cycle)
		check(player.camera_rig.impulse_degrees == 0 and is_equal_approx(player.camera_rig.mouse_sensitivity, .00425) and not scene.get_node("HUD").damage_flash_enabled, "cycle %d: preferences apply to fresh incident" % cycle)
		var count: int = scene.find_children("*", "", true, false).size()
		await key(KEY_ESCAPE)
		var before: float = incident.elapsed
		await frames(12)
		check(paused and app.page == "pause" and incident.elapsed == before, "cycle %d: pause freezes active incident time" % cycle)
		await click_control(menu_button("Corporate Policy"))
		await key(KEY_R)
		check(app.page == "settings" and incident.elapsed == before, "settings consumes restart without disturbing run")
		await key(KEY_ESCAPE)
		await key(KEY_ESCAPE)
		check(not paused and app.page.is_empty(), "Escape resumes from pause")
		check(app.backdrop == null and get_nodes_in_group("players").size() == 1, "cycle %d: title backdrop leaves before the incident" % cycle)
		await key(KEY_TAB)
		if cycle == 0:
			check(incident.stage == incident.Stage.ALERT, "fresh device cannot skip the first opening")
			incident.presentation.skip()
			await frames(2)
			check(app.preferences.values.opening_seen, "seen opening is remembered on this device")
		await frames(130)
		check(is_instance_valid(incident.active_enemy), "opening skip reaches live first enemy")
		incident._offer_upgrade(incident.Stage.INVESTIGATION)
		await key(KEY_ESCAPE)
		check(app.page == "pause" and incident.upgrade_pending, "Escape suspends upgrade without losing decision")
		await key(KEY_1)
		check(incident.run.choices.is_empty(), "hidden decision cannot consume input through pause")
		await click_control(menu_button("Resume Suffering"))
		await key(KEY_1)
		check(incident.stage == incident.Stage.INVESTIGATION and not paused, "resume returns to upgrade and applies selection once")
		# Approach from the clear south side; planted employees can occupy
		# the dashboard approach and E correctly prefers its local conversation there.
		player.position = incident.CONSOLE_POSITION + Vector3(0, .05, 3.9)
		await key(KEY_E)
		await key(KEY_3)
		await key(KEY_TAB)
		await key(KEY_ESCAPE)
		app.open_settings()
		app.go_back()
		app.resume_incident()
		await key(KEY_2)
		check(incident.corporate_choice == 1 and not paused, "corporate decision survives pause and settings")
		incident.fail()
		await frames(3)
		check(app.page == "report" and paused and menu_button("Restart Incident") != null, "defeat reaches actionable report")
		if cycle == 0:
			check(not app.progress.stage_one_completed, "losing Stage One does not record completion")
		await click_control(menu_button("Restart Incident"))
		await frames(3)
		check(incident.stage == incident.Stage.ALERT and incident.run.debt == 0 and incident.run.burnout == 0 and incident.run.choices.is_empty() and not paused and scene.find_children("*", "", true, false).size() == count, "cycle %d: restart clears actors, decisions, modifiers and pause with stable nodes" % cycle)
		for next in [incident.Stage.ENCOUNTER_ONE, incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
			incident._enter(next)
		incident.presentation.skip()
		incident.active_enemy.exposed = true
		incident.active_enemy.receive_damage(10000, player.position)
		await frames(3)
		check(app.page == "report" and incident.stage == incident.Stage.RESOLVED, "victory reaches report in release application")
		check(app.progress.stage_one_completed and menu_button("Replay Stage One") != null, "victory saves completion and offers replay")
		await click_control(menu_button("Back to Desk"))
		await frames(4)
		check(app.session == null and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("players").is_empty(), "cycle %d: main menu unloads all actors and audio owners" % cycle)
	# Real finale completion returns directly to a usable menu after its closing card.
	app.start_incident()
	scene = app.session
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	incident.presentation.skip()
	incident._cleanup()
	for next in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	var story: Node = incident.presentation
	story.reset_story()
	story.killcam_in_headless = true
	incident.hold_ending = true
	player.camera_rig.controls_active = true
	incident._enter(incident.Stage.RESOLVED)
	await frames(3)
	story.set_process(false)
	var finale: Node = story.all_hands
	check(is_instance_valid(finale), "release victory owns a finale before leaving the run")
	if is_instance_valid(finale):
		finale._beat("receipts")
		finale._beat("next")
		check(finale.titles.text == "TO BE CONTINUED" and app.page.is_empty(), "the closing card appears before menu navigation")
		finale.tick(3.6)
		await frames(4)
		check(app.page == "main" and app.session == null and app.backdrop != null and paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
			"the finished ending returns directly to the main menu with visible mouse and live backdrop")
		check(get_nodes_in_group("players").is_empty() and get_nodes_in_group("enemies").is_empty(), "return to menu unloads all run actors and their audio")
		app.start_incident()
		await frames(3)
		var restarted: Node = app.session.get_node("Incident")
		check(app.page.is_empty() and restarted.stage == restarted.Stage.ALERT and not paused,
			"a new run starts normally after the completed ending")
		app.main_menu()
		await frames(3)
	# Corrupt persisted data must not create unusable settings on next launch.
	var config: ConfigFile = ConfigFile.new()
	config.set_value("preferences", "sensitivity", -100)
	config.set_value("preferences", "master", "invalid")
	config.set_value("preferences", "quality", 999)
	config.save(TEST_SETTINGS)
	saved.load_settings()
	check(saved.values.sensitivity == .2 and saved.values.master == .8 and saved.values.quality == 1, "invalid persisted settings safely clamp or use defaults")
	DirAccess.remove_absolute(TEST_SETTINGS)
	DirAccess.remove_absolute(TEST_SETTINGS + ".chapters.json")
	app.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
