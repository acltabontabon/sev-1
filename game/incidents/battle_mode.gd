extends CanvasLayer
## Battle mode: when an enemy commits to the fight, the office answers. An onset hit
## (flash, chromatic split, speed lines, sting), then a held combat grade while anyone is
## engaged: vignette, hotter glow, the engineer's eyes and RGB keyboard lit. Presentation
## only; it reads enemy awareness and never changes combat.

const STING: AudioStream = preload("res://assets/audio/sfx/heavy_impact.ogg")
var level: float = 0.0
var onset: float = 0.0
var engaged: bool = false
var overlay: ColorRect
var material: ShaderMaterial
var environment: Environment
var base_glow: float = 0.0
var base_saturation: float = 1.0
var base_contrast: float = 1.0
var sting: AudioStreamPlayer
var player: Node3D


func _ready() -> void:
	# Below the HUD and story layers, above the 3D view.
	layer = -1
	material = ShaderMaterial.new()
	material.shader = preload("res://game/incidents/battle_overlay.gdshader")
	overlay = ColorRect.new()
	overlay.name = "BattleGrade"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.material = material
	overlay.hide()
	add_child(overlay)
	sting = AudioStreamPlayer.new()
	sting.stream = STING
	sting.bus = &"Effects"
	sting.volume_db = -10.0
	add_child(sting)
	player = get_tree().get_first_node_in_group("players") as Node3D
	var world: World3D = get_viewport().find_world_3d()
	environment = world.environment if world != null else null
	if environment != null:
		base_glow = environment.glow_intensity
		base_saturation = environment.adjustment_saturation
		base_contrast = environment.adjustment_contrast


func reset() -> void:
	level = 0.0
	onset = 0.0
	engaged = false
	sting.stop()
	ElementFx.release_freeze()
	_apply()


## Centre of the engaged enemies near the engineer, weighted to the closest; INF if none.
func fight_focus() -> Vector3:
	var total: Vector3 = Vector3.ZERO
	var weight: float = 0.0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: CharacterBody3D = node as CharacterBody3D
		if enemy == null or not enemy.is_inside_tree() or enemy.health <= 0 or enemy.awareness != enemy.Awareness.ENGAGED or not enemy.visible:
			continue
		var distance: float = enemy.global_position.distance_to(player.global_position)
		if distance > 12.0:
			continue
		var share: float = 1.0 / maxf(distance, 1.0)
		total += enemy.global_position * share
		weight += share
	return total / weight if weight > 0.0 else Vector3.INF


func fighting() -> bool:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: CharacterBody3D = node as CharacterBody3D
		if enemy != null and enemy.is_inside_tree() and enemy.health > 0 and enemy.awareness == enemy.Awareness.ENGAGED and enemy.visible:
			return true
	return false


func _process(delta: float) -> void:
	var now: bool = fighting() and player != null and player.health > 0
	if now and not engaged:
		onset = 1.0
		material.set_shader_parameter("seed", randf() * 50.0)
		if DisplayServer.get_name() != "headless":
			sting.play()
	engaged = now
	level = move_toward(level, 1.0 if now else 0.0, delta * (3.0 if now else .7))
	onset = maxf(0.0, onset - delta * 1.8)
	_apply()


func _apply() -> void:
	overlay.visible = level > .001 or onset > .001
	material.set_shader_parameter("vignette", .55 * level + .35 * onset)
	material.set_shader_parameter("aberration", .003 * onset)
	material.set_shader_parameter("lines", onset * onset)
	material.set_shader_parameter("flash", .18 * onset * onset * onset)
	if environment != null:
		environment.glow_intensity = base_glow * (1.0 + .25 * level)
		environment.adjustment_saturation = base_saturation * (1.0 + .04 * level)
		environment.adjustment_contrast = base_contrast * (1.0 + .04 * level)
	if player != null and "battle" in player.presentation:
		player.presentation.battle = level
	if player != null:
		player.camera_rig.battle = level
		player.camera_rig.focus = fight_focus() if engaged else Vector3.INF
