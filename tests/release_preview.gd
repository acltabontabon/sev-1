extends SceneTree
var app: Node
func _initialize() -> void:
	_run.call_deferred()
func frames(count: int = 10) -> void:
	for index in range(count):
		await process_frame
func shot(title: String) -> void:
	await frames()
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://builds/release_" + title + ".png")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds")
	app = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = "user://preview_nonexistent.cfg"
	root.add_child(app)
	current_scene = app
	await shot("title")
	app.open_settings()
	await shot("settings")
	app.go_back()
	app.open_controls()
	await shot("controls")
	app.start_incident()
	await shot("opening")
	app.pause_incident()
	await shot("pause")
	app.resume_incident()
	app.session.get_node("Incident").fail()
	await shot("report")
	for child: Node in app.box.get_children():
		if child is Button:
			print(child.text, ": ", child.get_global_rect())
	app.queue_free()
	paused = false
	await frames(3)
	quit()
