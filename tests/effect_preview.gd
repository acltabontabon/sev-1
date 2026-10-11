extends SceneTree
## Actual office/Forward+ review: 1 quake, 2 ring, 3 upright ring, 0 reset, Esc exit.
var scene: Node3D
var camera: Camera3D
var emitter: Node3D
var caption: Label


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.msaa_3d = Viewport.MSAA_2X
	root.window_input.connect(_on_input)
	scene = load("res://game/main.tscn").instantiate()
	scene.set_script(null)
	for child: Node in scene.get_children():
		if child.name not in [&"OfficeAfterHours", &"WorldEnvironment", &"KeyLight"]:
			scene.remove_child(child)
			child.free()
	root.add_child(scene)
	current_scene = scene
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
	caption.text = "SEV-1 · IMPACT EFFECT REVIEW\n1 earthquake · 2 shockwave · 3 upright · 0 reset · Esc close"
	hud.add_child(caption)
	for index in range(60):
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		for kind in ["baseline", "quake", "shockwave", "upright"]:
			ElementFx.clear_from(emitter)
			if kind != "baseline":
				_fire(kind)
				await create_timer(.14).timeout
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://builds")
			root.get_texture().get_image().save_png("res://builds/effect_" + kind + ".png")
			print("CAPTURE effect_", kind)
			if kind == "quake":
				await create_timer(.26).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://builds/effect_quake_dust.png")
		quit()
	if "--benchmark" in OS.get_cmdline_user_args():
		var times: Array[float] = []
		var previous: int = Time.get_ticks_usec()
		for index in range(240):
			if index % 30 == 0:
				_fire("quake")
			await process_frame
			var now: int = Time.get_ticks_usec()
			times.append((now - previous) / 1000.0)
			previous = now
		times.sort()
		print("FRAME TIMES: median %.2f ms, p95 %.2f ms (240 frames; office quake every 30 frames)" % [times[120], times[228]])
		quit()


func _fire(kind: String) -> void:
	var at: Vector3 = Vector3(0, .05, 3.5)
	var color: Color = Color(.58, .2, .12)
	if kind == "quake":
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
			KEY_1:
				_fire("quake")
			KEY_2:
				_fire("shockwave")
			KEY_3:
				_fire("upright")
