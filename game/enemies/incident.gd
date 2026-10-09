extends CharacterBody3D
## One slow pursuer: approach, commit to a direction, telegraph, swing, recover.

signal health_changed(value: int)
signal died

enum State { IDLE, APPROACH, TELEGRAPH, ATTACK, RECOVER, REACT, DEAD }

@export var max_health: int = 100
@export var move_speed: float = 2.4
@export var attack_distance: float = 1.65
@export var detection_distance: float = 10.0
@export_range(0, 0.5) var hit_reaction_duration: float = 0.2
@export_range(0, 8) var knockback_speed: float = 3.0
@export_range(0, 0.3) var hit_flash_duration: float = 0.12

var health: int = 100
var spawn_position: Vector3
var stagger_left: float = 0.0
var flash_left: float = 0.0
var knockback: Vector3 = Vector3.ZERO
var target: CharacterBody3D
var flash_material: StandardMaterial3D
var state: State = State.IDLE
var hitstop_left: float = 0.0
@onready var navigation: NavigationAgent3D = $NavigationAgent3D
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
	state = State.IDLE
	hitstop_left = 0.0
	health = max_health
	global_position = spawn_position
	velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	stagger_left = 0.0
	flash_left = 0.0
	visual.rotation = Vector3.ZERO
	visual.scale = Vector3.ONE
	body.material_override = null
	$Visual/LeftArm.rotation = Vector3.ZERO
	$Visual/RightArm.rotation = Vector3.ZERO
	$ImpactSparks.clear()
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
	flash_left = hit_flash_duration
	stagger_left = hit_reaction_duration
	knockback = (global_position - Vector3(source.x, global_position.y, source.z)).normalized() * knockback_speed
	# A hit reacts visibly but does not cancel a committed enemy attack.
	# Otherwise repeated light attacks could stun-lock the only opponent.
	if health == 0:
		state = State.DEAD
		melee.cancel()
		tell.hide()
		collision_layer = 0
		visual.rotation.z = -PI / 2.0
		label.text = "INCIDENT RESOLVED"
		died.emit()
	return true


func apply_hitstop(duration: float) -> void:
	hitstop_left = maxf(hitstop_left, duration)
	melee.freeze_left = maxf(melee.freeze_left, duration)


func show_impact(color: Color) -> void:
	$ImpactSparks.burst(global_position + Vector3.UP * 1.2, color)


func _update_state() -> void:
	if health <= 0:
		state = State.DEAD
	elif melee.attacking:
		if melee.elapsed < melee.windup:
			state = State.TELEGRAPH
		elif melee.is_active():
			state = State.ATTACK
		else:
			state = State.RECOVER
	elif stagger_left > 0:
		state = State.REACT
	else:
		state = State.IDLE


func _physics_process(delta: float) -> void:
	if hitstop_left > 0:
		hitstop_left = maxf(0, hitstop_left - delta)
		return
	flash_left = maxf(0.0, flash_left - delta)
	body.material_override = flash_material if flash_left > 0 else null
	if health <= 0:
		return
	stagger_left = maxf(0.0, stagger_left - delta)
	_update_state()
	knockback = knockback.move_toward(Vector3.ZERO, delta * 18.0)
	var direction: Vector3 = Vector3.ZERO
	if is_instance_valid(target) and target.health > 0:
		var offset: Vector3 = target.global_position - global_position
		var planar: Vector3 = Vector3(offset.x, 0, offset.z)
		if state == State.IDLE and planar.length() < detection_distance:
			visual.rotation.y = atan2(-planar.x, -planar.z)
			if planar.length() <= attack_distance and absf(offset.y) < 0.7:
				var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, target.global_position + Vector3.UP, 1)
				if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
					melee.start()
					state = State.TELEGRAPH
			# Being close through furniture is not an attack opportunity: keep routing.
			if state != State.TELEGRAPH:
				state = State.APPROACH
				direction = planar.normalized()
				# The office has furniture; use its baked routes without changing attacks.
				if NavigationServer3D.map_get_iteration_id(navigation.get_navigation_map()) > 0:
					navigation.target_position = target.global_position
					var next: Vector3 = navigation.get_next_path_position() - global_position
					direction = Vector3(next.x, 0, next.z).normalized()
	velocity.x = direction.x * move_speed + knockback.x
	velocity.z = direction.z * move_speed + knockback.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 22.0 * delta
	move_and_slide()
	tell.visible = state == State.TELEGRAPH
	if tell.visible:
		# The warning shows the full damage reach from the first wind-up frame.
		tell.scale = Vector3.ONE
		label.text = "INCOMING!"
	elif state == State.ATTACK:
		label.text = "STRIKE"
	elif state == State.RECOVER:
		label.text = "RECOVERING"
	elif state == State.REACT:
		label.text = "STAGGERED"
	else:
		label.text = "PRODUCTION INCIDENT  /  %d" % health
	var arm_pose: float = 0.0
	if melee.attacking:
		arm_pose = 0.9 if melee.elapsed < melee.windup else -1.2
	$Visual/LeftArm.rotation.x = lerpf($Visual/LeftArm.rotation.x, arm_pose, 1.0 - exp(-18.0 * delta))
	$Visual/RightArm.rotation.x = $Visual/LeftArm.rotation.x
	visual.rotation.z = sin(stagger_left * 40.0) * 0.12 if stagger_left > 0 else 0.0
	if global_position.y < -8:
		reset_enemy()
