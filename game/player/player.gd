extends CharacterBody3D
## Camera-relative locomotion. Only the visual turns; camera yaw stays independent.

signal health_changed(value: int)
signal died
signal reset_requested
signal hit_confirmed
signal hurt

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var acceleration: float = 28.0
@export var braking: float = 36.0
@export var air_acceleration: float = 8.0
@export var jump_speed: float = 7.0
@export var gravity: float = 22.0
@export var turn_speed: float = 14.0
@export var max_health: int = 100

var health: int = 100
var invulnerable_left: float = 0.0
var hurt_left: float = 0.0

var spawn_position: Vector3
var stride: float = 0.0
@onready var visual: Node3D = $Visual
@onready var camera_rig: Node3D = $CameraRig
@onready var left_leg: Node3D = $Visual/LeftLeg
@onready var right_leg: Node3D = $Visual/RightLeg
@onready var left_arm: Node3D = $Visual/LeftArm
@onready var right_arm: Node3D = $Visual/RightArm
@onready var melee: Node3D = $Visual/Melee
@onready var weapon: Node3D = $Visual/WeaponPivot


func _ready() -> void:
	spawn_position = global_position
	melee.hit_landed.connect(_on_hit_landed)


func _unhandled_input(event: InputEvent) -> void:
	if camera_rig.controls_active and event.is_action_pressed("attack") and not event.is_echo():
		request_attack()
		get_viewport().set_input_as_handled()


func request_attack() -> bool:
	if health <= 0 or hurt_left > 0 or not is_on_floor() or melee.attacking:
		return false
	visual.rotation.y = camera_rig.rotation.y
	return melee.start()


func _on_hit_landed(_target: Node3D) -> void:
	if DisplayServer.get_name() != "headless":
		$HitSound.play()
	hit_confirmed.emit()


func receive_damage(amount: int, _source: Vector3) -> bool:
	if health <= 0 or invulnerable_left > 0:
		return false
	health = maxi(0, health - amount)
	invulnerable_left = 0.65
	hurt_left = 0.16
	melee.cancel()
	health_changed.emit(health)
	if DisplayServer.get_name() != "headless":
		$HurtSound.play()
	hurt.emit()
	if health == 0:
		velocity = Vector3.ZERO
		visual.rotation.z = PI / 2.0
		died.emit()
	return true


func reset_player() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	health = max_health
	invulnerable_left = 0.0
	hurt_left = 0.0
	melee.cancel()
	weapon.rotation = Vector3.ZERO
	$HitSound.stop()
	$HurtSound.stop()
	health_changed.emit(health)
	camera_rig.reset_view()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	hurt_left = maxf(0.0, hurt_left - delta)
	if global_position.y < -8.0:
		reset_requested.emit()

	var input_vector: Vector2 = Vector2.ZERO
	if camera_rig.controls_active:
		input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = camera_rig.global_basis * Vector3(input_vector.x, 0.0, input_vector.y)
	direction.y = 0.0
	var speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	if melee.attacking:
		speed = walk_speed * 0.35
	if hurt_left > 0:
		speed = 0.0
	var rate: float = acceleration if not input_vector.is_zero_approx() else braking
	if not is_on_floor():
		rate = air_acceleration
		velocity.y -= gravity * delta
	elif camera_rig.controls_active and not melee.attacking and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed
	else:
		velocity.y = 0.0
	velocity.x = move_toward(velocity.x, direction.x * speed, rate * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, rate * delta)
	move_and_slide()

	if not melee.attacking and direction.length_squared() > 0.001:
		var facing: float = atan2(-direction.x, -direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, facing, 1.0 - exp(-turn_speed * delta))
	_animate_proxy(delta)


func _animate_proxy(delta: float) -> void:
	var planar_speed: float = Vector2(velocity.x, velocity.z).length()
	stride += planar_speed * delta * 2.4
	var amplitude: float = minf(planar_speed / sprint_speed, 1.0) * 0.65
	if not is_on_floor():
		amplitude = 0.0
	var swing: float = sin(stride) * amplitude
	left_leg.rotation.x = swing
	right_leg.rotation.x = -swing
	left_arm.rotation.x = -swing * 0.7
	right_arm.rotation.x = swing * 0.7
	if melee.attacking:
		var swing_progress: float = clampf((melee.elapsed - melee.windup) / melee.active_time, 0.0, 1.0)
		weapon.rotation.y = lerpf(-1.0, 1.0, swing_progress)
		right_arm.rotation.x = -1.0
	else:
		weapon.rotation.y = lerp_angle(weapon.rotation.y, 0.0, 1.0 - exp(-18.0 * delta))
