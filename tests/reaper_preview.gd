extends SceneTree
## Isolated art comparison. No encounters, progression, damage or save writes.
var scene: Node3D
var camera: Camera3D
var reaper: Node3D
var animator: AnimationPlayer
var angle: float = 0.0
var orbiting: bool = false
var comparison: bool = true
var reference: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.title = "SEV-1 · Abyssal Reaper vault art trial"
	root.window_input.connect(_on_input)
	var path: String = "res://assets/enemies/reaper_trial/abyssal_reaper.glb"
	if not ResourceLoader.exists(path):
		push_error("Local Reaper GLB missing. See assets/enemies/reaper_trial/README.md")
		quit(1)
		return
	scene = load("res://game/main.tscn").instantiate()
	scene.set_script(null)
	for child: Node in scene.get_children():
		if child.name not in [&"OfficeAfterHours", &"WorldEnvironment", &"KeyLight", &"Player"]:
			scene.remove_child(child)
			child.free()
	# Keep the current outfit and weapon, then disable player input and motion.
	# The Incident controller has been removed, so this scene has no run saves.
	var player: CharacterBody3D = scene.get_node("Player")
	player.position = Vector3(9, .05, -35.0)
	root.add_child(scene)
	current_scene = scene
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	player.visual.rotation.y = PI
	player.presentation.set_physics_process(false)
	player.presentation.reset_pose()
	player.camera_rig.set_process(false)
	player.camera_rig.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	reaper = load(path).instantiate()
	reaper.position = Vector3(6.4, .05, -40)
	scene.add_child(reaper)
	animator = reaper.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert(animator != null, "Imported Reaper must contain its supplied idle")
	var idle: StringName
	for clip: StringName in animator.get_animation_list():
		if "idle" in String(clip).to_lower():
			idle = clip
	assert(not idle.is_empty(), "Supplied idle animation missing")
	animator.get_animation(idle).loop_mode = Animation.LOOP_LINEAR
	animator.play(idle)
	print("REAPER idle: ", idle, " / seconds: ", animator.get_animation(idle).length)
	reference = load("res://game/enemies/incident.tscn").instantiate()
	reference.rig_kind = "variance"
	reference.bark_kind = ""
	reference.position = Vector3(12.2, .05, -40)
	scene.add_child(reference)
	reference.set_physics_process(false)
	reference.visual.set_physics_process(false)
	reference.rig.set_physics_process(false)
	reference.label.text = "CURRENT BOSS BODY"
	reference.label.position.y = 4.05
	var current_idle: String = reference.rig.clips["idle"]
	reference.rig.animator.play(current_idle)
	reference.rig.animator.seek(.5, true)
	reference.rig.animator.pause()
	var title: Label3D = Label3D.new()
	title.text = "ABYSSAL REAPER · FREE IDLE"
	title.position = reaper.position + Vector3(0, 4.1, 0)
	title.font_size = 38
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	scene.add_child(title)
	camera = Camera3D.new()
	camera.fov = 52
	scene.add_child(camera)
	_frame()
	camera.make_current()
	var layer: CanvasLayer = CanvasLayer.new()
	scene.add_child(layer)
	var caption: Label = Label.new()
	caption.position = Vector2(30, 25)
	caption.add_theme_font_size_override("font_size", 24)
	caption.text = "VAULT ART COMPARISON · Original Reaper textures · Supplied idle only\n1 comparison · 2 Reaper close-up · Space orbit · Esc close\nLocal trial: source provenance requires clarification before shipping"
	layer.add_child(caption)
	for index in range(90):
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await _capture("reaper_vault_comparison")
		comparison = false
		_frame()
		for index in range(10):
			await process_frame
		await _capture("reaper_vault_closeup")
		quit()


func _process(delta: float) -> bool:
	if orbiting and camera != null:
		angle += delta * .25
		_frame()
	return false


func _frame() -> void:
	var center: Vector3 = Vector3(9, 2.0, -40) if comparison else reaper.position + Vector3(0, 1.8, 0)
	var offset: Vector3 = Vector3(0, 1.2, 10.8) if comparison else Vector3(0, .4, 6.1)
	camera.position = center + offset.rotated(Vector3.UP, angle)
	camera.look_at(center)


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds")
	assert(root.get_texture().get_image().save_png("res://builds/" + filename + ".png") == OK)
	print("CAPTURE ", filename)


func _on_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				quit()
			KEY_1, KEY_2:
				comparison = event.keycode == KEY_1
				angle = 0.0
				_frame()
			KEY_SPACE:
				orbiting = not orbiting
