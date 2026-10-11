extends SceneTree
## Actual office/Forward+ review: impacts, sword ribbon and magic; 0 reset, Esc exit.
var scene: Node3D
var camera: Camera3D
var emitter: Node3D
var trail: MeshInstance3D
var hold_trail: bool = false
var caption: Label


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.msaa_3d = Viewport.MSAA_2X
	root.window_input.connect(_on_input)
	physics_frame.connect(func() -> void:
		if is_instance_valid(trail) and not trail.emitting and not hold_trail:
			trail.sample())
	scene = load("res://game/main.tscn").instantiate()
	scene.set_script(null)
	for child: Node in scene.get_children():
		if child.name not in [&"OfficeAfterHours", &"WorldEnvironment", &"KeyLight"]:
			scene.remove_child(child)
			child.free()
	root.add_child(scene)
	current_scene = scene
	trail = MeshInstance3D.new()
	trail.set_script(load("res://game/player/weapon_trail.gd"))
	scene.add_child(trail)
	trail.source = Node3D.new()
	scene.add_child(trail.source)
	trail.source.position = Vector3(0, 1, 3.5)
	emitter = Node3D.new()
	scene.add_child(emitter)
	var engineer: Node3D = load("res://game/player/rigged_engineer.tscn").instantiate()
	scene.add_child(engineer)
	engineer.position = Vector3(-1.8, .05, 4)
	engineer.set_physics_process(false)
	camera = Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0, 3.5, 10)
	camera.look_at(Vector3(0, .5, 3.5))
	camera.fov = 65.0
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var hud: CanvasLayer = CanvasLayer.new()
	scene.add_child(hud)
	caption = Label.new()
	caption.position = Vector2(30, 25)
	caption.add_theme_font_size_override("font_size", 22)
	caption.text = "SEV-1 · IMPACT EFFECT REVIEW\n1 earthquake · 2 shockwave · 3 upright · 4 sword trail · 5 magic · 0 reset · Esc close"
	hud.add_child(caption)
	for index in range(60):
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		hold_trail = true
		for kind in ["baseline", "quake", "shockwave", "upright", "sword", "magic"]:
			ElementFx.clear_from(emitter)
			trail.clear()
			if kind != "baseline":
				await _fire(kind)
				await create_timer(.02 if kind == "sword" else .14).timeout
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://builds")
			root.get_texture().get_image().save_png("res://builds/effect_" + kind + ".png")
			print("CAPTURE effect_", kind)
			if kind == "quake":
				await create_timer(.26).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://builds/effect_quake_dust.png")
		quit()
	if "--benchmark" in OS.get_cmdline_user_args() or "--soft-benchmark" in OS.get_cmdline_user_args():
		var soft_benchmark: bool = "--soft-benchmark" in OS.get_cmdline_user_args()
		var times: Array[float] = []
		var previous: int = Time.get_ticks_usec()
		for index in range(240):
			if index % 30 == 0:
				if soft_benchmark:
					_fire("magic")
					_fire("sword")
				else:
					_fire("quake")
			await process_frame
			var now: int = Time.get_ticks_usec()
			times.append((now - previous) / 1000.0)
			previous = now
		times.sort()
		print("FRAME TIMES: median %.2f ms, p95 %.2f ms (240 frames; office %s every 30 frames)" % [times[120], times[228], "magic + sword" if soft_benchmark else "quake"])
		quit()


func _fire(kind: String) -> void:
	var at: Vector3 = Vector3(0, .05, 3.5)
	var color: Color = Color(.58, .2, .12)
	if kind == "sword":
		trail.clear()
		trail.emitting = true
		for step in range(14):
			trail.source.rotation.y = lerpf(-1.0, 1.0, step / 13.0)
			trail.sample()
			await physics_frame
		trail.emitting = false
	elif kind == "magic":
		ElementFx.sigil(emitter, at, Color(.3, .7, 1), 2.2, 1.2)
		ElementFx.gust(emitter, at + Vector3.UP, Basis.IDENTITY, Color(.5, .8, 1), 2.0, .8)
		ElementFx.bolt(emitter, at + Vector3(-1.5, 1.5, 0), at + Vector3(1.5, 1.5, 0), Color(.4, .65, 1), .7, .09)
		ElementFx.motes(emitter, at + Vector3.UP, Color(.3, .7, 1), 28, 2.0, 1.0, 0.0, .25)
	elif kind == "quake":
		ElementFx.quake(emitter, at, color, 2.4)
	else:
		ElementFx.shockwave(emitter, at, color, 3.2, .55, kind == "upright")


func _on_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				quit()
			KEY_0:
				ElementFx.clear_from(emitter)
				trail.clear()
			KEY_1:
				_fire("quake")
			KEY_2:
				_fire("shockwave")
			KEY_3:
				_fire("upright")
			KEY_4:
				_fire("sword")
			KEY_5:
				_fire("magic")
