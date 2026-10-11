extends SceneTree
## Outcome checks: camera tracking, comfort, bounded overlap, reset and expiry.

class ComfortRig extends Node3D:
	var impulse_degrees: float = .8
	func add_tremor(_strength: float) -> void:
		pass

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func _run() -> void:
	var emitter: Node3D = Node3D.new()
	root.add_child(emitter)
	var player: Node3D = Node3D.new()
	emitter.add_child(player)
	player.add_to_group("players")
	var comfort: ComfortRig = ComfortRig.new()
	comfort.name = "CameraRig"
	player.add_child(comfort)
	var camera: Camera3D = Camera3D.new()
	emitter.add_child(camera)
	camera.position = Vector3(0, 3, 6)
	camera.look_at(Vector3.ZERO)
	camera.make_current()
	var wave: ElementFx = ElementFx.shockwave(emitter, Vector3.ZERO, Color(.6, .18, .1), 3.0, .5)
	var pass_: ShockwaveDistortion = root.get_node("ShockwaveDistortion")
	wave.age = .1
	pass_._update()
	check(pass_.visible, "visible impact produces distortion")
	var original: PackedVector4Array = pass_.material.get_shader_parameter("waves")
	camera.position.x = 2.0
	pass_._update()
	var moved: PackedVector4Array = pass_.material.get_shader_parameter("waves")
	check(absf(moved[0].x - original[0].x) > .05, "pulse tracks its world origin as the camera moves")
	root.size = Vector2i(960, 960)
	pass_._update()
	var resized: PackedVector4Array = pass_.material.get_shader_parameter("waves")
	var center: Vector2 = camera.unproject_position(wave.global_position) / root.get_visible_rect().size
	check(Vector2(resized[0].x, resized[0].y).distance_to(center) < .001, "resizing keeps the pulse at its projected impact")
	comfort.impulse_degrees = 0.0
	pass_._update()
	check(not pass_.visible and is_instance_valid(wave), "zero camera shake disables distortion while retaining world effects")
	comfort.impulse_degrees = .8
	camera.rotation.y += PI
	pass_._update()
	check(not pass_.visible, "impacts behind the camera do not distort the screen")
	camera.look_at(Vector3.ZERO)
	for index in range(8):
		ElementFx.shockwave(emitter, Vector3.ZERO, Color(.6, .18, .1), 3.0, .5)
	check(pass_.pulses.size() == 4 and root.find_children("ShockwaveDistortion", "", false, false).size() == 1, "overlapping attacks use one pass with at most four pulses")
	ElementFx.quake(emitter, Vector3.ZERO, Color(.6, .18, .1), 2.4)
	ElementFx.clear_from(emitter)
	check(pass_.pulses.is_empty() and not pass_.visible, "retry immediately clears every distortion and dust source")
	ElementFx.shockwave(emitter, Vector3.ZERO, Color.WHITE, 2.0, .05)
	for index in range(12):
		await process_frame
	check(pass_.pulses.is_empty() and not pass_.visible and not pass_.is_processing(), "expired pulses leave no visible or processing screen pass")
	emitter.queue_free()
	await process_frame
	pass_.queue_free()
	quit(1 if failures else 0)
