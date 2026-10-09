extends Node3D
## Native fallback only: reads combat state; never starts attacks or applies damage.
## Replace this scene behind the same controller contract when a rig is approved.

@export var stride_length: float = 1.25
@export var breathing_amount: float = 0.008
## Authored staging only. 1-2 keep the standing opening glances; 3+ are full-body holds
## used by the menu desk and the opening. Gameplay always runs with 0.
enum Pose { NONE, LOOK_DOWN, LOOK_UP, TYPING, ALERT, SLUMP, SIP, RELAX, GLANCE, ARMED }
var story_pose: int = 0
var sit: float = 0.0
var hands: Array[Vector3] = [Vector3(-.36, .83, -.04), Vector3(.36, .83, -.04)]
var head_turn: Vector2 = Vector2.ZERO
var lean: float = 0.0
var phase: float = 0.0
var clock: float = 0.0
var crouch: float = 0.0
var previous_position: Vector3
var actor: CharacterBody3D
@onready var weapon: Node3D = $WeaponPivot


func _ready() -> void:
	# Null outside a player, e.g. the menu desk: the scene is then staged only.
	actor = get_parent().get_parent() as CharacterBody3D
	# Read the completed controller/melee tick, including hit-stop and cancellation.
	process_physics_priority = 10


func reset_pose() -> void:
	phase = 0.0
	clock = 0.0
	crouch = 0.0
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	sit = 0.0
	lean = 0.0
	head_turn = Vector2.ZERO
	previous_position = actor.global_position if actor != null else global_position
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
	if actor == null:
		clock += delta
		_staged(delta)
		return
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
	if story_pose >= Pose.TYPING:
		_staged(delta)
	elif story_pose > 0:
		weapon.rotation.x = -1.35
		_pose_arms(0)
		$Head.rotation.x = .22 if story_pose == 1 else -.08
		$Head.rotation.y = -.3 if story_pose == 1 else .4
		_arm("Left", Vector3(-.34, 1.39, 0), Vector3(-.12, 1.22, -.38), Vector3(-.3, 0, .2))
	else:
		$Head.rotation.y = 0


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


## Full-body authored hold, blended so cuts between poses never pop.
## Desk geometry: seat at the origin, keyboard about 0.55 m ahead at desk height.
func _staged(delta: float) -> void:
	var seated: bool = story_pose in [Pose.TYPING, Pose.ALERT, Pose.SLUMP, Pose.SIP, Pose.RELAX, Pose.GLANCE]
	var blend: float = 1.0 - exp(-7.0 * delta)
	sit = lerpf(sit, 1.0 if seated else 0.0, blend)
	var type: float = absf(sin(clock * 13.0)) * .018
	var targets: Array[Vector3] = [Vector3(-.17, .87 + type, -.55), Vector3(.13, .87 + absf(sin(clock * 11.0 + 1.3)) * .018, -.55)]
	var look: Vector2 = Vector2(.12, 0)
	var target_lean: float = -.12
	match story_pose:
		Pose.ALERT:
			targets = [Vector3(-.2, .97, -.46), Vector3(.16, .97, -.46)]
			look = Vector2(-.04, 0)
			target_lean = .02
		Pose.SLUMP:
			targets = [Vector3(-.22, .7, -.28), Vector3(.22, .7, -.28)]
			look = Vector2(.55, .05)
			target_lean = -.28
		Pose.SIP:
			targets = [Vector3(-.17, .87, -.55), Vector3(.1, 1.36, -.2)]
			look = Vector2(-.12, .08)
			target_lean = .08
		Pose.RELAX:
			targets = [Vector3(-.12, 1.6, .1), Vector3(.12, 1.6, .1)]
			look = Vector2(-.18, 0)
			target_lean = .2
		Pose.GLANCE:
			targets = [Vector3(-.2, .9, -.5), Vector3(.16, .9, -.5)]
			look = Vector2(.02, -.35)
			target_lean = -.05
		Pose.ARMED:
			targets = [Vector3(-.2, 1.12, -.32), Vector3.ZERO]
			look = Vector2(-.04, 0)
			target_lean = -.1
	for side in [0, 1]:
		hands[side] = hands[side].lerp(targets[side], blend)
	head_turn = head_turn.lerp(look, blend)
	lean = lerpf(lean, target_lean, blend)
	var drop: float = .23 * sit
	var bob: float = sin(clock * 2.1) * breathing_amount
	$Torso.position = Vector3(0, 1.17 - drop + bob, 0)
	$Torso.rotation = Vector3(lean, 0, 0)
	$Pelvis.position.y = .83 - drop
	$Belt.position.y = .91 - drop
	$Head.position = Vector3(0, 1.68 - drop + bob, -.035 - lean * .35)
	$Head.rotation = Vector3(head_turn.x, head_turn.y, -.04)
	for side in [0, 1]:
		var prefix: String = "Left" if side == 0 else "Right"
		var x: float = -.16 if side == 0 else .16
		var foot: Vector3 = Vector3(x, .13, 0).lerp(Vector3(x * 1.15, .13, -.5), sit)
		_leg(prefix, Vector3(x, .85 - drop, 0), foot)
	# The improvised weapon lies across the desk until the engineer reaches for it.
	var rest_position: Vector3 = Vector3(.3, .88, -.62)
	var rest_rotation: Vector3 = Vector3(0, -1.2, 0)
	if story_pose == Pose.ARMED:
		weapon.position = weapon.position.lerp(Vector3(.36, 1.0 - drop, -.12), blend)
		weapon.rotation = weapon.rotation.lerp(Vector3(-.85, .05, -.1), blend)
		hands[1] = weapon.transform * Vector3(0, 0, -.22)
		hands[0] = hands[0].lerp(weapon.transform * Vector3(0, 0, -.42) + Vector3(-.1, 0, 0), blend)
	else:
		weapon.position = rest_position
		weapon.rotation = rest_rotation
	_arm("Left", Vector3(-.34, 1.39 - drop, 0), hands[0], Vector3(-.4, -.2, .3))
	_arm("Right", Vector3(.34, 1.39 - drop, 0), hands[1], Vector3(.4, -.2, .3))
