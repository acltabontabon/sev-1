extends Node3D
## A place the engineer can use with E. Distance-checked, so staged positions
## (and tests) act in the same frame. The incident owns what using it means.

signal used
@export var radius: float = 1.9
@export var prompt: String = "E — USE"
var enabled: bool = true
var label: Label3D


func _ready() -> void:
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.pixel_size = .0035
	label.outline_size = 10
	label.modulate = Color(.55, .95, 1)
	label.position.y = 1.85
	label.no_depth_test = true
	add_child(label)
	label.hide()


func in_range(body: Node3D) -> bool:
	return enabled and body.global_position.distance_to(global_position) < radius


func refresh(body: Node3D, allowed: bool) -> void:
	label.visible = allowed and in_range(body)
	label.text = prompt
