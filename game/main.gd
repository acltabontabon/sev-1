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
	var incident: Node = get_node_or_null("Incident")
	if active and incident != null and (incident.terminal() or incident.modal_pending()):
		player.camera_rig.set_capture(false)
		return
	get_tree().paused = not active


func _on_player_died() -> void:
	enemy.melee.cancel()
	if has_node("Incident"):
		# The incident lets the fall play out, then releases the mouse for the report.
		$Incident.fail()
		return
	player.camera_rig.set_capture(false)


func reset_encounter() -> void:
	get_tree().call_group("breakables", "reset_prop")
	player.reset_player()
	if has_node("Incident"):
		$Incident.reset_incident()
	else:
		enemy.reset_enemy()
	$HUD.hit_left = 0.0
	$HUD.hurt_left = 0.0
	$HUD.refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_player") and not event.is_echo():
		reset_encounter()
		get_viewport().set_input_as_handled()
