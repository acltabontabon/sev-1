extends Control
## Floor map, bottom right: the walkable floor drawn from the baked navigation mesh,
## centred on the engineer and turned with the camera so up is where you are looking.
## Red: hunting you. Orange: patrolling, with the way it is looking. Grey: people (some
## of them are not what they seem). Cyan diamond: the NEXT step. Threats past the edge
## are pinned to the rim, so none is ever off the map.

const SIZE: float = 196.0
## Metres from the centre to the edge.
const RANGE: float = 24.0
## Opaque: the navigation mesh stacks layers (desk tops, the deck) that would double up.
const FLOOR: Color = Color(.17, .28, .34)
const HUNTING: Color = Color(1, .26, .2)
const PATROL: Color = Color(1, .62, .22)
const PEOPLE: Color = Color(.72, .76, .8, .7)
const NEXT: Color = Color(.35, .95, 1)

var incident: Node
var player: Node3D
var floor_mesh: ArrayMesh
var clock: float = 0.0
var turn: float = 0.0
var center: Vector2
var origin: Vector2
var backdrop: StyleBoxFlat
var frame: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -SIZE - 24
	offset_right = -24
	offset_top = -SIZE - 24
	offset_bottom = -24
	clip_contents = true
	backdrop = StyleBoxFlat.new()
	backdrop.bg_color = Color(.015, .03, .04, .82)
	backdrop.border_color = Color(.3, .75, .8, .45)
	backdrop.set_border_width_all(2)
	backdrop.set_corner_radius_all(10)
	frame = backdrop.duplicate()
	frame.draw_center = false


## The navigation mesh flattened to one 2D triangle mesh (x, z), built once.
func _build_floor() -> void:
	var region: NavigationRegion3D = incident.room.get_node_or_null("Navigation")
	if region == null or region.navigation_mesh == null:
		return
	var navigation: NavigationMesh = region.navigation_mesh
	var vertices: PackedVector3Array = navigation.get_vertices()
	var triangles: PackedVector2Array = PackedVector2Array()
	for index in navigation.get_polygon_count():
		var polygon: PackedInt32Array = navigation.get_polygon(index)
		# Skip walkable tops of tall furniture and racks; keep the floor and the deck.
		if vertices[polygon[0]].y > 2.4:
			continue
		for corner in range(1, polygon.size() - 1):
			for vertex in [polygon[0], polygon[corner], polygon[corner + 1]]:
				var point: Vector3 = region.global_transform * vertices[vertex]
				triangles.append(Vector2(point.x, point.z))
	if triangles.is_empty():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = triangles
	floor_mesh = ArrayMesh.new()
	floor_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _process(delta: float) -> void:
	if incident == null or not incident.is_node_ready():
		return
	if player == null:
		player = incident.player
	if floor_mesh == null:
		_build_floor()
	visible = incident.stage != incident.Stage.ALERT and not incident.terminal()
	if not visible:
		return
	clock += delta
	queue_redraw()


## World position to map pixels.
func to_map(at: Vector3) -> Vector2:
	return center + (Vector2(at.x, at.z) - origin).rotated(turn) * (SIZE * .5 / RANGE)


## Keeps a marker inside the frame; returns true when it had to be pinned to the rim.
func _pin(point: Vector2) -> Array:
	var inset: float = 9.0
	var offset: Vector2 = point - center
	var limit: float = SIZE * .5 - inset
	var reach: float = maxf(absf(offset.x), absf(offset.y))
	if reach <= limit:
		return [point, false]
	return [center + offset * (limit / reach), true]


func _draw() -> void:
	if player == null:
		return
	center = Vector2(SIZE, SIZE) * .5
	draw_style_box(backdrop, Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)))
	var view: Basis = player.camera_rig.global_basis
	var forward: Vector2 = Vector2(-view.z.x, -view.z.z)
	turn = -PI * .5 - forward.angle()
	origin = Vector2(player.global_position.x, player.global_position.z)
	var scale_: float = SIZE * .5 / RANGE
	if floor_mesh != null:
		draw_set_transform(center - (origin * scale_).rotated(turn), turn, Vector2(scale_, scale_))
		draw_mesh(floor_mesh, null, Transform2D(), FLOOR)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# People: the overtime crew and the employees a wave is waiting inside.
	var people: Array[Node3D] = []
	if incident.coworkers != null:
		for someone: Dictionary in incident.coworkers.people:
			people.append(someone.body)
	for host: Node3D in incident.hosts + incident.sync_hosts:
		if is_instance_valid(host):
			people.append(host)
	var threats: Array[CharacterBody3D] = []
	for actor: CharacterBody3D in incident.alive + incident.sync_alive + incident.bugs:
		if not is_instance_valid(actor) or actor.health <= 0:
			continue
		if actor.disguised():
			people.append(actor)
		else:
			threats.append(actor)
	if is_instance_valid(incident.boss) and incident.boss.health > 0:
		threats.append(incident.boss)
	for someone: Node3D in people:
		var spot: Array = _pin(to_map(someone.global_position))
		if not spot[1]:
			draw_circle(spot[0], 2.6, PEOPLE)
	# Unaware threats show where they are looking, at the same scale as their sight.
	for actor: CharacterBody3D in threats:
		if actor.awareness in [actor.Awareness.UNAWARE, actor.Awareness.SEARCHING]:
			var at: Vector2 = to_map(actor.global_position)
			if (at - center).length() < SIZE * .75:
				var heading: float = actor.visual.global_rotation.y
				var half: float = deg_to_rad(actor.sight_fov * .5)
				var fan: PackedVector2Array = PackedVector2Array([at])
				for step in range(9):
					var angle: float = heading + lerpf(-half, half, step / 8.0)
					fan.append(to_map(actor.global_position + Vector3(-sin(angle), 0, -cos(angle)) * actor.sight_range))
				draw_colored_polygon(fan, Color(PATROL.r, PATROL.g, PATROL.b, .13))
	var pulse: float = .75 + .25 * sin(clock * 9.0)
	for actor: CharacterBody3D in threats:
		var hunting: bool = actor.awareness in [actor.Awareness.ENGAGED, actor.Awareness.NOTICING]
		var color: Color = HUNTING if hunting else PATROL
		var radius: float = 4.6
		if actor == incident.boss:
			color = Color(1, .3, .9)
			radius = 7.5
		elif incident.bugs.has(actor):
			radius = 2.6
		if hunting:
			color = color * Color(1, 1, 1, pulse)
		var spot: Array = _pin(to_map(actor.global_position))
		if spot[1]:
			radius *= .7
		draw_circle(spot[0], radius + 1.4, Color(0, 0, 0, .6))
		draw_circle(spot[0], radius, color)
	var step: Dictionary = incident.next_step()
	if not step.is_empty() and step.tag != "" and (step.point as Vector3).is_finite() and step.tag != "THREAT":
		var spot: Array = _pin(to_map(step.point))
		var size: float = 6.0
		var diamond: PackedVector2Array = PackedVector2Array([spot[0] + Vector2(0, -size), spot[0] + Vector2(size, 0), spot[0] + Vector2(0, size), spot[0] + Vector2(-size, 0)])
		draw_colored_polygon(diamond, NEXT)
	# The engineer: an arrow along their own facing, relative to the camera.
	var facing: Vector3 = -player.visual.global_basis.z
	var direction: Vector2 = Vector2(facing.x, facing.z).rotated(turn).normalized()
	var side: Vector2 = Vector2(-direction.y, direction.x)
	var arrow: PackedVector2Array = PackedVector2Array([center + direction * 8.0, center - direction * 5.0 + side * 5.5, center - direction * 2.5, center - direction * 5.0 - side * 5.5])
	draw_colored_polygon(arrow, Color(.85, 1, 1))
	draw_style_box(frame, Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)))
