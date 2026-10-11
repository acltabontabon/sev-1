extends SceneTree
## Graphical regression: preserve battle grading and HUD, distort only the wave band.

class Pattern extends Control:
	func _draw() -> void:
		for x in range(0, int(size.x), 24):
			for y in range(0, int(size.y), 24):
				var shade: float = .18 if (x / 24 + y / 24) % 2 == 0 else .55
				draw_rect(Rect2(x, y, 24, 24), Color(shade, shade * .8, shade * .7))

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func capture() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var background: CanvasLayer = CanvasLayer.new()
	background.layer = -2
	root.add_child(background)
	var pattern: Pattern = Pattern.new()
	pattern.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.add_child(pattern)
	var battle: CanvasLayer = CanvasLayer.new()
	battle.layer = -1
	root.add_child(battle)
	var grade: ColorRect = ColorRect.new()
	grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://game/incidents/battle_overlay.gdshader")
	material.set_shader_parameter("vignette", .5)
	grade.material = material
	battle.add_child(grade)
	var hud: CanvasLayer = CanvasLayer.new()
	root.add_child(hud)
	var marker: ColorRect = ColorRect.new()
	marker.position = Vector2(20, 20)
	marker.size = Vector2(180, 50)
	marker.color = Color(.8, .1, .05)
	hud.add_child(marker)
	var emitter: Node3D = Node3D.new()
	root.add_child(emitter)
	var camera: Camera3D = Camera3D.new()
	emitter.add_child(camera)
	camera.position = Vector3(0, 0, 6)
	camera.look_at(Vector3.ZERO)
	camera.make_current()
	for index in range(30):
		await process_frame
	var baseline: Image = await capture()
	var wave: ElementFx = ElementFx.shockwave(emitter, Vector3.ZERO, Color.BLACK, 3.0, 1.0)
	wave.set_process(false)
	# Hide the world ring to isolate the screen shader's rendered contribution.
	(wave.get_child(0) as MeshInstance3D).hide()
	wave.age = .2
	var pass_: ShockwaveDistortion = root.get_node("ShockwaveDistortion")
	pass_._update()
	var image_: Image = await capture()
	var changed: int = 0
	var far_changed: int = 0
	for x in range(0, image_.get_width(), 3):
		for y in range(0, image_.get_height(), 3):
			var delta: Color = image_.get_pixel(x, y) - baseline.get_pixel(x, y)
			if maxf(absf(delta.r), maxf(absf(delta.g), absf(delta.b))) > .025:
				changed += 1
				if x < image_.get_width() * .12 or x > image_.get_width() * .88:
					far_changed += 1
	check(changed > 30, "shockwave shader visibly refracts the rendered background")
	check(far_changed == 0, "outside the pulse band the earlier battle grade is preserved")
	check(image_.get_pixel(80, 40).is_equal_approx(baseline.get_pixel(80, 40)), "HUD marker stays pixel-identical during distortion")
	ElementFx.clear_from(emitter)
	var cleared: Image = await capture()
	check(cleared.get_pixel(640, 360).is_equal_approx(baseline.get_pixel(640, 360)), "clearing effects restores the original rendered scene")
	# Reproduce shutdown ordering: layer exits before its source.
	ElementFx.shockwave(emitter, Vector3.ZERO, Color.BLACK, 3.0)
	root.remove_child(pass_)
	emitter.free()
	pass_.free()
	quit(1 if failures else 0)
