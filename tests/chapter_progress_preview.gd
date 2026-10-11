extends "res://tests/release_preview.gd"
## Graphical QA with a disposable save; never writes the player's completion.


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds")
	app = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = "user://chapter_preview_settings.cfg"
	DirAccess.remove_absolute(app.preferences.path + ".chapters.json")
	root.add_child(app)
	current_scene = app
	await shot("chapter_fresh")
	app.show_page("campaign")
	await shot("chapter_campaign")
	app.show_page("tester_unlock")
	await shot("chapter_unlock")
	app.unlock_stage_one()
	await shot("chapter_saved")
	DirAccess.remove_absolute(app.progress.path)
	app.queue_free()
	paused = false
	await frames(3)
	quit()
