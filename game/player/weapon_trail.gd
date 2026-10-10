extends MeshInstance3D
## Ribbon left by the keyboard's edge while a swing is live. Presentation only: it samples
## two points on the weapon each physics tick and fades the oldest samples out.

@export var samples: int = 12
@export var base_offset: Vector3 = Vector3(0, 0, -.45)
@export var tip_offset: Vector3 = Vector3(0, 0, -1.47)
var color: Color = Color(.3, .95, 1)
var emitting: bool = false
var points: Array[PackedVector3Array] = []
var source: Node3D
var material: StandardMaterial3D


func _ready() -> void:
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = ImmediateMesh.new()
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = false


func clear() -> void:
	points.clear()
	emitting = false
	(mesh as ImmediateMesh).clear_surfaces()


func sample() -> void:
	if source == null:
		return
	global_transform = Transform3D.IDENTITY
	if emitting:
		points.push_front(PackedVector3Array([source.global_transform * base_offset, source.global_transform * tip_offset]))
	elif not points.is_empty():
		points.pop_back()
	while points.size() > samples:
		points.pop_back()
	var immediate: ImmediateMesh = mesh as ImmediateMesh
	immediate.clear_surfaces()
	if points.size() < 2:
		return
	immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
	for index in range(points.size()):
		var fade: float = 1.0 - float(index) / float(points.size() - 1)
		immediate.surface_set_color(Color(color.r, color.g, color.b, 0.0))
		immediate.surface_add_vertex(points[index][0])
		immediate.surface_set_color(Color(color.r, color.g, color.b, .85 * fade * fade))
		immediate.surface_add_vertex(points[index][1])
	immediate.surface_end()
