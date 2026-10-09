extends CharacterBody3D
## One slow pursuer: approach, commit to a direction, telegraph, swing, recover.

signal health_changed(value: int)
signal died

enum State { IDLE, APPROACH, TELEGRAPH, ATTACK, RECOVER, REACT, DEAD }

@export var max_health: int = 100
@export var move_speed: float = 2.4
@export var attack_distance: float = 1.65
@export var detection_distance: float = 10.0
@export_range(0, 0.5) var hit_reaction_duration: float = 0.2
@export_range(0, 8) var knockback_speed: float = 3.0
@export_range(0, 0.3) var hit_flash_duration: float = 0.12

var health: int = 100
var spawn_position: Vector3
var stagger_left: float = 0.0
var flash_left: float = 0.0
var knockback: Vector3 = Vector3.ZERO
var target: CharacterBody3D
var flash_material: StandardMaterial3D
var state: State = State.IDLE
var hitstop_left: float = 0.0
## Shown on the first sighting of this kind in a run; archetypes override both.
var title: String = "CORRUPTED RECORD"
var motto: String = "Success ≠ Failed ≠ Not Found"
## A Blocker's protection: damage is refused while this runs.
var shield_left: float = 0.0
var shell: MeshInstance3D
var blocked_cooldown: float = 0.0
@export_range(0, 3) var separation: float = 1.4
## Archetypes move relative to the encounter's base pursuit speed.
var speed_scale: float = 1.0
@onready var navigation: NavigationAgent3D = $NavigationAgent3D
@onready var visual: Node3D = $Visual
@onready var melee: Node3D = $Visual/Melee
@onready var tell: MeshInstance3D = $Visual/Telegraph
@onready var label: Label3D = $Label
@onready var body: MeshInstance3D = $Visual/Body


func _ready() -> void:
	label.font = preload("res://assets/fonts/barlow_condensed_bold.ttf")
	label.font_size = 44
	label.outline_size = 10
	label.modulate = Color(1, .85, .55)
	_make_bar()
	health_changed.connect(_update_bar.unbind(1))
	spawn_position = global_position
	target = get_tree().get_first_node_in_group("players") as CharacterBody3D
	flash_material = StandardMaterial3D.new()
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.albedo_color = Color(1, 0.9, 0.65)
	tell.mesh = melee.arc.mesh
	reset_enemy()


func reset_enemy() -> void:
	state = State.IDLE
	hitstop_left = 0.0
	health = max_health
	global_position = spawn_position
	velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	stagger_left = 0.0
	flash_left = 0.0
	visual.rotation = Vector3.ZERO
	visual.scale = Vector3.ONE
	body.material_override = null
	$Visual/LeftArm.rotation = Vector3.ZERO
	$Visual/RightArm.rotation = Vector3.ZERO
	$DefeatSound.stop()
	$ImpactSparks.clear()
	melee.cancel()
	visual.reset_pose()
	tell.hide()
	drop_shield()
	collision_layer = 4
	health_changed.emit(health)
	label.text = "PRODUCTION INCIDENT  /  %d" % health
	reset_physics_interpolation()


func receive_damage(amount: int, source: Vector3) -> bool:
	if health <= 0:
		return false
	if shield_left > 0:
		show_blocked()
		return false
	health = maxi(health - amount, 0)
	health_changed.emit(health)
	flash_left = hit_flash_duration
	stagger_left = hit_reaction_duration
	knockback = (global_position - Vector3(source.x, global_position.y, source.z)).normalized() * knockback_speed
	# A hit reacts visibly but does not cancel a committed enemy attack.
	# Otherwise repeated light attacks could stun-lock the only opponent.
	if health == 0:
		state = State.DEAD
		if DisplayServer.get_name() != "headless":
			$DefeatSound.play()
		melee.cancel()
		tell.hide()
		collision_layer = 0
		visual.defeat()
		label.text = "INCIDENT RESOLVED"
		died.emit()
	return true


## A slim health bar that only appears once the enemy has been hurt.
func _make_bar() -> void:
	for index in range(2):
		var bar: MeshInstance3D = MeshInstance3D.new()
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(.9, .07)
		bar.mesh = quad
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.no_depth_test = true
		material.render_priority = index
		material.albedo_color = Color(.05, .06, .07, .85) if index == 0 else Color(1, .42, .2)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bar.material_override = material
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bar.position.y = 2.35
		bar.name = "HealthBack" if index == 0 else "HealthFill"
		bar.hide()
		add_child(bar)


func _update_bar() -> void:
	var ratio: float = clampf(float(health) / maxf(1, max_health), 0, 1)
	var fill: QuadMesh = $HealthFill.mesh
	fill.size.x = .86 * ratio
	fill.center_offset.x = -.43 * (1.0 - ratio)
	$HealthBack.visible = health > 0 and health < max_health
	$HealthFill.visible = $HealthBack.visible


## Refused damage must still read as a hit: an amber spark, a clunk, a word.
func show_blocked() -> void:
	if blocked_cooldown > 0:
		return
	blocked_cooldown = .35
	$ImpactSparks.burst(global_position + Vector3.UP * 1.3, Color(1, .65, .15), Vector3.ZERO)
	label.text = "BLOCKED"
	if DisplayServer.get_name() != "headless":
		var clunk: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		clunk.stream = preload("res://assets/audio/sfx/metal_block.ogg")
		clunk.bus = &"Effects"
		clunk.volume_db = -6
		add_child(clunk)
		clunk.play()
		clunk.finished.connect(clunk.queue_free)


func protect(seconds: float) -> void:
	shield_left = maxf(shield_left, seconds)
	if shell == null:
		shell = MeshInstance3D.new()
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 1.05
		sphere.height = 2.5
		shell.mesh = sphere
		shell.position.y = 1.1
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(1, .62, .15, .22)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		shell.material_override = material
		shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(shell)
	shell.show()


func drop_shield() -> void:
	shield_left = 0
	if shell != null:
		shell.hide()


func apply_hitstop(duration: float) -> void:
	hitstop_left = maxf(hitstop_left, duration)
	melee.freeze_left = maxf(melee.freeze_left, duration)


func show_impact(color: Color) -> void:
	$ImpactSparks.burst(global_position + Vector3.UP * 1.2 - knockback.normalized() * .25, color, knockback)


## Gentle push away from nearby allies so a wave never fuses into one silhouette.
func _separation() -> Vector3:
	var push: Vector3 = Vector3.ZERO
	for other: Node in get_tree().get_nodes_in_group("enemies"):
		if other == self or not other is Node3D:
			continue
		var away: Vector3 = global_position - other.global_position
		away.y = 0
		var distance: float = away.length()
		if distance > 0.01 and distance < separation:
			push += away / distance * (separation - distance) / separation
	return push * 1.4


func _update_state() -> void:
	if health <= 0:
		state = State.DEAD
	elif melee.attacking:
		if melee.elapsed < melee.windup:
			state = State.TELEGRAPH
		elif melee.is_active():
			state = State.ATTACK
		else:
			state = State.RECOVER
	elif stagger_left > 0:
		state = State.REACT
	else:
		state = State.IDLE


func _physics_process(delta: float) -> void:
	if hitstop_left > 0:
		hitstop_left = maxf(0, hitstop_left - delta)
		return
	flash_left = maxf(0.0, flash_left - delta)
	body.material_override = flash_material if flash_left > 0 else null
	blocked_cooldown = maxf(0, blocked_cooldown - delta)
	if shield_left > 0:
		shield_left = maxf(0, shield_left - delta)
		if shield_left == 0:
			drop_shield()
	if health <= 0:
		return
	stagger_left = maxf(0.0, stagger_left - delta)
	_update_state()
	knockback = knockback.move_toward(Vector3.ZERO, delta * 18.0)
	var direction: Vector3 = Vector3.ZERO
	if is_instance_valid(target) and target.health > 0:
		var offset: Vector3 = target.global_position - global_position
		var planar: Vector3 = Vector3(offset.x, 0, offset.z)
		if state == State.IDLE and planar.length() < detection_distance:
			visual.rotation.y = atan2(-planar.x, -planar.z)
			if planar.length() <= attack_distance and absf(offset.y) < 0.7:
				var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, target.global_position + Vector3.UP, 1)
				# A crowd takes turns: the incident caps simultaneous telegraphs.
				var allowed: bool = not get_parent().has_method("request_attack") or get_parent().request_attack(self)
				if allowed and get_world_3d().direct_space_state.intersect_ray(query).is_empty():
					melee.start()
					state = State.TELEGRAPH
			# Being close through furniture is not an attack opportunity: keep routing.
			if state != State.TELEGRAPH:
				state = State.APPROACH
				direction = planar.normalized()
				# The office has furniture; use its baked routes without changing attacks.
				if NavigationServer3D.map_get_iteration_id(navigation.get_navigation_map()) > 0:
					navigation.target_position = target.global_position
					var next: Vector3 = navigation.get_next_path_position() - global_position
					direction = Vector3(next.x, 0, next.z).normalized()
				direction = (direction + _separation()).normalized()
	# Enemies do not collide with each other; a constant gentle spread keeps a
	# crowd readable even while it stands and swings.
	var spread: Vector3 = _separation() * 1.2
	velocity.x = direction.x * move_speed + knockback.x + spread.x
	velocity.z = direction.z * move_speed + knockback.z + spread.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 22.0 * delta
	move_and_slide()
	tell.visible = state == State.TELEGRAPH
	if tell.visible:
		# The warning shows the full damage reach from the first wind-up frame.
		tell.scale = Vector3.ONE
	# Overhead text is reserved for states the arc cannot show.
	label.text = "STAGGERED" if state == State.REACT else ""
	if blocked_cooldown > 0 or shield_left > 0:
		label.text = "BLOCKED" if blocked_cooldown > 0 else "PROTECTED"
	if global_position.y < -8:
		reset_enemy()
