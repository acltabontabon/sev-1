extends SceneTree
## Actual gameplay rig/materials at melee contact and physical death in office light.
var scene: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	scene = load("res://game/main.tscn").instantiate()
	scene.set_script(null)
	for child: Node in scene.get_children():
		if child.name not in [&"OfficeAfterHours", &"WorldEnvironment", &"KeyLight", &"Player"]:
			scene.remove_child(child)
			child.free()
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	player.position = Vector3(1.3, .05, 4.0)
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.camera_rig.set_capture(false)
	player.camera_rig.set_physics_process(false)
	var foe: CharacterBody3D = load("res://game/enemies/incident.tscn").instantiate()
	foe.position = Vector3(-1.3, .05, 4.0)
	scene.add_child(foe)
	foe.set_physics_process(false)
	foe.rig.set_physics_process(false)
	foe.visual.set_physics_process(false)
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0, 2.1, -4.0)
	camera.look_at(Vector3(0, 1.2, 4.0))
	camera.fov = 45.0
	camera.make_current()
	var pose: String = "idle"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--pose="):
			pose = argument.trim_prefix("--pose=")
	if pose == "attack":
		foe.melee.start()
		foe.melee.set_physics_process(false)
		foe.melee.elapsed = foe.melee.windup
		foe.rig._physics_process(1.0 / 60.0)
		# This stopped-frame probe bypasses the normal multi-frame crossfade.
		foe.rig.animator.play(foe.rig.clips.attack, 0.0)
		foe.rig.animator.seek(foe.rig.animator.current_animation_length * foe.rig.spec.impact, true)
	elif pose == "gore":
		foe.engage()
		foe.receive_damage(10000, foe.position + Vector3(0, 0, -2))
		foe.rig._die(.02)
		for index in range(6):
			await physics_frame
		paused = true
	for index in range(90):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds")
	assert(root.get_texture().get_image().save_png("res://builds/skeleton_combat_" + pose + ".png") == OK)
	print("CAPTURE skeleton_combat_", pose)
	quit()
