extends Node3D
## A booked meeting: telegraphed on the floor, then it slows and drains whoever attends.
## Planar distance check only, so it never needs physics overlap and resets instantly.

signal expired
@export var radius: float = 3.0
@export var telegraph: float = 1.1
@export var duration: float = 4.0
@export var tick_damage: int = 5
@export var warning_text: String = "MEETING STARTS IN"
@export var active_text: String = "MEETING IN PROGRESS\nATTENDANCE MANDATORY"
var player: CharacterBody3D
var age: float = 0.0
var tick: float = 0.0
var disc: MeshInstance3D
var edge: MeshInstance3D
var material: StandardMaterial3D
var label: Label3D


func _ready() -> void:
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(.3, .55, 1, .12)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	disc = MeshInstance3D.new()
	var plate: CylinderMesh = CylinderMesh.new()
	plate.top_radius = radius
	plate.bottom_radius = radius
	plate.height = .02
	plate.radial_segments = 40
	disc.mesh = plate
	disc.position.y = .05
	disc.material_override = material
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)
	edge = MeshInstance3D.new()
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = radius - .08
	ring.outer_radius = radius
	ring.rings = 40
	edge.mesh = ring
	edge.position.y = .06
	var bright: StandardMaterial3D = StandardMaterial3D.new()
	bright.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bright.albedo_color = Color(.45, .7, 1)
	edge.material_override = bright
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(edge)
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.0
	label.font_size = 44
	label.pixel_size = .004
	label.outline_size = 10
	label.modulate = Color(.7, .85, 1)
	add_child(label)


func contains(body: Node3D) -> bool:
	if age < telegraph or age >= telegraph + duration:
		return false
	var offset: Vector3 = body.global_position - global_position
	return Vector2(offset.x, offset.z).length() <= radius


func _physics_process(delta: float) -> void:
	age += delta
	if age < telegraph:
		label.text = "%s %d" % [warning_text, ceili(telegraph - age)]
		var pulse: float = .5 + .5 * sin(age * 20.0)
		edge.scale = Vector3.ONE * lerpf(.3, 1.0, age / telegraph)
		material.albedo_color.a = .08 + .1 * pulse
		return
	edge.scale = Vector3.ONE
	material.albedo_color = Color(.3, .55, 1, .32)
	label.text = active_text
	if age >= telegraph + duration:
		expired.emit()
		set_physics_process(false)
		return
	tick -= delta
	if is_instance_valid(player) and contains(player) and tick <= 0:
		tick = 1.0
		player.receive_damage(tick_damage, global_position)
