extends MeshInstance3D
## Ribbon left by the keyboard's edge while a swing is live. Presentation only: it samples
## two points on the weapon each physics tick and fades the oldest samples out.

const TRACE_TEXTURE: Texture2D = preload("res://assets/effects/kenney_particles/soft_trace.png")

@export var samples: int = 14
@export var fade_seconds: float = .22
@export var base_offset: Vector3 = Vector3(0, 0, -.6)
@export var tip_offset: Vector3 = Vector3(0, 0, -2.3)
var color: Color = Color(.3, .95, 1)
var emitting: bool = false
var points: Array[PackedVector3Array] = []
var ages: Array[float] = []
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
	material.albedo_texture = TRACE_TEXTURE
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.texture_repeat = false
	material.no_depth_test = false


func clear() -> void:
	points.clear()
	ages.clear()
	emitting = false
	(mesh as ImmediateMesh).clear_surfaces()


func sample() -> void:
	if source == null:
		return
	global_transform = Transform3D.IDENTITY
	for index in range(ages.size()):
		ages[index] += get_physics_process_delta_time()
	if emitting:
		points.push_front(PackedVector3Array([source.global_transform * base_offset, source.global_transform * tip_offset]))
		ages.push_front(0.0)
	while not points.is_empty() and (points.size() > samples or ages.back() >= maxf(.01, fade_seconds)):
		points.pop_back()
		ages.pop_back()
	var immediate: ImmediateMesh = mesh as ImmediateMesh
	immediate.clear_surfaces()
	if points.size() < 2:
		return
	immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
	for index in range(points.size()):
		var along: float = float(index) / float(points.size() - 1)
		var fade: float = (1.0 - smoothstep(0.0, 1.0, along)) * (1.0 - smoothstep(0.0, maxf(.01, fade_seconds), ages[index])) * .85
		immediate.surface_set_uv(Vector2(.32, along))
		immediate.surface_set_color(Color(color.r, color.g, color.b, fade))
		immediate.surface_add_vertex(points[index][0])
		immediate.surface_set_uv(Vector2(.68, along))
		immediate.surface_set_color(Color(color.r, color.g, color.b, fade).lerp(Color(1, 1, 1, fade), .25 * fade))
		immediate.surface_add_vertex(points[index][1])
	immediate.surface_end()
