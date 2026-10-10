extends SceneTree
func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	if paused:
		paused = false
	return false


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var scene: Node3D = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	scene.get_node("Enemy").position = Vector3(0, -50, 0)
	scene.get_node("HUD").hide()
	player.position = Vector3(0, .05, 2)
	var character: Node3D = player.get_node("Visual/Character")
	var camera: Camera3D = Camera3D.new()
	camera.fov = 45
	scene.add_child(camera)
	camera.make_current()
	camera.global_position = player.global_position + Vector3(3.2, 1.4, -2.2)
	camera.look_at(player.global_position + Vector3(0, .95, 0))
	var tiles: Array[Image] = []
	for clip in ["sword_a", "sword_b", "sword_c", "sword_combo", "sword_attack"]:
		print("LEN ", clip, " ", character.animator.get_animation("rig/" + clip).length)
		for at in [.15, .35, .55, .75]:
			character.preview_clip = clip
			character.preview_at = at
			for i in range(3):
				await physics_frame
			await process_frame
			RenderingServer.force_draw()
			var image: Image = root.get_texture().get_image()
			image.convert(Image.FORMAT_RGBA8)
			image.resize(320, 180)
			tiles.append(image)
	var sheet: Image = Image.create(1280, 180 * 5, false, Image.FORMAT_RGBA8)
	for index in range(tiles.size()):
		sheet.blit_rect(tiles[index], Rect2i(0, 0, 320, 180), Vector2i(320 * (index % 4), 180 * (index / 4)))
	sheet.save_png(out)
	print("SAVED")
	quit()
