extends Node3D
## A fixed eight-spark pool. Reused on each impact and cleared on encounter reset.

@export_range(0, 1) var duration: float = 0.18
@export_range(0, 8) var speed: float = 2.4
var remaining: float = 0.0
var sparks: Array[MeshInstance3D] = []
var directions: Array[Vector3] = []
var material: StandardMaterial3D


func _ready() -> void:
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.055, 0.055, 0.13)
	mesh.material = material
	for index in range(8):
		var spark: MeshInstance3D = MeshInstance3D.new()
		spark.mesh = mesh
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(spark)
		sparks.append(spark)
		var angle: float = TAU * index / 8.0
		directions.append(Vector3(cos(angle), 0.35 + (index % 3) * 0.25, sin(angle)).normalized())
	clear()


func burst(origin: Vector3, color: Color) -> void:
	global_position = origin
	remaining = duration
	material.albedo_color = color
	for spark in sparks:
		spark.position = Vector3.ZERO
		spark.scale = Vector3.ONE
	show()


func clear() -> void:
	remaining = 0.0
	hide()


func _physics_process(delta: float) -> void:
	if remaining <= 0:
		return
	remaining = maxf(0, remaining - delta)
	for index in range(sparks.size()):
		sparks[index].position += directions[index] * speed * delta
		sparks[index].scale = Vector3.ONE * maxf(0.01, remaining / maxf(duration, 0.01))
	if remaining == 0:
		hide()
