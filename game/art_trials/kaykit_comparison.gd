extends Node3D
## Isolated character review in the actual office, with the current engineer rig.
const MODEL: PackedScene = preload("res://assets/enemies/kaykit_trial/skeleton_minion.glb")
const CLIPS: Array[String] = ["Idle", "Walking_D_Skeletons", "Unarmed_Melee_Attack_Punch_A"]
var skeleton_body: Node3D
var engineer: Node3D
var animator: AnimationPlayer
var camera: Camera3D
var status: Label
var original_bounds: AABB
var matched_scale: float = 1.0
var matched_size: bool = false
var capture: bool = false


func _ready() -> void:
	get_window().size = Vector2i(1920, 1080)
	capture = "--capture" in OS.get_cmdline_user_args()
	var office: Node3D = load("res://game/main.tscn").instantiate()
	office.set_script(null)
	for child: Node in office.get_children():
		if child.name not in [&"OfficeAfterHours", &"WorldEnvironment", &"KeyLight", &"Player"]:
			office.remove_child(child)
			child.free()
	add_child(office)
	var player: CharacterBody3D = office.get_node("Player")
	player.position = Vector3(1.1, .05, 4.0)
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.camera_rig.set_capture(false)
	player.camera_rig.set_process_unhandled_input(false)
	player.camera_rig.set_physics_process(false)
	engineer = player.presentation
	skeleton_body = MODEL.instantiate()
	add_child(skeleton_body)
	original_bounds = _bounds(skeleton_body)
	var hero_bounds: AABB = _bounds(engineer.model)
	matched_scale = hero_bounds.size.y / original_bounds.size.y
	assert(matched_scale > .1 and matched_scale < 5.0, "Unexpected character units")
	assert(hero_bounds.size.y > 1.5 and hero_bounds.size.y < 2.5, "Unexpected engineer height")
	animator = skeleton_body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert(animator != null, "Skeleton is missing its animator")
	for clip: String in CLIPS:
		assert(animator.has_animation(clip), "Missing original KayKit animation: " + clip)
	skeleton_body.rotation.y = PI
	_set_size(false)
	_pose(0)
	camera = Camera3D.new()
	camera.fov = 43.0
	add_child(camera)
	_view("front")
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--pose=walk":
			_pose(1)
		elif argument == "--pose=punch":
			_pose(2)
		elif argument == "--original":
			_set_size(false)
		elif argument.begins_with("--view="):
			_view(argument.trim_prefix("--view="))
	print("KayKit comparison: engineer height %.3f m; source minion %.3f m; matched scale %.3f" % [hero_bounds.size.y, original_bounds.size.y, matched_scale])
	if capture:
		_capture.call_deferred()


func _bounds(body: Node3D) -> AABB:
	var result: AABB
	var first: bool = true
	for child: Node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = child as MeshInstance3D
		var box: AABB = (body.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		if first:
			result = box
			first = false
		else:
			result = result.merge(box)
	# Include the body node's own scale, e.g. the engineer's 0.64 source conversion.
	return Transform3D(Basis.from_scale(body.scale), Vector3.ZERO) * result


func _set_size(matched: bool) -> void:
	matched_size = matched
	var factor: float = matched_scale if matched else 1.0
	skeleton_body.scale = Vector3.ONE * factor
	skeleton_body.position = Vector3(-1.1, .05 - original_bounds.position.y * factor, 4.0)
	_update_status()


func _pose(index: int) -> void:
	var clip: String = CLIPS[index]
	animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animator.play(clip, .15)
	_update_status()


func _view(direction: String) -> void:
	var focus: Vector3 = Vector3(0, 1.1, 4.0)
	match direction:
		"front": camera.position = Vector3(0, 1.8, -3.5)
		"side": camera.position = Vector3(5.5, 1.8, -.5)
		"back": camera.position = Vector3(0, 1.8, 11.5)
	camera.look_at(focus)


func _build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(16, 16)
	layer.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	panel.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var title: Label = Label.new()
	title.text = "KAYKIT MINION · beside the current engineer"
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 14)
	column.add_child(status)
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	for index in range(CLIPS.size()):
		_button(row, ["1 Idle", "2 Walk", "3 Punch"][index], _pose.bind(index))
	for direction: String in ["front", "side", "back"]:
		_button(row, direction.capitalize(), _view.bind(direction))
	_button(row, "Toggle original / matched size", func() -> void: _set_size(not matched_size))
	_button(row, "Close (Esc)", get_tree().quit)
	var note: Label = Label.new()
	note.text = "Free CC0 Skeleton Minion · F/S/B views · M size · visual trial"
	note.add_theme_font_size_override("font_size", 12)
	column.add_child(note)
	_update_status()


func _button(parent: Node, caption: String, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = caption
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(action)
	parent.add_child(button)


func _update_status() -> void:
	if status != null:
		var pose: String = ["Idle", "Walk", "Punch"][CLIPS.find(animator.current_animation)]
		status.text = "%s · %s · original KayKit materials" % [pose, "Matched engineer height" if matched_size else "Original author size"]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _pose(0)
			KEY_2: _pose(1)
			KEY_3: _pose(2)
			KEY_F: _view("front")
			KEY_S: _view("side")
			KEY_B: _view("back")
			KEY_M: _set_size(not matched_size)
			KEY_ESCAPE: get_tree().quit()


func _capture() -> void:
	for index in range(90):
		await get_tree().process_frame
	var samples: Array[float] = []
	var previous: int = Time.get_ticks_usec()
	for index in range(120):
		await get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		samples.append(float(now - previous) / 1000.0)
		previous = now
	samples.sort()
	var total: float = 0.0
	for sample: float in samples:
		total += sample
	print("KayKit staged office 1920x1080: mean %.2f ms; p95 %.2f ms (presentation/vsync included)" % [total / samples.size(), samples[113]])
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds")
	var suffix: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--pose=") or argument.begins_with("--view="):
			suffix += "_" + argument.get_slice("=", 1)
	assert(get_viewport().get_texture().get_image().save_png("res://builds/kaykit_comparison" + suffix + ".png") == OK)
	get_tree().quit()
