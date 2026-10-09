extends CharacterBody3D
## One slow pursuer: approach, commit to a direction, telegraph, swing, recover.

signal health_changed(value: int)
signal died

@export var max_health: int = 100
@export var move_speed: float = 2.4
@export var attack_distance: float = 1.65
@export var detection_distance: float = 10.0

var health: int = 100
var spawn_position: Vector3
var stagger_left: float = 0.0
var flash_left: float = 0.0
var knockback: Vector3 = Vector3.ZERO
var target: CharacterBody3D
var flash_material: StandardMaterial3D
@onready var visual: Node3D = $Visual
@onready var melee: Node3D = $Visual/Melee
@onready var tell: MeshInstance3D = $Visual/Telegraph
@onready var label: Label3D = $Label
@onready var body: MeshInstance3D = $Visual/Body


func _ready() -> void:
	spawn_position = global_position
	target = get_tree().get_first_node_in_group("players") as CharacterBody3D
	flash_material = StandardMaterial3D.new()
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.albedo_color = Color(1, 0.9, 0.65)
	tell.mesh = melee.arc.mesh
	reset_enemy()


func reset_enemy() -> void:
	health = max_health
	global_position = spawn_position
	velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	stagger_left = 0.0
	flash_left = 0.0
	visual.rotation = Vector3.ZERO
	visual.scale = Vector3.ONE
	body.material_override = null
	melee.cancel()
	tell.hide()
	collision_layer = 4
	health_changed.emit(health)
	label.text = "PRODUCTION INCIDENT  /  %d" % health
	reset_physics_interpolation()


func receive_damage(amount: int, source: Vector3) -> bool:
	if health <= 0:
		return false
	health = maxi(health - amount, 0)
	health_changed.emit(health)
	flash_left = 0.12
	stagger_left = 0.2
	knockback = (global_position - Vector3(source.x, global_position.y, source.z)).normalized() * 3.0
	# A hit reacts visibly but does not cancel a committed enemy attack.
	# Otherwise repeated light attacks could stun-lock the only opponent.
	if health == 0:
		melee.cancel()
		tell.hide()
		collision_layer = 0
		visual.rotation.z = -PI / 2.0
		label.text = "INCIDENT RESOLVED"
		died.emit()
	return true


func _physics_process(delta: float) -> void:
	flash_left = maxf(0.0, flash_left - delta)
	body.material_override = flash_material if flash_left > 0 else null
	if health <= 0:
		return
	stagger_left = maxf(0.0, stagger_left - delta)
	knockback = knockback.move_toward(Vector3.ZERO, delta * 18.0)
	var direction: Vector3 = Vector3.ZERO
	if is_instance_valid(target) and target.health > 0:
		var offset: Vector3 = target.global_position - global_position
		var planar: Vector3 = Vector3(offset.x, 0, offset.z)
		if not melee.attacking and stagger_left <= 0 and planar.length() < detection_distance:
			visual.rotation.y = atan2(-planar.x, -planar.z)
			if planar.length() <= attack_distance and absf(offset.y) < 0.7:
				melee.start()
			else:
				direction = planar.normalized()
	velocity.x = direction.x * move_speed + knockback.x
	velocity.z = direction.z * move_speed + knockback.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 22.0 * delta
	move_and_slide()
	tell.visible = melee.attacking and melee.elapsed < melee.windup
	if tell.visible:
		var progress: float = clampf(melee.elapsed / melee.windup, 0, 1)
		tell.scale = Vector3.ONE * lerpf(0.65, 1.0, progress)
		label.text = "INCOMING!"
	elif melee.attacking:
		label.text = "RECOVERING"
	else:
		label.text = "PRODUCTION INCIDENT  /  %d" % health
	var arm_pose: float = 0.0
	if melee.attacking:
		arm_pose = 0.9 if melee.elapsed < melee.windup else -1.2
	$Visual/LeftArm.rotation.x = lerpf($Visual/LeftArm.rotation.x, arm_pose, 1.0 - exp(-18.0 * delta))
	$Visual/RightArm.rotation.x = $Visual/LeftArm.rotation.x
	if global_position.y < -8:
		reset_enemy()
