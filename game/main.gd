extends Node3D
## Own the small encounter's pause/reset lifecycle; no persistent run systems.

@onready var player: CharacterBody3D = $Player
@onready var enemy: CharacterBody3D = $Enemy


func _ready() -> void:
	player.camera_rig.capture_changed.connect(_on_capture_changed)
	player.died.connect(_on_player_died)
	player.reset_requested.connect(reset_encounter)
	get_tree().paused = not player.camera_rig.controls_active


func _on_capture_changed(active: bool) -> void:
	get_tree().paused = not active


func _on_player_died() -> void:
	player.camera_rig.set_capture(false)


func reset_encounter() -> void:
	player.reset_player()
	enemy.reset_enemy()
	$HUD.hit_left = 0.0
	$HUD.hurt_left = 0.0
	$HUD.refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_player") and not event.is_echo():
		reset_encounter()
		get_viewport().set_input_as_handled()
