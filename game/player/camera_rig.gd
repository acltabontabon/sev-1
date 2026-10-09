extends Node3D
## Orbit independently of the character's facing; the spring arm handles walls.

signal capture_changed(active: bool)

@export_range(0.0005, 0.01) var mouse_sensitivity: float = 0.0025
@export var min_pitch_degrees: float = -65.0
@export var max_pitch_degrees: float = 25.0
@export var min_distance: float = 2.0
@export var max_distance: float = 7.0

var controls_active: bool = false
@onready var spring_arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	spring_arm.add_excluded_object((get_parent() as CollisionObject3D).get_rid())
	reset_view()


func reset_view() -> void:
	rotation = Vector3.ZERO
	spring_arm.rotation.x = deg_to_rad(-18.0)
	spring_arm.spring_length = 5.0


func orbit(motion: Vector2) -> void:
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
			spring_arm.spring_length = maxf(min_distance, spring_arm.spring_length - 0.4)
		elif controls_active and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = minf(max_distance, spring_arm.spring_length + 0.4)
	elif event is InputEventMouseMotion and controls_active:
		orbit(event.screen_relative)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and DisplayServer.get_name() != "headless":
		set_capture(false)
