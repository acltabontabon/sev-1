extends "res://tests/incident_tests.gd"

func _run() -> void:
	var app: Node = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = "user://frame_budget_test.cfg"
	root.add_child(app)
	current_scene = app
	await frames(2)
	check(app.frame_budget(true) == 30 and app.frame_budget(false) == 15, "title limits foreground and background rendering")
	app.start_incident()
	await frames(3)
	check(app.frame_budget(true) == 60, "fresh gameplay defaults to 60 FPS")
	app.change_setting("frame_limit", 120)
	var saved: RefCounted = load("res://game/release/preferences.gd").new()
	saved.path = app.preferences.path
	saved.load_settings()
	check(saved.values.frame_limit == 120 and app.frame_budget(true) == 120, "120 FPS option persists and applies to gameplay")
	app.pause_incident()
	var incident_node: Node = app.session.get_node("Incident")
	var elapsed: float = incident_node.elapsed
	await frames(10)
	check(app.frame_budget(true) == 30 and incident_node.elapsed == elapsed, "pause keeps simulation frozen and reduces rendering")
	app.resume_incident()
	check(app.frame_budget(true) == 120 and app.frame_budget(false) == 15, "resume restores selected rate; focus loss reduces it")
	check(Engine.physics_ticks_per_second == 60 and Engine.time_scale == 1.0, "frame budgets preserve physics ticks and game speed")
	var config: ConfigFile = ConfigFile.new()
	config.set_value("preferences", "frame_limit", 0)
	config.save(saved.path)
	saved.load_settings()
	check(saved.values.frame_limit == 60, "invalid uncapped preference falls back to 60 FPS")
	DirAccess.remove_absolute(saved.path)
	DirAccess.remove_absolute(saved.path + ".chapters.json")
	app.queue_free()
	paused = false
	await frames(2)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
