extends "res://tests/rig_preview.gd"
## Hero look-development sheet: the engineer from the front, three-quarter, side, the
## gameplay back view, a face close-up and battle mode, for creator review.
## sh tools/godot.sh --path . --script tests/hero_preview.gd
## Writes builds/hero_sheet.png. It shows the look only, not motion quality or feel.


func _run() -> void:
	root.size = Vector2i(1280, 720)
	scene = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	var enemy: Node3D = scene.get_node("Enemy")
	enemy.hide()
	enemy.set_physics_process(false)
	player.position = Vector3(0, .05, 2)
	camera = Camera3D.new()
	camera.fov = 40.0
	scene.add_child(camera)
	camera.make_current()
	scene.get_node("HUD").hide()
	player.camera_rig.set_capture(true)
	paused = false
	keep_running = true
	await frames(100)
	player.visual.rotation.y = 0
	var view: Node3D = player.get_node("Visual/Character")
	# The model faces -Z: the front views stand on that side.
	for entry: Array in [
		["front", Vector3(0, 1.2, -3.0), .85],
		["three-quarter", Vector3(2.0, 1.4, -2.3), .85],
		["side", Vector3(3.0, 1.1, 0), .85],
		["back (gameplay)", Vector3(-.6, 1.7, 3.2), .9],
		["face", Vector3(.5, 1.8, -1.5), 1.5],
	]:
		camera.position = player.global_position + entry[1]
		camera.look_at(player.global_position + Vector3(0, entry[2], 0))
		await frames(4)
		await grab(entry[0])
	view.battle = 1.0
	camera.position = player.global_position + Vector3(1.6, 1.3, -2.2)
	camera.look_at(player.global_position + Vector3(0, .85, 0))
	await frames(8)
	await grab("battle mode")
	var sheet: Image = Image.create(640 * 3, 360 * 2, false, Image.FORMAT_RGBA8)
	for index in range(tiles.size()):
		sheet.blit_rect(tiles[index], Rect2i(0, 0, 640, 360), Vector2i(640 * (index % 3), 360 * (index / 3)))
	DirAccess.make_dir_recursive_absolute("res://builds")
	var out: String = "res://builds/hero_sheet.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	sheet.save_png(out)
	print("SHEET ", out)
	player.camera_rig.set_capture(false)
	quit()
