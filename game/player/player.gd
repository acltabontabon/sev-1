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
@export_range(0, 1) var attack_movement_scale: float = 0.35
@export_range(0, 2) var damage_invulnerability: float = 0.65
@export_range(0, 0.5) var hurt_duration: float = 0.16
@export var combo: Array[AttackProfile] = []
@export_range(0.05, 0.5) var combo_buffer_window: float = 0.24
@export_range(0.05, 0.5) var combo_link_window: float = 0.26
@export_range(0.5, 6.0) var dodge_distance: float = 3.0
@export_range(0.1, 0.6) var dodge_duration: float = 0.24
@export_range(0.1, 1.0) var dodge_recovery: float = 0.32
@export_range(0, 0.2) var dodge_invulnerability_start: float = 0.0
@export_range(0, 0.4) var dodge_invulnerability_end: float = 0.18
@export var hitstop_enabled: bool = true
@export_range(0, 1) var camera_impulse_strength: float = 0.4
@export var impact_particles_enabled: bool = true

var health: int = 100
var invulnerable_left: float = 0.0
var hurt_left: float = 0.0
var combo_index: int = -1
var combo_buffer_left: float = 0.0
var combo_link_left: float = 0.0
var hitstop_left: float = 0.0
var dodging: bool = false
var dodge_elapsed: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO

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
@onready var dodge_aura: MeshInstance3D = $Visual/DodgeAura


func _ready() -> void:
	health = max_health
	spawn_position = global_position
	melee.hit_landed.connect(_on_hit_landed)
	melee.finished.connect(_on_attack_finished)


func _unhandled_input(event: InputEvent) -> void:
	if camera_rig.controls_active and event.is_action_pressed("attack") and not event.is_echo():
		request_attack()
		get_viewport().set_input_as_handled()
	elif camera_rig.controls_active and event.is_action_pressed("dodge") and not event.is_echo():
		request_dodge()
		get_viewport().set_input_as_handled()


func request_attack() -> bool:
	if health <= 0 or hurt_left > 0 or dodging or not is_on_floor() or combo.is_empty():
		return false
	if melee.attacking:
		if combo_index < combo.size() - 1 and melee.remaining_time() <= combo_buffer_window:
			combo_buffer_left = combo_buffer_window + 1.0 / Engine.physics_ticks_per_second
			return true
		return false
	var next: int = combo_index + 1 if combo_link_left > 0 else 0
	return _start_step(next)


func _start_step(index: int) -> bool:
	combo_index = index % combo.size()
	combo_buffer_left = 0.0
	combo_link_left = 0.0
	melee.configure(combo[combo_index])
	melee.audio.pitch_scale = 0.8 if combo_index == 2 else 1.0 + combo_index * 0.15
	visual.rotation.y = camera_rig.rotation.y
	return melee.start()


func _on_attack_finished() -> void:
	if combo_index < combo.size() - 1:
		if combo_buffer_left > 0 and health > 0 and not dodging:
			_start_step(combo_index + 1)
		else:
			combo_link_left = combo_link_window
	else:
		clear_combo()


func clear_combo() -> void:
	combo_index = -1
	combo_buffer_left = 0.0
	combo_link_left = 0.0


func request_dodge() -> bool:
	if health <= 0 or hurt_left > 0 or dodging or not is_on_floor() or melee.is_active() or hitstop_left > 0:
		return false
	melee.cancel()
	clear_combo()
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	dodge_direction = camera_rig.global_basis * Vector3(input_vector.x, 0, input_vector.y)
	if dodge_direction.is_zero_approx():
		dodge_direction = camera_rig.global_basis.z
	dodge_direction.y = 0
	dodge_direction = dodge_direction.normalized()
	dodge_elapsed = 0.0
	dodging = true
	return true


func dodge_is_invulnerable() -> bool:
	return dodging and dodge_elapsed >= dodge_invulnerability_start and dodge_elapsed < minf(dodge_invulnerability_end, dodge_duration)


func _on_hit_landed(target: Node3D) -> void:
	if DisplayServer.get_name() != "headless":
		$HitSound.play()
	hit_confirmed.emit()
	if combo_index >= 0:
		var duration: float = combo[combo_index].hitstop if hitstop_enabled else 0.0
		hitstop_left = duration
		melee.freeze_left = duration
		if target.has_method("apply_hitstop"):
			target.apply_hitstop(duration)
		camera_rig.add_impulse(camera_impulse_strength * (1.5 if combo_index == 2 else 1.0))
		if impact_particles_enabled and target.has_method("show_impact"):
			target.show_impact(combo[combo_index].color)


func receive_damage(amount: int, _source: Vector3) -> bool:
	if health <= 0 or invulnerable_left > 0 or dodge_is_invulnerable():
		return false
	health = maxi(0, health - amount)
	invulnerable_left = damage_invulnerability
	hurt_left = hurt_duration
	melee.cancel()
	clear_combo()
	dodging = false
	dodge_aura.hide()
	visual.scale = Vector3.ONE
	visual.rotation.x = 0.0
	hitstop_left = 0.0
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
	clear_combo()
	dodging = false
	dodge_elapsed = 0.0
	dodge_direction = Vector3.ZERO
	hitstop_left = 0.0
	dodge_aura.hide()
	visual.scale = Vector3.ONE
	for limb in [left_leg, right_leg, left_arm, right_arm]:
		limb.rotation = Vector3.ZERO
	weapon.rotation = Vector3.ZERO
	$HitSound.stop()
	$HurtSound.stop()
	health_changed.emit(health)
	camera_rig.reset_view()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	if hitstop_left > 0:
		hitstop_left = maxf(0, hitstop_left - delta)
		return
	combo_buffer_left = maxf(0, combo_buffer_left - delta)
	combo_link_left = maxf(0, combo_link_left - delta)
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	hurt_left = maxf(0.0, hurt_left - delta)
	if global_position.y < -8.0:
		reset_requested.emit()
		return
	if dodging:
		_tick_dodge(delta)
		return

	var input_vector: Vector2 = Vector2.ZERO
	if camera_rig.controls_active:
		input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = camera_rig.global_basis * Vector3(input_vector.x, 0.0, input_vector.y)
	direction.y = 0.0
	var speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	if melee.attacking:
		speed = walk_speed * attack_movement_scale
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


func _tick_dodge(delta: float) -> void:
	var travel_delta: float = minf(delta, maxf(0, dodge_duration - dodge_elapsed))
	dodge_elapsed += delta
	var speed: float = dodge_distance / maxf(dodge_duration, 0.01) * travel_delta / delta
	velocity.x = dodge_direction.x * speed
	velocity.z = dodge_direction.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()
	dodge_aura.visible = dodge_is_invulnerable()
	visual.scale = Vector3(1.08, 0.78, 1.08) if travel_delta > 0 else visual.scale.lerp(Vector3.ONE, minf(1, delta * 20))
	visual.rotation.x = -0.18 if travel_delta > 0 else 0.0
	if dodge_elapsed >= dodge_duration + dodge_recovery:
		dodging = false
		dodge_aura.hide()
		visual.scale = Vector3.ONE
		visual.rotation.x = 0.0


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
		var swing_direction: float = combo[combo_index].swing_direction if combo_index >= 0 else 1.0
		weapon.rotation.y = lerpf(-1.0, 1.0, swing_progress) * swing_direction
		weapon.rotation.z = sin(swing_progress * PI) * 0.45 if combo_index == 2 else 0.0
		right_arm.rotation.x = -1.0
	else:
		weapon.rotation.y = lerp_angle(weapon.rotation.y, 0.0, 1.0 - exp(-18.0 * delta))
		weapon.rotation.z = lerp_angle(weapon.rotation.z, 0.0, 1.0 - exp(-18.0 * delta))
