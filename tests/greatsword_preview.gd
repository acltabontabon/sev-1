extends "res://tests/rig_preview.gd"
## Wider office view of the imported sword's shoulder carry, for creator review.
## sh tools/godot.sh --path . --script tests/greatsword_preview.gd


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	scene = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	var enemy: Node3D = scene.get_node("Enemy")
	enemy.hide()
	enemy.set_physics_process(false)
	player.position = Vector3(0, .05, 2)
	camera = Camera3D.new()
	camera.fov = 45.0
	scene.add_child(camera)
	camera.make_current()
	scene.get_node("HUD").hide()
	player.camera_rig.set_capture(true)
	paused = false
	keep_running = true
	await frames(100)
	player.visual.rotation.y = 0
	frame_player(Vector3(3.0, 2.1, -4.3))
	await frames(10)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds")
	root.get_texture().get_image().save_png("res://builds/greatsword_shoulder.png")
	print("SHOT builds/greatsword_shoulder.png")
	player.camera_rig.set_capture(false)
	quit()
