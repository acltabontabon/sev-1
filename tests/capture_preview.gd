extends SceneTree
## Render a repeatable review image with a real graphics device, not headless.


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var scene: Node = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	if "--combat" in OS.get_cmdline_user_args():
		var player: CharacterBody3D = scene.get_node("Player")
		var enemy: CharacterBody3D = scene.get_node("Enemy")
		# An unattended capture must not pause when another app gains focus.
		player.camera_rig.capture_changed.disconnect(scene._on_capture_changed)
		player.global_position = Vector3(0, 0.05, 5)
		enemy.global_position = Vector3(0, 0.05, 3.3)
		enemy.set_physics_process(false)
		enemy.visual.rotation.y = PI
		player.camera_rig.controls_active = true
		paused = false
		for index in range(10):
			await physics_frame
			await process_frame
		enemy.melee.start()
		for index in range(24):
			await physics_frame
			await process_frame
		enemy.tell.show()
		player.request_attack()
		for index in range(9):
			await physics_frame
			await process_frame
		paused = true
		player.camera_rig.controls_active = true
		scene.get_node("HUD").refresh()
	scene.get_node("HUD/CapturePrompt").hide()
	for index in range(60):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds")
	var ignore_file: FileAccess = FileAccess.open("res://builds/.gdignore", FileAccess.WRITE)
	if ignore_file:
		ignore_file.close()
	var path: String = "res://builds/combat_preview.png" if "--combat" in OS.get_cmdline_user_args() else "res://builds/movement_preview.png"
	var error: Error = root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Could not save preview: " + error_string(error))
	# The preview freezes mid-swing. Stop its paused audio before tearing down.
	scene.get_node("Player/Visual/Melee").cancel()
	scene.get_node("Enemy/Visual/Melee").cancel()
	scene.get_node("Player/HitSound").stop()
	scene.get_node("Player/HurtSound").stop()
	scene.queue_free()
	paused = false
	await create_timer(0.25).timeout
	quit(0 if error == OK else 1)
