extends SceneTree
## Rendered outcome checks: the real sword ribbon feathers and fades after emission.
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func capture() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func energy(image: Image) -> float:
	var sum: float = 0.0
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			sum += image.get_pixel(x, y).r
	return sum


func _run() -> void:
	root.size = Vector2i(640, 480)
	var world: Node3D = Node3D.new()
	root.add_child(world)
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	world.add_child(environment)
	var camera: Camera3D = Camera3D.new()
	world.add_child(camera)
	camera.position.z = 6
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4
	camera.make_current()
	var source: Node3D = Node3D.new()
	world.add_child(source)
	var trail = load("res://game/player/weapon_trail.gd").new()
	world.add_child(trail)
	trail.source = source
	trail.base_offset = Vector3(-1, 0, 0)
	trail.tip_offset = Vector3(1, 0, 0)
	trail.color = Color.WHITE
	trail.fade_seconds = .5
	trail.emitting = true
	for step in range(14):
		source.position.y = lerpf(-1.0, 1.0, step / 13.0)
		trail.sample()
		await physics_frame
	trail.emitting = false
	var bright: Image = await capture()
	var peak: float = 0.0
	for x in range(bright.get_width()):
		peak = maxf(peak, bright.get_pixel(x, bright.get_height() / 2).r)
	var feather_pixels: int = 0
	for x in range(bright.get_width()):
		var value: float = bright.get_pixel(x, bright.get_height() / 2).r
		if value > peak * .05 and value < peak * .8:
			feather_pixels += 1
	check(peak > .1 and feather_pixels > 20, "sword ribbon renders a visible core with broad intermediate edge shades")
	var initial: float = energy(bright)
	for step in range(12):
		await physics_frame
		trail.sample()
	var fading: Image = await capture()
	check(energy(fading) > 0.0 and energy(fading) < initial * .85, "stopped sword ribbon visibly dims before disappearing")
	for step in range(35):
		await physics_frame
		trail.sample()
	check(energy(await capture()) < .01, "stopped sword ribbon leaves no rendered residue")
	trail.emitting = true
	for step in range(3):
		source.position.y = step * .3
		trail.sample()
	trail.clear()
	check(energy(await capture()) < .01, "reset immediately clears the rendered sword ribbon")
	var spell: ElementFx = ElementFx.sigil(world, Vector3.ZERO, Color.WHITE, 1.5, 1.0)
	spell.set_process(false)
	(spell.get_child(0) as MeshInstance3D).rotation.x = PI * .5
	spell.on_tick.call(.3)
	check(energy(await capture()) > 10.0, "soft spell circle remains visible while active")
	spell.on_tick.call(1.0)
	check(energy(await capture()) < .01, "spell circle smoothly reaches a fully transparent end")
	ElementFx.clear_from(world)
	var wave: ElementFx = ElementFx.shockwave(world, Vector3.ZERO, Color.WHITE, 1.5, 1.0, true)
	wave.set_process(false)
	wave.on_tick.call(.3)
	var ring: Image = await capture()
	check(energy(ring) > 10.0, "textured soft shockwave remains visible")
	wave.on_tick.call(1.0)
	check(energy(await capture()) < .01, "soft shockwave reaches a fully transparent end")
	ElementFx.clear_from(world)
	world.free()
	quit(1 if failures else 0)
