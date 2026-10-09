extends Node3D
## A bounded forward strike shared by player and enemy; no lingering hitboxes.

signal hit_landed(target: Node3D)

@export var target_group: StringName = &"enemies"
@export var damage: int = 25
@export var reach: float = 2.25
@export var half_angle_degrees: float = 65.0
@export var windup: float = 0.12
@export var active_time: float = 0.12
@export var recovery: float = 0.28
@export var arc_color: Color = Color(0.3, 0.95, 1.0)
@export var swing_sound: AudioStream
@export var windup_sound: AudioStream

var elapsed: float = 0.0
var attacking: bool = false
var hit_targets: Array[int] = []
var arc: MeshInstance3D
var audio: AudioStreamPlayer3D


func _ready() -> void:
	arc = MeshInstance3D.new()
	arc.name = "StrikeArc"
	var mesh: ImmediateMesh = ImmediateMesh.new()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = arc_color
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
	for index in range(25):
		var angle: float = deg_to_rad(lerpf(-half_angle_degrees, half_angle_degrees, index / 24.0))
		var direction: Vector3 = Vector3(sin(angle), 0, -cos(angle))
		mesh.surface_add_vertex(direction * (reach - 0.22))
		mesh.surface_add_vertex(direction * reach)
	mesh.surface_end()
	arc.mesh = mesh
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(arc)
	arc.hide()
	audio = AudioStreamPlayer3D.new()
	audio.volume_db = -12.0
	add_child(audio)


func start() -> bool:
	if attacking:
		return false
	attacking = true
	elapsed = 0.0
	hit_targets.clear()
	# The headless dummy audio driver does not drain playback on fast test exits.
	if windup_sound and DisplayServer.get_name() != "headless":
		audio.stream = windup_sound
		audio.play()
	return true


func cancel() -> void:
	attacking = false
	elapsed = 0.0
	hit_targets.clear()
	arc.hide()
	audio.stop()


func _physics_process(delta: float) -> void:
	if not attacking:
		return
	var previous: float = elapsed
	elapsed += delta
	if previous < windup and elapsed >= windup and swing_sound and DisplayServer.get_name() != "headless":
		audio.stream = swing_sound
		audio.play()
	# Test even if a long physics step crosses the complete active window.
	if elapsed >= windup and previous < windup + active_time:
		_resolve_hits()
	arc.visible = attacking and elapsed >= windup and elapsed < windup + active_time
	if elapsed >= windup + active_time + recovery:
		cancel()


func _resolve_hits() -> void:
	for candidate in get_tree().get_nodes_in_group(target_group):
		var target: Node3D = candidate as Node3D
		if target == null or hit_targets.has(target.get_instance_id()):
			continue
		var target_center: Vector3 = target.global_position + Vector3.UP
		var offset: Vector3 = target_center - global_position
		if absf(offset.y) > 1.0:
			continue
		var planar: Vector3 = Vector3(offset.x, 0, offset.z)
		if planar.length() > reach:
			continue
		var forward: Vector3 = -global_basis.z
		if not planar.is_zero_approx() and forward.dot(planar.normalized()) < cos(deg_to_rad(half_angle_degrees)):
			continue
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position, target_center, 1)
		ray.hit_from_inside = true
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		hit_targets.append(target.get_instance_id())
		if target.receive_damage(damage, global_position):
			hit_landed.emit(target)
