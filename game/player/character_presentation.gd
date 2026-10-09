extends Node3D
## Native fallback only: reads combat state; never starts attacks or applies damage.
## Replace this scene behind the same controller contract when a rig is approved.

@export var stride_length: float = 1.25
@export var breathing_amount: float = 0.008
var phase: float = 0.0
var clock: float = 0.0
var crouch: float = 0.0
var previous_position: Vector3
var actor: CharacterBody3D
@onready var weapon: Node3D = $WeaponPivot


func _ready() -> void:
	actor = get_parent().get_parent() as CharacterBody3D
	# Read the completed controller/melee tick, including hit-stop and cancellation.
	process_physics_priority = 10


func reset_pose() -> void:
	phase = 0.0
	clock = 0.0
	crouch = 0.0
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	previous_position = actor.global_position
	weapon.position = Vector3(.38, .91, -.02)
	weapon.rotation = Vector3(-.5, 0, 0)
	_pose(0.0, 0.0)


func defeat() -> void:
	# Reports pause immediately. Set a settled kneeling pose before the death signal.
	crouch = .48
	_pose(0.0, 0.0)
	$Torso.rotation.x = .65
	$Head.position += Vector3(0, -.14, -.17)
	$Head.rotation.x = .5
	weapon.position = Vector3(.35, .12, -.25)
	weapon.rotation = Vector3.ZERO
	_pose_arms(0)


func _physics_process(delta: float) -> void:
	if actor.health <= 0:
		return
	var distance: float = Vector2(actor.global_position.x - previous_position.x, actor.global_position.z - previous_position.z).length()
	previous_position = actor.global_position
	if actor.hitstop_left > 0:
		return
	clock += delta
	var speed: float = distance / maxf(delta, .001)
	var old_half: int = int(phase * 2)
	if actor.is_on_floor() and not actor.dodging:
		phase = fmod(phase + distance / stride_length, 1.0)
	if old_half != int(phase * 2) and speed > 1.0 and DisplayServer.get_name() != "headless":
		actor.get_node("StepSound").pitch_scale = 1.04 if phase < .5 else .96
		actor.get_node("StepSound").play()
	var target_crouch: float = .30 if actor.dodging and actor.dodge_elapsed < actor.dodge_duration else 0.0
	crouch = move_toward(crouch, target_crouch, delta * 4.5)
	_pose(speed, delta)


func _pose(speed: float, delta: float) -> void:
	var moving: float = clampf(speed / 2.0, 0, 1) if actor.is_on_floor() and not actor.dodging else 0.0
	var bob: float = sin(clock * 2.1) * breathing_amount * (1.0 - moving)
	$Torso.position.y = 1.17 - crouch + bob
	$Pelvis.position.y = .83 - crouch
	$Belt.position.y = .91 - crouch
	$Head.position = Vector3(0, 1.68 - crouch + bob, -.035)
	$Head.rotation.x = .07
	$Torso.rotation.x = .06 + crouch * .7 + (.16 if actor.hurt_left > 0 else 0.0)
	$Torso.rotation.y = sin(phase * TAU) * .06 * moving
	for side in [0, 1]:
		var prefix: String = "Left" if side == 0 else "Right"
		var x: float = -.16 if side == 0 else .16
		var cycle: float = fmod(phase + side * .5, 1.0)
		# Linear backward travel during stance, lifted forward return during swing.
		# Distance-driven phase reduces skating; no terrain IK/root motion is claimed.
		var foot_z: float = lerpf(-stride_length * .25, stride_length * .25, cycle * 2) if cycle < .5 else lerpf(stride_length * .25, -stride_length * .25, (cycle - .5) * 2)
		var lift: float = sin((cycle - .5) * TAU) * .18 if cycle >= .5 else 0.0
		var foot: Vector3 = Vector3(x, .13 + lift * moving, foot_z * moving)
		if not actor.is_on_floor():
			foot.y += .13
			foot.z += -.15 if side == 0 else .1
		if actor.dodging:
			foot.z = -.28 if side == 0 else .25
		_leg(prefix, Vector3(x, .85 - crouch, 0), foot)
	_pose_weapon(delta)
	_pose_arms(moving)


func _pose_weapon(delta: float) -> void:
	var target_position: Vector3 = Vector3(.38, .91 - crouch, -.02)
	var target_rotation: Vector3 = Vector3(-.5 + crouch, 0, -.08)
	var melee: Node3D = actor.melee
	if melee.attacking:
		var direction: float = actor.combo[actor.combo_index].swing_direction if actor.combo_index >= 0 else 1.0
		var yaw: float
		var weight: float
		if melee.elapsed < melee.windup:
			weight = smoothstep(0, 1, melee.elapsed / melee.windup)
			yaw = -1.12 * direction
		elif melee.elapsed < melee.windup + melee.active_time:
			weight = 1.0
			yaw = lerpf(-1.12, 1.12, (melee.elapsed - melee.windup) / melee.active_time) * direction
		else:
			weight = 1.0 - smoothstep(0, 1, (melee.elapsed - melee.windup - melee.active_time) / melee.recovery)
			yaw = 1.12 * direction
		target_position = target_position.lerp(Vector3(.10, 1.19, -.05), weight)
		target_rotation = target_rotation.lerp(Vector3(.12 if actor.combo_index == 2 else 0.0, yaw, .1 * direction), weight)
		$Torso.rotation.y += yaw * weight * .17
		# Explicit phase coordination: smoothing here would lag the short active window.
		weapon.position = target_position
		weapon.rotation = target_rotation
	else:
		var blend: float = 1.0 if delta == 0 else 1.0 - exp(-18.0 * delta)
		weapon.position = weapon.position.lerp(target_position, blend)
		weapon.rotation = weapon.rotation.lerp(target_rotation, blend)


func _pose_arms(moving: float) -> void:
	var hand: Vector3 = weapon.transform * Vector3(0, 0, -.22)
	_arm("Right", Vector3(.34, 1.39 - crouch, 0), hand, Vector3(.35, 0, .2))
	var left_hand: Vector3 = Vector3(-.36, .83 - crouch, -.04 + sin(phase * TAU) * moving * .16)
	if actor.melee.attacking:
		left_hand = Vector3(-.28, 1.09 - crouch, -.23)
	_arm("Left", Vector3(-.34, 1.39 - crouch, 0), left_hand, Vector3(-.3, 0, .2))


func _leg(prefix: String, hip: Vector3, foot: Vector3) -> void:
	var knee: Vector3 = _joint(hip, foot, .40, Vector3.FORWARD)
	_segment(get_node(prefix + "Leg"), hip, knee)
	_segment(get_node(prefix + "Shin"), knee, foot)
	get_node(prefix + "Foot").position = foot + Vector3(0, -.055, -.065)


func _arm(prefix: String, shoulder: Vector3, hand: Vector3, pole: Vector3) -> void:
	var elbow: Vector3 = _joint(shoulder, hand, .34, pole)
	_segment(get_node(prefix + "Arm"), shoulder, elbow)
	_segment(get_node(prefix + "Forearm"), elbow, hand)
	get_node(prefix + "Hand").position = hand
	get_node(prefix + "Cuff").position = elbow


func _joint(start: Vector3, end: Vector3, length_: float, pole: Vector3) -> Vector3:
	var axis: Vector3 = (end - start).normalized()
	var bend: Vector3 = (pole - axis * pole.dot(axis)).normalized()
	return (start + end) * .5 + bend * sqrt(maxf(.001, length_ * length_ - start.distance_squared_to(end) * .25))


func _segment(node: Node3D, start: Vector3, end: Vector3) -> void:
	node.position = start
	node.quaternion = Quaternion(Vector3.DOWN, (end - start).normalized())
	node.get_node("Mesh").scale.y = start.distance_to(end)
	node.get_node("Mesh").position.y = -start.distance_to(end) * .5
