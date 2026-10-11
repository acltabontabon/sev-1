extends Node3D
## Local departure staging: ordinary strides, held memories and a real opening doorway.
const THRESHOLD: float = 9.8
const LEG_SECONDS: float = 2.0
var legs: Array[Dictionary] = []
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


func configure(memories: Array[Dictionary], from: Vector3, to: Vector3) -> void:
	legs.clear()
	var at: float = 0.0
	for index in range(memories.size() + 1):
		var start: Vector3 = from.lerp(to, float(index) / 6.0)
		var end: Vector3 = from.lerp(to, float(index + 1) / 6.0)
		legs.append({"at": at, "from": start, "to": end})
		at += LEG_SECONDS
		if index < memories.size():
			var memory: Dictionary = memories[index]
			memory.cue = at + .2
			memory.body.global_position = end + Vector3(.45, -.05, 2.25)
			at = float(memory.cue) + float(memory.length) + .8
	duration = at


## A short eased stride between memories; he rests while listening to each full line.
func travel(time: float) -> Vector4:
	for leg: Dictionary in legs:
		var t: float = time - float(leg.at)
		if t <= LEG_SECONDS:
			var u: float = clampf(t / LEG_SECONDS, 0.0, 1.0)
			var ease: float = u * u * (3.0 - 2.0 * u)
			var point: Vector3 = (leg.from as Vector3).lerp(leg.to, ease)
			var speed: float = (leg.from as Vector3).distance_to(leg.to) * 6.0 * u * (1.0 - u) / LEG_SECONDS
			return Vector4(point.x, point.y, point.z, speed)
	var last: Vector3 = legs.back().to
	return Vector4(last.x, last.y, last.z, 0.0)


func set_door(amount: float) -> void:
	door_open = clampf(amount, 0.0, 1.0)
	get_node("LiftDoorLeft").position.z = lerpf(-.68, -2.1, door_open)
	get_node("LiftDoor1").position.z = lerpf(.68, 2.1, door_open)
