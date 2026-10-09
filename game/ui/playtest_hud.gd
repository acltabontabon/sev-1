extends CanvasLayer

var hit_left: float = 0.0
var hurt_left: float = 0.0
@onready var player: CharacterBody3D = %Player
@onready var enemy: CharacterBody3D = %Enemy
@onready var camera_rig: Node3D = %Player/CameraRig
@onready var prompt: Control = $CapturePrompt
@onready var status: Label = $Margin/VBox/Status


func _ready() -> void:
	if get_parent().has_node("Incident"):
		var backdrop: StyleBoxFlat = StyleBoxFlat.new()
		backdrop.bg_color = Color(.025, .045, .055, .96)
		$CapturePrompt/Panel.add_theme_stylebox_override("panel", backdrop)
	camera_rig.capture_changed.connect(_on_capture_changed)
	player.health_changed.connect(_on_health_changed)
	enemy.health_changed.connect(_on_health_changed)
	player.hit_confirmed.connect(_on_hit)
	player.hurt.connect(_on_hurt)
	refresh()


func _on_capture_changed(_active: bool) -> void:
	refresh()


func _on_health_changed(_value: int) -> void:
	refresh()


func refresh() -> void:
	var incident: Node = get_parent().get_node_or_null("Incident")
	if incident != null and incident.is_node_ready():
		_refresh_incident(incident)
		return
	prompt.visible = not camera_rig.controls_active
	status.text = "OFFICE AFTER HOURS   /   LIVE" if camera_rig.controls_active else "OFFICE AFTER HOURS   /   PAUSED"
	$Margin/VBox/Health.text = "YOU  %d / %d     |     INCIDENT  %d / %d" % [player.health, player.max_health, enemy.health, enemy.max_health]
	if player.health <= 0:
		status.text = "YOU ARE OFFLINE  /  R TO RETRY"
		$CapturePrompt/Panel/Padding/Text.text = "YOU ARE OFFLINE\n\nPress R to reset the encounter.\nThen click to resume."
	elif enemy.health <= 0:
		status.text = "INCIDENT RESOLVED  /  R TO RUN IT BACK"
		$CapturePrompt/Panel/Padding/Text.text = "INCIDENT RESOLVED\n\nPress R for another round.\nClick to keep exploring."
	else:
		$CapturePrompt/Panel/Padding/Text.text = "FRIDAY 16:59  /  CLICK TO BEGIN\n\nLMB or F: three-hit chain. Press again near recovery.\nQ or right mouse: dodge. Move to choose direction.\nNo movement input: dodge backward.\n\nWatch the orange warning. Cyan means invulnerable.\nR resets both fighters. Escape pauses."


func _on_hit() -> void:
	hit_left = 0.18
	$HitFeedback.text = "HIT  −%d" % player.melee.damage


func _on_hurt() -> void:
	hurt_left = 0.2


func _process(delta: float) -> void:
	if get_parent().has_node("Incident"):
		refresh()
	hit_left = maxf(0, hit_left - delta)
	hurt_left = maxf(0, hurt_left - delta)
	$HitFeedback.visible = hit_left > 0
	$DamageFlash.color.a = hurt_left * 0.75
	if get_parent().has_node("Incident") and get_parent().get_node("Incident").terminal():
		$Margin/VBox/AttackState.text = "R TO RESTART INCIDENT"
	elif player.health <= 0:
		$Margin/VBox/AttackState.text = "R TO RESTART"
	elif player.dodging:
		$Margin/VBox/AttackState.text = "DODGE  /  INVULNERABLE" if player.dodge_is_invulnerable() else "DODGE  /  RECOVERY"
	elif player.melee.attacking:
		var phase: String = "WIND-UP" if player.melee.elapsed < player.melee.windup else ("STRIKE" if player.melee.is_active() else "RECOVERY")
		var queue_text: String = "  /  NEXT QUEUED" if player.combo_buffer_left > 0 else ""
		$Margin/VBox/AttackState.text = "%d / 3  %s  /  %s%s" % [player.combo_index + 1, player.combo[player.combo_index].title, phase, queue_text]
	else:
		$Margin/VBox/AttackState.text = "READY  /  LMB OR F   •   Q OR RMB TO DODGE"


func _refresh_incident(incident: Node) -> void:
	$Margin/VBox/Title.text = "SEV—1   /   THE MISSING TRANSACTION"
	status.text = incident.objective
	if incident.stage == incident.Stage.INVESTIGATION and incident.inspected and not incident.near_console():
		status.text = "Return to the OPERATIONS marker to select a record."
	$Margin/VBox/Health.text = "YOU  %d / %d" % [player.health, player.max_health]
	if is_instance_valid(incident.active_enemy):
		var foe: CharacterBody3D = incident.active_enemy
		$Margin/VBox/Health.text += "     |     %s  %d / %d" % ["THE VARIANCE" if incident.stage == incident.Stage.BOSS else "RECORD", foe.health, foe.max_health]
	$Controls.text = incident.message + "\nE  Inspect   •   WASD  Move   •   LMB/F  Combo   •   Q/RMB  Dodge   •   R  Restart   •   Esc  Pause"
	$Controls.offset_top = -112
	prompt.visible = not camera_rig.controls_active or incident.terminal()
	$CapturePrompt/Panel/Padding/Text.text = incident.report if incident.terminal() else "FRIDAY, 4:59 PM\nOne payment. Three systems. Nobody agrees.\n\nClick to begin / resume\nWASD move • Mouse aim • LMB/F three-hit combo\nQ / right mouse dodge • E inspect operations\n\nWatch orange warnings. Strike during recovery.\nR restarts the entire incident."
