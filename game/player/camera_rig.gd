extends Node3D
## Orbit independently of the character's facing; the spring arm handles walls. It
## sweeps a sphere (not a ray) so the lens never grazes into a wall or ceiling, also
## stops at the office's camera-only blockers (layer 9), pulls in at once and eases
## back out, and fades the engineer when it has to sit right behind his head.

signal capture_changed(active: bool)

@export_range(0.0005, 0.01) var mouse_sensitivity: float = 0.0025
@export var min_pitch_degrees: float = -65.0
@export var max_pitch_degrees: float = 25.0
@export var min_distance: float = 2.0
@export var max_distance: float = 7.0
@export_range(0, 2) var impulse_degrees: float = 0.8
@export_range(1, 30) var impulse_decay: float = 12.0
## Combat framing: after the mouse rests this long mid-fight, the view eases toward the
## fight. Any mouse motion hands control straight back.
@export_range(0.2, 3.0) var assist_delay: float = 1.0
@export_range(0.2, 6.0) var assist_rate: float = 2.2
@export_range(10, 90) var assist_dead_zone_degrees: float = 35.0

var controls_active: bool = false
var impulse: float = 0.0
## Ground tremor from heavy enemy attacks: random jitter on top of the impulse kick.
var tremor: float = 0.0
## Where the fight is (set by battle mode; INF when nothing is engaged) and how intense.
var focus: Vector3 = Vector3.INF
var battle: float = 0.0
var input_idle: float = 0.0
var assisting: bool = false
## The player's chosen distance; battle pulls back a little on top of it.
var base_length: float = 5.0
## Within this distance of the pivot the engineer fades so the view is not his head.
@export var fade_distance: float = 2.4
var fade_meshes: Array[GeometryInstance3D] = []
var faded: float = 0.0
@onready var spring_arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	spring_arm.add_excluded_object((get_parent() as CollisionObject3D).get_rid())
	# The body and blade only (built before the rig); transient effects keep their own look.
	var visual: Node = get_parent().get_node_or_null("Visual")
	if visual != null:
		for node in visual.find_children("*", "GeometryInstance3D", true, false):
			fade_meshes.append(node)
	reset_view()


func reset_view() -> void:
	impulse = 0.0
	tremor = 0.0
	focus = Vector3.INF
	battle = 0.0
	input_idle = 0.0
	assisting = false
	base_length = 5.0
	$SpringArm3D/Camera3D.rotation = Vector3.ZERO
	rotation = Vector3.ZERO
	spring_arm.rotation.x = deg_to_rad(-18.0)
	spring_arm.spring_length = 5.0
	_fade(0.0)


func add_impulse(strength: float) -> void:
	impulse = minf(1, impulse + strength)


func add_tremor(strength: float) -> void:
	tremor = minf(1, tremor + strength)


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	impulse = move_toward(impulse, 0, delta * impulse_decay)
	tremor = move_toward(tremor, 0, delta * 2.2)
	input_idle += delta
	# A wall pulls the lens in at once; once it clears, the lens eases back out
	# instead of popping (the length grows back from where the wall left it).
	var reach: float = spring_arm.get_hit_length()
	if reach < spring_arm.spring_length - .05:
		spring_arm.spring_length = maxf(reach, min_distance * .5)
	spring_arm.spring_length = lerpf(spring_arm.spring_length, base_length + .9 * battle, 1.0 - exp(-2.5 * delta))
	_fade(clampf((fade_distance - reach) / (fade_distance - 1.0), 0.0, 1.0))
	_frame_fight(delta)
	# Rotation only: never move the lens through the spring arm's collision plane.
	# Tremor scales with impulse_degrees, so the Camera shake setting governs both.
	var rumble: Vector3 = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-.5, .5)) * deg_to_rad(impulse_degrees * 2.2) * tremor * tremor
	$SpringArm3D/Camera3D.rotation = Vector3(deg_to_rad(impulse_degrees) * impulse, 0, deg_to_rad(impulse_degrees) * impulse * 0.35) + rumble


func _fade(amount: float) -> void:
	if is_equal_approx(amount, faded):
		return
	faded = amount
	for mesh in fade_meshes:
		if is_instance_valid(mesh):
			mesh.transparency = .85 * amount


func _frame_fight(delta: float) -> void:
	if not controls_active or not focus.is_finite() or input_idle < assist_delay:
		assisting = false
		return
	var to: Vector3 = focus - global_position
	if Vector2(to.x, to.z).length() < 1.5:
		return
	var yaw: float = atan2(-to.x, -to.z)
	var offset: float = absf(angle_difference(rotation.y, yaw))
	if not assisting and offset > deg_to_rad(assist_dead_zone_degrees):
		assisting = true
	if assisting:
		rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-assist_rate * delta))
		spring_arm.rotation.x = lerp_angle(spring_arm.rotation.x, deg_to_rad(-20.0), 1.0 - exp(-1.5 * delta))
		if offset < deg_to_rad(8.0):
			assisting = false


func orbit(motion: Vector2) -> void:
	input_idle = 0.0
	assisting = false
	rotation.y = wrapf(rotation.y - motion.x * mouse_sensitivity, -PI, PI)
	spring_arm.rotation.x = clampf(
		spring_arm.rotation.x - motion.y * mouse_sensitivity,
		deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees)
	)


func set_capture(active: bool) -> void:
	controls_active = active
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
	capture_changed.emit(active)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		set_capture(false)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not controls_active:
			set_capture(true)
			get_viewport().set_input_as_handled()
		elif controls_active and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			base_length = maxf(min_distance, base_length - 0.4)
		elif controls_active and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			base_length = minf(max_distance, base_length + 0.4)
	elif event is InputEventMouseMotion and controls_active:
		orbit(event.screen_relative)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and DisplayServer.get_name() != "headless":
		set_capture(false)
