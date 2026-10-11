extends SceneTree
## Isolated art comparison. No encounters, progression, damage or save writes.
var scene: Node3D
var camera: Camera3D
var angle: float = 0.0
var orbiting: bool = false
var comparison: bool = true
var trail_clock: float = 0.0
var trail_sample: float = 0.0
var trail_tracks: Array[Dictionary] = []
var trail_skeleton: Skeleton3D
var reference: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.title = "SEV-1 · The Variance red Demon"
	root.window_input.connect(_on_input)
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
	player.camera_rig.set_process(false)
	player.camera_rig.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	reference = load("res://game/enemies/incident.tscn").instantiate()
	reference.rig_kind = "variance"
	reference.bark_kind = ""
	reference.position = Vector3(7, .05, -40)
	scene.add_child(reference)
	reference.set_physics_process(false)
	reference.visual.set_physics_process(false)
	reference.rig.set_physics_process(false)
	reference.rig.model.rotation.y = 0.0
	for mesh: MeshInstance3D in reference.rig.meshes:
		for surface: int in range(mesh.mesh.get_surface_count()):
			mesh.set_surface_override_material(surface, null)
	reference.label.text = "THE VARIANCE · RED DEMON"
	reference.label.position.y = 4.05
	var current_idle: String = reference.rig.clips["idle"]
	reference.rig.animator.play(current_idle)
	reference.rig.animator.seek(.5, true)
	reference.rig.animator.pause()
	var attack_clip: String = reference.rig.clips["attack"]
	reference.rig.animator.get_animation(attack_clip).loop_mode = Animation.LOOP_LINEAR
	reference.rig.animator.play(attack_clip, 0.0)
	_add_aura()
	_add_wisps()
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
	caption.text = "THE VARIANCE · RED DEMON\n1 comparison · 2 close-up · A looping weapon attack · I idle · F front · B back · Space orbit · Esc close"
	layer.add_child(caption)
	for index in range(90):
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await _capture("red_demon_vault_comparison")
		comparison = false
		_frame()
		for index in range(10):
			await process_frame
		await _capture("red_demon_vault_closeup")
		reference.rig.animator.play(reference.rig.clips["attack"], 0.0)
		reference.rig.animator.advance(0.0)
		reference.rig.animator.seek(.45, true)
		reference.rig.animator.pause()
		for index in range(10):
			await process_frame
		await _capture("red_demon_vault_attack")
		quit()


func _process(delta: float) -> bool:
	if reference != null and reference.rig != null:
		reference.rig.animator.advance(delta)
	_update_trails(delta)
	if orbiting and camera != null:
		angle += delta * .25
		_frame()
	return false


func _frame() -> void:
	var center: Vector3 = Vector3(9, 2.0, -40) if comparison else reference.position + Vector3(0, 1.8, 0)
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
			KEY_A, KEY_I:
				reference.rig.animator.play(reference.rig.clips["attack" if event.keycode == KEY_A else "idle"], 0.0)
			KEY_F, KEY_B:
				reference.rig.model.rotation.y = 0.0 if event.keycode == KEY_F else PI
			KEY_SPACE:
				orbiting = not orbiting


func _add_aura() -> void:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_front, blend_add, depth_draw_never, shadows_disabled;
uniform float expansion = 0.02;
uniform float opacity = 0.015;
void vertex() {
	float unease = 1.0 + 0.16 * sin(VERTEX.y * 4.5 + TIME * 0.9) + 0.08 * sin(VERTEX.x * 7.0 - TIME * 1.3);
	VERTEX += NORMAL * expansion * unease;
}
void fragment() {
	float pulse = 0.72 + 0.18 * sin(TIME * 0.85) + 0.10 * sin(TIME * 2.1 + 1.4);
	ALBEDO = vec3(0.38, 0.012, 0.85) * pulse;
	ALPHA = opacity * pulse;
}
"""
	# Layer faint expanded silhouettes: the inner edge is gentle, and the
	# cumulative glow falls smoothly to zero toward the outer boundary.
	var first: ShaderMaterial
	var previous: ShaderMaterial
	for index: int in range(16):
		var fraction: float = float(index + 1) / 16.0
		var layer: ShaderMaterial = ShaderMaterial.new()
		layer.shader = shader
		layer.set_shader_parameter("expansion", .008 + .12 * fraction)
		layer.set_shader_parameter("opacity", .024 * pow(1.0 - fraction, 1.5))
		if previous != null:
			previous.next_pass = layer
		else:
			first = layer
		previous = layer
	for mesh: MeshInstance3D in reference.rig.meshes:
		for surface: int in range(mesh.mesh.get_surface_count()):
			var source: Material = mesh.mesh.surface_get_material(surface)
			if source != null:
				var skin: Material = source.duplicate()
				skin.next_pass = first
				mesh.set_surface_override_material(surface, skin)


func _add_wisps() -> void:
	for node: Node in reference.rig.model.find_children("*", "Skeleton3D", true, false):
		trail_skeleton = node as Skeleton3D
		break
	assert(trail_skeleton != null)
	var shader: Shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;
uniform sampler2D trace_texture : filter_linear_mipmap, repeat_disable;
void vertex() {
	float age = UV.y;
	VERTEX.x += sin(TIME * 0.9 + age * 8.0) * 0.11 * age;
	VERTEX.y += 0.16 * age;
	VERTEX.z += cos(TIME * 0.7 + age * 5.0) * 0.06 * age;
}
void fragment() {
	float texture_fade = texture(trace_texture, vec2(mix(0.32, 0.68, UV.x), UV.y)).a;
	float edge = pow(max(sin(UV.x * 3.14159), 0.0), 1.5);
	float fade = pow(1.0 - UV.y, 1.8);
	ALBEDO = vec3(0.48, 0.012, 0.85);
	ALPHA = edge * fade * texture_fade * 0.27;
}
"""
	for bone_name: String in ["LowerArm.L", "LowerArm.R", "Torso"]:
		var bone: int = trail_skeleton.find_bone(bone_name)
		assert(bone >= 0)
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("trace_texture", load("res://assets/effects/kenney_particles/soft_trace.png"))
		var ribbon: MeshInstance3D = MeshInstance3D.new()
		ribbon.name = "TrailingAura" + bone_name
		ribbon.material_override = material
		ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		scene.add_child(ribbon)
		trail_tracks.append({"bone": bone, "mesh": ribbon, "points": []})


func _update_trails(delta: float) -> void:
	if trail_skeleton == null or camera == null:
		return
	trail_clock += delta
	trail_sample += delta
	if trail_sample < .025:
		return
	trail_sample = 0.0
	for track: Dictionary in trail_tracks:
		var pose: Transform3D = trail_skeleton.global_transform * trail_skeleton.get_bone_global_pose(track.bone)
		var points: Array = track.points
		points.push_front({"position": pose.origin, "time": trail_clock})
		while not points.is_empty() and trail_clock - points.back().time > .95:
			points.pop_back()
		if points.size() < 2:
			continue
		var tool: SurfaceTool = SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index: int in range(points.size() - 1):
			var from: Vector3 = points[index].position
			var to: Vector3 = points[index + 1].position
			if from.distance_squared_to(to) < .00001:
				continue
			var across: Vector3 = (to - from).cross(camera.global_position - from).normalized()
			for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
				var point: Dictionary = points[index + int(corner.y)]
				var age: float = clampf((trail_clock - point.time) / .95, 0.0, 1.0)
				var width: float = lerpf(.22, .025, age)
				tool.set_uv(Vector2(corner.x, age))
				tool.add_vertex(point.position + across * (corner.x - .5) * width)
		track.mesh.mesh = tool.commit()
