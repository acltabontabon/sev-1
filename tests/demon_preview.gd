extends SceneTree
## Review both licensed demon bodies in the actual office; --capture saves and exits.
var scene: Node3D
var demons: Array[CharacterBody3D] = []
var camera: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.window_input.connect(_on_input)
	scene = load("res://game/main.tscn").instantiate()
	scene.set_script(null)
	for child: Node in scene.get_children():
		if child.name not in [&"OfficeAfterHours", &"WorldEnvironment", &"KeyLight"]:
			scene.remove_child(child)
			child.free()
	root.add_child(scene)
	current_scene = scene
	for index in range(2):
		var actor: CharacterBody3D = load("res://game/enemies/incident.tscn").instantiate()
		actor.rig_kind = "night_demon" if index == 0 else "chained_demon"
		actor.bark_kind = "record"
		actor.position = Vector3(-1.5 + index * 3.0, .05, 4.0)
		scene.add_child(actor)
		actor.set_physics_process(false)
		actor.rig.set_physics_process(false)
		actor.visual.set_physics_process(false)
		actor.label.text = "NIGHT DEMON" if index == 0 else "CHAINED DEMON"
		actor.label.position.y = 2.7
		demons.append(actor)
	camera = Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0, 2.0, -3.0)
	camera.look_at(Vector3(0, 1.1, 4))
	camera.fov = 48.0
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var layer: CanvasLayer = CanvasLayer.new()
	scene.add_child(layer)
	var caption: Label = Label.new()
	caption.position = Vector2(30, 30)
	caption.add_theme_font_size_override("font_size", 24)
	caption.text = "DEMON BODY TRIAL · Original textures / provisional motions\n1 idle · 2 walk · 3 attack · 4 stagger · 5 death · Esc close"
	layer.add_child(caption)
	var review_pose: String = "Idle"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--pose="):
			review_pose = argument.trim_prefix("--pose=")
	_pose(review_pose, .5)
	var gore_review: bool = "--gore" in OS.get_cmdline_user_args()
	if gore_review:
		for actor: CharacterBody3D in demons:
			actor.engage()
			actor.receive_damage(10000, actor.position + Vector3(0, 0, -2))
			actor.rig._die(.02)
		for index in range(6):
			await physics_frame
		paused = true
	for index in range(90):
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://builds")
		var filename: String = "demon_trials" if review_pose == "Idle" else "demon_trials_" + review_pose.to_snake_case()
		if gore_review:
			filename = "demon_trials_gore"
		assert(root.get_texture().get_image().save_png("res://builds/" + filename + ".png") == OK)
		print("CAPTURE demon_trials")
		quit()


func _pose(clip: String, time: float) -> void:
	for actor: CharacterBody3D in demons:
		var rig: MonsterRig = actor.rig
		var name_: String = rig._resolve(clip)
		assert(not name_.is_empty(), "Missing demon trial clip: " + clip)
		rig.animator.play(name_, 0.0)
		rig.animator.seek(time, true)
		rig.animator.pause()


func _on_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				quit()
			KEY_1:
				_pose("Idle", .5)
			KEY_2:
				_pose("Walk", .2)
			KEY_3:
				_pose("Attack", .5)
			KEY_4:
				_pose("HitReact", .25)
			KEY_5:
				_pose("Death", 1.3)
