extends SceneTree
## Temporary: contact sheet of the opening at fixed times.
func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	if paused:
		paused = false
	return false


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var marks: PackedFloat64Array = OS.get_cmdline_user_args()[1].split_floats(",")
	var scene: Node = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.get_node("Player").camera_rig.set_capture(true)
	var incident: Node = scene.get_node("Incident")
	var tiles: Array[Image] = []
	for mark in marks:
		while incident.stage_time < mark:
			scene.get_node("Player").camera_rig.controls_active = true
			await process_frame
		RenderingServer.force_draw()
		var image: Image = root.get_texture().get_image()
		image.convert(Image.FORMAT_RGBA8)
		image.resize(426, 240)
		tiles.append(image)
	var cols: int = 4
	var sheet: Image = Image.create(426 * cols, 240 * ceili(tiles.size() / float(cols)), false, Image.FORMAT_RGBA8)
	for index in range(tiles.size()):
		sheet.blit_rect(tiles[index], Rect2i(0, 0, 426, 240), Vector2i(426 * (index % cols), 240 * (index / cols)))
	sheet.save_png(out)
	print("SAVED")
	quit()
