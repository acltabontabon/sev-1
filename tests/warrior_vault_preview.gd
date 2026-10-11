extends SceneTree
## Isolated art comparison. No encounters, progression, damage or save writes.
var scene: Node3D
var camera: Camera3D
var warrior: Node3D
var animator: AnimationPlayer
var angle: float = 0.0
var orbiting: bool = false
var comparison: bool = true
var skin: ShaderMaterial
var golem: Node3D
var axe: Node3D
var original_bounds: AABB
const CLIPS: Array[String] = ["Idle_Combat", "Walking_D_Skeletons", "1H_Melee_Attack_Chop"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.title = "SEV-1 · Free skeleton golem vault trial"
	root.window_input.connect(_on_input)
	var path: String = "res://assets/enemies/warrior_trial/skeleton_warrior.glb"
	if not ResourceLoader.exists(path):
		push_error("Local Warrior GLB missing. See assets/enemies/warrior_trial/README.md")
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
	player.position = Vector3(11.3, .05, -39.7)
	root.add_child(scene)
	current_scene = scene
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	player.visual.rotation.y = PI
	player.presentation.reset_pose()
	player.camera_rig.set_capture(false)
	player.camera_rig.set_process_unhandled_input(false)
	player.camera_rig.set_process(false)
	player.camera_rig.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	warrior = load(path).instantiate()
	warrior.position = Vector3(7.0, .05, -40)
	scene.add_child(warrior)
	animator = warrior.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert(animator != null, "Imported Warrior must contain its supplied idle")
	original_bounds = _bounds(warrior)
	var factor: float = 3.6 / original_bounds.size.y
	warrior.scale = Vector3.ONE * factor
	warrior.position.y = .05 - original_bounds.position.y * factor
	warrior.rotation.y = 0.0
	skin = ShaderMaterial.new()
	skin.shader = load("res://game/art_trials/warrior_vault/dark_armor.gdshader")
	for node: Node in warrior.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		for surface: int in range(mesh.mesh.get_surface_count()):
			var source: StandardMaterial3D = mesh.get_active_material(surface) as StandardMaterial3D
			if source != null and source.albedo_texture != null:
				skin.set_shader_parameter("source_texture", source.albedo_texture)
				mesh.set_surface_override_material(surface, skin)
	_accessory("handslot.r", "skeleton_axe")
	_accessory("handslot.l", "skeleton_shield_large_a")
	golem = load("res://game/art_trials/warrior_vault/golem_armor.gd").new()
	scene.add_child(golem)
	golem.build(warrior, axe)
	golem.set_enabled(false)
	_pose(0)
	print("WARRIOR source height %.3f m; trial 3.600 m; factor %.3f" % [original_bounds.size.y, factor])
	var title: Label3D = Label3D.new()
	title.text = "THE VARIANCE · GOLEM STYLE TRIAL"
	title.position = Vector3(7.0, 3.85, -40)
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
	caption.add_theme_font_size_override("font_size", 18)
	caption.text = "THE VARIANCE · SKELETON GOLEM STYLE TRIAL · Boss scale / dark armor\n1 comparison · 2 close-up · I idle · W walk · A axe chop · D armor palette · G golem / warrior · Space orbit · Esc close\nFree CC0 KayKit · visual comparison, existing combat unchanged"
	layer.add_child(caption)
	for index in range(90):
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await _capture("warrior_vault_comparison")
		comparison = false
		_frame()
		for index in range(10):
			await process_frame
		await _capture("warrior_vault_closeup")
		comparison = true
		_frame()
		for index: int in [1, 2]:
			animator.play(CLIPS[index], 0.0)
			animator.advance(0.0)
			animator.seek(.35, true)
			animator.pause()
			for frame: int in range(10):
				await process_frame
			await _capture("warrior_vault_walk" if index == 1 else "warrior_vault_chop")
		_pose(0)
		skin.set_shader_parameter("dark_armor", false)
		for frame: int in range(10):
			await process_frame
		await _capture("warrior_vault_original_palette")
		quit()


func _process(delta: float) -> bool:
	if orbiting and camera != null:
		angle += delta * .25
		_frame()
	return false


func _frame() -> void:
	var center: Vector3 = Vector3(9, 1.9, -40) if comparison else warrior.position + Vector3(0, 1.8, 0)
	var offset: Vector3 = Vector3(0, .9, 9.8) if comparison else Vector3(0, .3, 6.7)
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
			KEY_I:
				_pose(0)
			KEY_W:
				_pose(1)
			KEY_A:
				_pose(2)
			KEY_D:
				skin.set_shader_parameter("dark_armor", not bool(skin.get_shader_parameter("dark_armor")))
			KEY_G:
				golem.set_enabled(not golem.enabled)
			KEY_SPACE:
				orbiting = not orbiting


func _pose(index: int) -> void:
	assert(animator.has_animation(CLIPS[index]), "Missing original Warrior animation")
	animator.get_animation(CLIPS[index]).loop_mode = Animation.LOOP_LINEAR
	animator.play(CLIPS[index], .15)


func _bounds(body: Node3D) -> AABB:
	var result: AABB
	var first: bool = true
	for node: Node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var box: AABB = (body.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		if first:
			result = box
			first = false
		else:
			result = result.merge(box)
	return result


func _accessory(bone: String, asset: String) -> void:
	var skeleton: Skeleton3D = warrior.find_child("Skeleton3D", true, false) as Skeleton3D
	assert(skeleton.find_bone(bone) >= 0, "Warrior hand attachment missing")
	var hand: BoneAttachment3D = BoneAttachment3D.new()
	hand.bone_name = bone
	skeleton.add_child(hand)
	var prop: Node3D = load("res://assets/enemies/warrior_trial/" + asset + ".gltf").instantiate()
	hand.add_child(prop)
	if asset == "skeleton_axe":
		axe = prop
	if "shield" in asset:
		prop.rotation.y = PI
	for node: Node in prop.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		for surface: int in range(mesh.mesh.get_surface_count()):
			mesh.set_surface_override_material(surface, skin)
