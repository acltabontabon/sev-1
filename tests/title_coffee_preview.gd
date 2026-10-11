extends SceneTree
## Actual title scheduling and camera; save pickup/sip/return views for creator review.
## sh tools/godot.sh --path . --fixed-fps 60 --script tests/title_coffee_preview.gd


func _initialize() -> void:
	_review.call_deferred()


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/title_coffee_" + label + ".png")
	print("CAPTURE title coffee ", label)


func _review() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://builds")
	var app: Node = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = "user://title_coffee_preview_nonexistent.cfg"
	root.add_child(app)
	current_scene = app
	var backdrop: Node3D = app.backdrop
	var rig: Node3D = backdrop.character
	var reached: bool = false
	var drank: bool = false
	for frame in range(1500):
		await physics_frame
		await process_frame
		if rig.coffee_active and rig.coffee_time >= .8 and not reached:
			reached = true
			await _capture("pickup")
		if rig.coffee_active and rig.coffee_time >= 2.4 and not drank:
			drank = true
			await _capture("sip")
		if drank and not rig.coffee_active:
			await _capture("returned")
			quit()
			return
	push_error("The normal title did not complete its first coffee cycle")
	quit(1)
