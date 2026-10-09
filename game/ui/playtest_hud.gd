extends CanvasLayer

var hit_left: float = 0.0
var hurt_left: float = 0.0
@onready var player: CharacterBody3D = %Player
@onready var enemy: CharacterBody3D = %Enemy
@onready var camera_rig: Node3D = %Player/CameraRig
@onready var prompt: Control = $CapturePrompt
@onready var status: Label = $Margin/VBox/Status


func _ready() -> void:
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
	prompt.visible = not camera_rig.controls_active
	status.text = "COMBAT LAB   /   LIVE" if camera_rig.controls_active else "COMBAT LAB   /   PAUSED"
	$Margin/VBox/Health.text = "YOU  %d / %d     |     INCIDENT  %d / %d" % [player.health, player.max_health, enemy.health, enemy.max_health]
	if player.health <= 0:
		status.text = "YOU ARE OFFLINE  /  R TO RETRY"
		$CapturePrompt/Panel/Padding/Text.text = "YOU ARE OFFLINE\n\nPress R to reset the encounter.\nThen click to resume."
	elif enemy.health <= 0:
		status.text = "INCIDENT RESOLVED  /  R TO RUN IT BACK"
		$CapturePrompt/Panel/Padding/Text.text = "INCIDENT RESOLVED\n\nPress R for another round.\nClick to keep exploring."
	else:
		$CapturePrompt/Panel/Padding/Text.text = "CLICK TO ENTER THE COMBAT LAB\n\nAim the camera toward the incident.\nLeft click or F swings the baton.\nStep aside when it winds up.\n\nR resets both fighters. Escape pauses."


func _on_hit() -> void:
	hit_left = 0.18
	$HitFeedback.text = "HIT  −%d" % player.melee.damage


func _on_hurt() -> void:
	hurt_left = 0.2


func _process(delta: float) -> void:
	hit_left = maxf(0, hit_left - delta)
	hurt_left = maxf(0, hurt_left - delta)
	$HitFeedback.visible = hit_left > 0
	$DamageFlash.color.a = hurt_left * 0.75
	if player.health <= 0:
		$Margin/VBox/AttackState.text = "R TO RESTART"
	elif player.melee.attacking:
		$Margin/VBox/AttackState.text = "SWINGING" if player.melee.elapsed < player.melee.windup + player.melee.active_time else "RECOVERING"
	else:
		$Margin/VBox/AttackState.text = "BATON READY  /  LMB OR F"
