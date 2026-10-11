class_name ShockwaveDistortion
extends CanvasLayer
## One bounded screen pass per viewport; sources own the lifetime of their pulses.
## Layer 0 samples the battle grade (-1) but leaves the HUD (1+) untouched.

const SHADER: Shader = preload("res://game/combat/shockwave_distortion.gdshader")
const MAX_PULSES: int = 4
var pulses: Array[Dictionary] = []
var material: ShaderMaterial
var overlay: ColorRect


static func emit(source: Node3D, radius: float) -> void:
	var viewport: Viewport = source.get_viewport()
	var pass_: ShockwaveDistortion = viewport.get_node_or_null("ShockwaveDistortion") as ShockwaveDistortion
	if pass_ == null:
		pass_ = ShockwaveDistortion.new()
		pass_.name = "ShockwaveDistortion"
		viewport.add_child(pass_)
	pass_._add(source, radius)


func _ready() -> void:
	layer = 0
	# Explicitly sample earlier screen-reading effects, including the battle grade.
	var copy: BackBufferCopy = BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)
	material = ShaderMaterial.new()
	material.shader = SHADER
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.material = material
	add_child(overlay)
	hide()
	set_process(false)


func _add(source: Node3D, radius: float) -> void:
	if pulses.size() == MAX_PULSES:
		pulses.pop_front()
	var id: int = source.get_instance_id()
	pulses.append({"source": weakref(source), "id": id, "radius": radius})
	source.tree_exiting.connect(_remove.bind(id), CONNECT_ONE_SHOT)
	set_process(true)
	_update()


func _remove(id: int) -> void:
	for index in range(pulses.size() - 1, -1, -1):
		if pulses[index].id == id:
			pulses.remove_at(index)
	_update()
	if pulses.is_empty():
		set_process(false)


func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	# Source exit signals may arrive after this layer has left the viewport on quit.
	if not is_inside_tree():
		return
	var waves: PackedVector4Array = PackedVector4Array()
	waves.resize(MAX_PULSES)
	var camera: Camera3D = get_viewport().get_camera_3d()
	var size: Vector2 = get_viewport().get_visible_rect().size
	var active: int = 0
	if camera != null and size.x > 0.0 and size.y > 0.0:
		for pulse: Dictionary in pulses:
			var source: Node3D = pulse.source.get_ref() as Node3D
			if source == null or not source.is_inside_tree() or camera.is_position_behind(source.global_position):
				continue
			var center: Vector2 = camera.unproject_position(source.global_position) / size
			if not Rect2(-.1, -.1, 1.2, 1.2).has_point(center):
				continue
			var comfort: float = 1.0
			var player: Node = get_tree().get_first_node_in_group("players")
			if player != null and player.has_node("CameraRig"):
				comfort = clampf(float(player.get_node("CameraRig").get("impulse_degrees")) / .8, 0.0, 1.0)
			if comfort <= 0.0:
				continue
			var t: float = clampf(float(source.get("age")) / maxf(.01, float(source.get("life"))), 0.0, 1.0)
			var edge: Vector3 = source.global_position + camera.global_basis.x * float(pulse.radius)
			var reach: float = camera.unproject_position(edge).distance_to(center * size) / size.x
			var spread: float = lerpf(.1, 1.0, ease(t, .35))
			var strength: float = .003 * comfort * pow(1.0 - t, 2.0) * minf(1.0, reach * 8.0)
			waves[active] = Vector4(center.x, center.y, reach * spread, strength)
			active += 1
	material.set_shader_parameter("waves", waves)
	material.set_shader_parameter("wave_count", active)
	visible = active > 0
