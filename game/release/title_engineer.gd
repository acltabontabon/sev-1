extends "res://game/player/rigged_engineer.gd"
## Desk-only prop choreography. The shared gameplay rig remains untouched.

const COFFEE_DURATION: float = 5.0
const HANDLE: Vector3 = Vector3(.095, .095, 0)
const LIP_CONTACT: Vector3 = Vector3(0, .18, .063)
var coffee_mug: Node3D
var coffee_rest: Transform3D
var coffee_active: bool = false
var coffee_time: float = 0.0
var reach_from: Vector3
var coffee_grip: Vector3
var coffee_mouth: Vector3
var solved_coffee_hand: Vector3
var coffee_lip: Vector3


func begin_coffee() -> void:
	if coffee_active or not is_instance_valid(coffee_mug):
		return
	coffee_rest = coffee_mug.global_transform
	reach_from = right_target.global_position
	coffee_time = 0.0
	coffee_active = true
	story_pose = Pose.SIP


func _ready() -> void:
	super._ready()
	# Read the solved fist while the modifier's result is still applied to the skin.
	right_ik.modification_processed.connect(_coffee_hand_solved)


func _coffee_hand_solved() -> void:
	solved_coffee_hand = skeleton.global_transform * skeleton.get_bone_global_pose(bones["Fist.R"]).origin


func _staged(delta: float) -> void:
	super._staged(delta)
	if not coffee_active:
		return
	coffee_time = minf(COFFEE_DURATION, coffee_time + delta)
	var carry: float = smoothstep(.85, 1.8, coffee_time) * (1.0 - smoothstep(3.2, 4.2, coffee_time))
	var reaching: float = smoothstep(0, .7, coffee_time) * (1.0 - smoothstep(4.25, COFFEE_DURATION, coffee_time)) * (1.0 - carry)
	# Reach from the torso while keeping the hips seated and the cup on the clear side.
	position += Vector3(.1, 0, -.05) * reaching
	_turn("Abdomen", Vector3.RIGHT, -.5 * reaching)
	_turn("Abdomen", Vector3.FORWARD, .45 * reaching)
	# Turn toward the title camera so the cup reads against his cheek.
	_turn("Head", Vector3.UP, -.95 * carry)
	var head: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bones["Head"])
	coffee_mouth = head.origin + head.basis.orthonormalized() * Vector3(0, .17, .34)
	var tilt: float = smoothstep(1.8, 2.25, coffee_time) * (1.0 - smoothstep(2.8, 3.2, coffee_time))
	var drinking_basis: Basis = Basis(Vector3.RIGHT, tilt * .32) * coffee_rest.basis
	var rim_contact: Vector3 = coffee_rest.basis.inverse() * LIP_CONTACT
	var drinking: Transform3D = Transform3D(drinking_basis, coffee_mouth - drinking_basis * rim_contact)
	coffee_mug.global_transform = coffee_rest.interpolate_with(drinking, carry)
	# Lift clear before moving sideways; descend vertically for the last part of set-down.
	coffee_mug.global_position.y += sin(carry * PI) * .12
	coffee_grip = coffee_mug.global_transform * HANDLE
	coffee_lip = coffee_mug.global_transform * rim_contact
	var contact: Vector3 = reach_from.lerp(coffee_grip, smoothstep(0, .8, coffee_time))
	var typing: Vector3 = get_parent().to_global(DESK_HANDS[1])
	contact = contact.lerp(typing, smoothstep(4.25, COFFEE_DURATION, coffee_time))
	hands[1] = to_local(contact)
	right_target.position = hands[1]
	right_reach = 1.0
	if coffee_time >= COFFEE_DURATION:
		coffee_mug.global_transform = coffee_rest
		coffee_active = false
		story_pose = Pose.TYPING
