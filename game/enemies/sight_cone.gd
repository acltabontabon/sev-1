extends MeshInstance3D
## What an enemy can see, painted on the floor: a fan of rays across its field of view,
## each cut short by walls and furniture. Red while it is unaware, orange while it is
## noticing, amber while it searches; hidden once it is chasing or dead. Presentation of
## the exact rule `_senses()` uses, so sneaking around it is honest.

const RAYS: int = 22
var actor: CharacterBody3D
var refresh_left: float = 0.0
var material: StandardMaterial3D


func _ready() -> void:
	actor = get_parent() as CharacterBody3D
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = ImmediateMesh.new()
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Added light, not a painted surface: a flat fill read as cardboard on the carpet.
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.render_priority = -1
	# Stagger rebuilds so a wave does not cast all its rays on the same frame.
	refresh_left = randf() * .15


func _physics_process(delta: float) -> void:
	if actor == null or not actor.is_inside_tree():
		return
	var tint: Color = _tint()
	visible = tint.a > 0.0
	if not visible:
		return
	global_position = Vector3(actor.global_position.x, actor.global_position.y + .06, actor.global_position.z)
	global_rotation = Vector3.ZERO
	refresh_left -= delta
	if refresh_left > 0:
		return
	refresh_left = .15
	_rebuild(tint)


func _tint() -> Color:
	if actor.health <= 0 or not actor.visible:
		return Color(0, 0, 0, 0)
	match actor.awareness:
		actor.Awareness.UNAWARE:
			# Red reads as danger; warm yellow on blue carpet read as cardboard.
			return Color(1, .22, .18, .16)
		actor.Awareness.NOTICING:
			return Color(1, .55, .1, .38)
		actor.Awareness.SEARCHING:
			return Color(1, .4, .12, .26)
	return Color(0, 0, 0, 0)


func _rebuild(tint: Color) -> void:
	var space: PhysicsDirectSpaceState3D = actor.get_world_3d().direct_space_state
	var heading: float = actor.visual.rotation.y
	var half: float = deg_to_rad(actor.sight_fov * .5)
	var eye: Vector3 = actor.global_position + Vector3.UP * 1.0
	var reach: PackedFloat32Array = PackedFloat32Array()
	for index in range(RAYS + 1):
		var angle: float = heading + lerpf(-half, half, float(index) / RAYS)
		var direction: Vector3 = Vector3(-sin(angle), 0, -cos(angle))
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(eye, eye + direction * actor.sight_range, 1)
		query.exclude = [actor.get_rid()]
		var hit: Dictionary = space.intersect_ray(query)
		reach.append(eye.distance_to(hit.position) if not hit.is_empty() else actor.sight_range)
	var immediate: ImmediateMesh = mesh as ImmediateMesh
	immediate.clear_surfaces()
	immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	# A whisper of fill near the eyes, and a clear outline where sight ends: a boundary to
	# stay outside of, not a coloured patch of floor.
	var fill: Color = Color(tint.r, tint.g, tint.b, tint.a * .45)
	var clear: Color = Color(tint.r, tint.g, tint.b, 0.0)
	var line: Color = Color(tint.r, tint.g, tint.b, minf(1.0, tint.a * 3.2))
	var points: PackedVector3Array = PackedVector3Array()
	for index in range(RAYS + 1):
		var angle: float = heading + lerpf(-half, half, float(index) / RAYS)
		points.append(Vector3(-sin(angle), 0, -cos(angle)) * reach[index])
	for index in range(RAYS):
		_triangle(immediate, [fill, clear, clear], [Vector3.ZERO, points[index] * .7, points[index + 1] * .7])
		_strip(immediate, line, points[index], points[index + 1], .07)
	_strip(immediate, line, Vector3.ZERO, points[0], .05)
	_strip(immediate, line, Vector3.ZERO, points[RAYS], .05)
	immediate.surface_end()


func _triangle(immediate: ImmediateMesh, colors: Array, corners: Array) -> void:
	for index in range(3):
		immediate.surface_set_color(colors[index])
		immediate.surface_add_vertex(corners[index])


## A flat band from a to b on the floor, `width` wide, for the cone's outline.
func _strip(immediate: ImmediateMesh, color: Color, a: Vector3, b: Vector3, width: float) -> void:
	var across: Vector3 = (b - a).cross(Vector3.UP).normalized() * width * .5
	var soft: Color = Color(color.r, color.g, color.b, color.a * .2)
	_triangle(immediate, [color, color, soft], [a, b, b + across])
	_triangle(immediate, [color, soft, soft], [a, b + across, a + across])
	_triangle(immediate, [color, soft, color], [a, b - across, b])
	_triangle(immediate, [color, soft, soft], [a, a - across, b - across])

