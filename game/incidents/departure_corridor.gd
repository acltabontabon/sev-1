extends Node3D
## Local departure staging: continuous strides, recalled voices and an opening doorway.
const THRESHOLD: float = 9.8
const STRIDE_SPEED: float = 1.15
var walk_from: Vector3
var walk_to: Vector3
var duration: float = 0.0
var door_open: float = 0.0


func _ready() -> void:
	# Reuse the actual company mark, rather than inventing another logo for the ending.
	var source: Node3D = get_parent().room.get_node("CompanyLogo")
	var logo: Node3D = source.duplicate()
	logo.name = "DepartureLogo"
	add_child(logo)
	logo.position = Vector3(9.54, 3.08, 0)
	logo.rotation = Vector3(0, -PI * .5, 0)
	logo.scale = Vector3.ONE * .45
	for label: Label3D in logo.find_children("*", "Label3D", true, false):
		label.visible = label.name == "Wordmark"
	var word: Label3D = logo.get_node("Wordmark")
	word.outline_size = 4
	word.no_depth_test = false
	for panel: MeshInstance3D in [get_node("LiftDoorLeft"), get_node("LiftDoor1")]:
		var solid: StaticBody3D = StaticBody3D.new()
		var shape: CollisionShape3D = CollisionShape3D.new()
		var bounds: BoxShape3D = BoxShape3D.new()
		bounds.size = Vector3(.08, 2.96, 1.34)
		shape.shape = bounds
		solid.add_child(shape)
		panel.add_child(solid)
	# A small night-city backdrop prevents the opening from looking into an empty sky.
	for index in range(3):
		var tower: MeshInstance3D = get_parent().room.get_node("CityTower%d" % index).duplicate()
		add_child(tower)
		tower.position = Vector3(32 + index * 3, 3.0, -10 + index * 10)
		tower.rotation = Vector3.ZERO
		tower.scale = Vector3(.4, .15, .4)
	var pavement: MeshInstance3D = MeshInstance3D.new()
	var ground: BoxMesh = BoxMesh.new()
	ground.size = Vector3(24, .12, 24)
	pavement.mesh = ground
	pavement.material_override = get_node("Floor").material_override
	pavement.position = Vector3(28, -.06, 0)
	add_child(pavement)
	set_door(0.0)


func configure(memories: Array[Dictionary], _from: Vector3, to: Vector3) -> void:
	var cue: float = .7
	for memory: Dictionary in memories:
		memory.cue = cue
		cue += float(memory.length) + .9
	duration = cue + .7
	walk_to = to
	# Match the corridor length to the complete recalled takes, rather than slowing his feet.
	walk_from = to - Vector3.RIGHT * STRIDE_SPEED * (duration - .6)
	_extend_to(to_local(walk_from).x - 6.0)
	for memory: Dictionary in memories:
		var at: float = float(memory.cue) + float(memory.length) * .4
		var sample: Vector4 = travel(at)
		memory.body.global_position = Vector3(sample.x, sample.y - .05, sample.z + 2.25)


## Continuous travel under the recalled voices, with only the departure/end eased.
func travel(time: float) -> Vector4:
	var t: float = clampf(time, 0.0, duration)
	var ramp: float = .6
	var distance: float
	if t < ramp:
		distance = pow(t, 3) / pow(ramp, 2) - .5 * pow(t, 4) / pow(ramp, 3)
	elif t > duration - ramp:
		var remaining: float = duration - t
		distance = duration - ramp - (pow(remaining, 3) / pow(ramp, 2) - .5 * pow(remaining, 4) / pow(ramp, 3))
	else:
		distance = t - ramp * .5
	var point: Vector3 = walk_from.lerp(walk_to, distance / (duration - ramp))
	var speed: float = STRIDE_SPEED * smoothstep(0.0, ramp, t) * (1.0 - smoothstep(duration - ramp, duration, t))
	return Vector4(point.x, point.y, point.z, speed)


## Temporary architecture only: a clear corridor sized for this run's voice takes.
func _extend_to(start: float) -> void:
	get_node("StartWall").queue_free()
	var width: float = maxf(0.0, -12.0 - start)
	if width <= 0.0:
		return
	var center: float = (start - 12.0) * .5
	_extension_box("ExtendedFloor", Vector3(center, -.12, 0), Vector3(width, .24, 10), get_node("Floor").material_override)
	_extension_box("ExtendedCeiling", Vector3(center, 3.85, 0), Vector3(width, .2, 10), get_node("Ceiling").material_override)
	for side in [-1, 1]:
		_extension_box("ExtendedWall", Vector3(center, 1.9, side * 5.0), Vector3(width, 3.8, .25), get_node("BackWall").material_override)
	for index in range(int(ceil(width / 6.0))):
		var x: float = -15.0 - index * 6.0
		for side in [-1, 1]:
			_extension_box("Trim", Vector3(x, 1.85, side * 4.79), Vector3(.14, 3.7, .15), get_node("PilasterLeft_0").material_override, false)
			_extension_box("WallLamp", Vector3(x, 2.35, side * 4.66), Vector3(.08, .9, .08), get_node("WallLightLeft_0").material_override, false)
		var pool: OmniLight3D = OmniLight3D.new()
		pool.name = "PoolExtension%d" % index
		pool.position = Vector3(x, 3.1, 0)
		pool.light_color = Color(.81, .86, 1)
		pool.light_energy = 1.8
		pool.omni_range = 8.0
		add_child(pool)


func _extension_box(part_name: String, at: Vector3, size: Vector3, material: Material, colliding: bool = true) -> void:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.name = part_name
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.material_override = material
	part.position = at
	add_child(part)
	if colliding:
		var solid: StaticBody3D = StaticBody3D.new()
		var shape: CollisionShape3D = CollisionShape3D.new()
		var bounds: BoxShape3D = BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		solid.add_child(shape)
		part.add_child(solid)


func set_door(amount: float) -> void:
	door_open = clampf(amount, 0.0, 1.0)
	get_node("LiftDoorLeft").position.z = lerpf(-.68, -2.1, door_open)
	get_node("LiftDoor1").position.z = lerpf(.68, 2.1, door_open)
