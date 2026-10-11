extends "res://tests/release_tests.gd"
## Outcome checks: fresh process data, UI unlock, replay/failure, and write failures.
const TEST_PROGRESS: String = "user://chapter_progress_test.json"
const TESTER: String = "Cleared Circle I in an older build?"


func _run() -> void:
	DirAccess.remove_absolute(TEST_PROGRESS)
	var progress: RefCounted = load("res://game/release/chapter_progress.gd").new()
	progress.path = TEST_PROGRESS
	progress.load_progress()
	check(not progress.stage_one_completed, "a fresh player has no completed chapter")
	check(progress.complete_stage_one() == OK, "chapter boundary writes successfully")
	var fresh: RefCounted = load("res://game/release/chapter_progress.gd").new()
	fresh.path = TEST_PROGRESS
	fresh.load_progress()
	check(fresh.stage_one_completed, "a fresh save reader retains completion across relaunch")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEST_PROGRESS))
	check(data.next_chapter == "stage_two" and data.completed_chapters == ["incident_001"] and not data.has("debt"), "save records the next chapter without temporary run modifiers")
	var before: String = FileAccess.get_file_as_string(TEST_PROGRESS)
	check(fresh.complete_stage_one() == OK and FileAccess.get_file_as_string(TEST_PROGRESS) == before, "repeat completion keeps the existing chapter save")
	var invalid: FileAccess = FileAccess.open(TEST_PROGRESS, FileAccess.WRITE)
	invalid.store_string('{"schema_version": 99, "completed_chapters": ["incident_001"]}')
	invalid.close()
	fresh.load_progress()
	before = FileAccess.get_file_as_string(TEST_PROGRESS)
	check(not fresh.stage_one_completed and fresh.complete_stage_one() != OK and FileAccess.get_file_as_string(TEST_PROGRESS) == before, "unsupported future saves are preserved without silently overwriting")
	invalid = FileAccess.open(TEST_PROGRESS, FileAccess.WRITE)
	invalid.store_string("broken save")
	invalid.close()
	fresh.load_progress()
	check(not fresh.stage_one_completed and not fresh.load_notice.is_empty() and fresh.complete_stage_one() != OK, "damaged save is preserved and explained")
	fresh.path = "user://nonexistent_chapter_test_directory/save.json"
	fresh.load_progress()
	check(fresh.complete_stage_one() != OK and not fresh.stage_one_completed, "failed writes never claim completion is saved")
	DirAccess.remove_absolute(TEST_PROGRESS)
	DirAccess.remove_absolute(TEST_SETTINGS + ".chapters.json")
	app = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = TEST_SETTINGS
	root.add_child(app)
	current_scene = app
	await frames(3)
	await click_control(menu_button("Play"))
	check(menu_button(TESTER) != null, "fresh campaign offers the earlier tester unlock")
	await click_control(menu_button(TESTER))
	check(app.page == "tester_unlock" and menu_button("Mark Circle I Cleared") != null, "tester unlock explains the action before saving")
	await key(KEY_ESCAPE)
	check(app.page == "campaign" and not app.progress.stage_one_completed, "backing out leaves completion locked")
	var real_path: String = app.progress.path
	app.progress.path = "user://nonexistent_chapter_test_directory/save.json"
	await click_control(menu_button(TESTER))
	await click_control(menu_button("Mark Circle I Cleared"))
	check(not app.progress.stage_one_completed and menu_button("Retry Save") != null and not app.progress_notice.is_empty(), "failed tester save offers retry without claiming saved completion")
	app.progress.path = real_path
	await click_control(menu_button("Retry Save"))
	check(app.page == "campaign" and app.progress.stage_one_completed and menu_button(TESTER) == null and menu_button(app.CIRCLES[0]) != null, "earlier testers save completion and keep replay")
	var labels: String = ""
	for label: Node in app.box.find_children("*", "Label", true, false):
		labels += label.text + "\n"
	check("INCIDENT 001  ·  CLEARED" in labels and "Circles II–VI are not built yet." in labels, "campaign marks Circle I cleared and honestly marks later circles unavailable")
	await click_control(menu_button(app.CIRCLES[0]))
	scene = app.session
	incident = scene.get_node("Incident")
	await frames(3)
	check(incident.stage == incident.Stage.ALERT and app.progress.stage_one_completed, "replay starts Stage One without clearing the save")
	incident.fail()
	await frames(3)
	app.restart_incident()
	await frames(3)
	app.main_menu()
	fresh.path = app.progress.path
	fresh.load_progress()
	check(fresh.stage_one_completed, "replay death, restart and return to title preserve disk completion")
	app.queue_free()
	paused = false
	await frames(3)
	app = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = TEST_SETTINGS
	root.add_child(app)
	current_scene = app
	await frames(3)
	await click_control(menu_button("Play"))
	check(app.progress.stage_one_completed and menu_button(TESTER) == null and "CLEARED" in str(app.box.find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)), "a new application instance loads completion into the campaign")
	app.queue_free()
	paused = false
	await frames(3)
	DirAccess.remove_absolute(TEST_SETTINGS)
	DirAccess.remove_absolute(TEST_SETTINGS + ".chapters.json")
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
