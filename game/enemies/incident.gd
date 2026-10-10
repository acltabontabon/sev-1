extends CharacterBody3D
## One slow pursuer: approach, commit to a direction, telegraph, swing, recover.

signal health_changed(value: int)
signal died

enum State { IDLE, APPROACH, TELEGRAPH, ATTACK, RECOVER, REACT, DEAD }
## Incident arrivals are not omniscient: they materialize, go about their "work",
## and only commit once they see, hear or are told about the engineer.
enum Awareness { MANIFESTING, UNAWARE, NOTICING, ENGAGED, SEARCHING }
const ACTIVITIES: Array[String] = ["RECONCILING…", "IN A MEETING", "OOO (NOT REALLY)", "WAITING ON QA", "UPDATING THE TICKET", "LOW BATTERY", "SYNCING…", "REFRESHING DASHBOARD"]

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
## Lab opponents and bosses are always hunting; incident waves start unaware.
@export var starts_aware: bool = true
@export var sight_range: float = 14.0
@export_range(30, 360) var sight_fov: float = 140.0
## Unaware this long, the incident assigns the engineer to them anyway.
@export var patience: float = 14.0
var awareness: Awareness = Awareness.ENGAGED
var awareness_left: float = 0.0
var unaware_time: float = 0.0
var sense_left: float = 0.0
var lost_left: float = 0.0
var last_seen: Vector3
var home: Vector3
var wander_target: Vector3
var wander_left: float = 0.0
var orbit_sign: float = 1.0
var backoff_left: float = 0.0
var was_attacking: bool = false
var activity: String = ""
## Spell identity, overridden by archetypes in _ready. Presentation only: a sigil under
## the caster on every telegraph, a release on the strike, a burst on defeat.
var magic_color: Color = Color(1, .22, .3)
var magic_accent: Color = Color(.3, 1, .55)
var magic_words: Array = ["NULL", "404", "NaN", "0x0", "ROLLBACK?", "DUPLICATE"]
var magic_radius: float = 1.1
## How the strike lands: slash (crack + crescent), quake (ground slam), splat, cataclysm.
var attack_style: String = "slash"
var last_state: State = State.IDLE
## Which CC0 rigged body to wear (MonsterRig.KINDS); archetypes set it before super._ready().
var rig_kind: String = "record"
var rig: MonsterRig
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
	if rig_kind != "":
		rig = MonsterRig.create(rig_kind, self)
		visual.add_child(rig)
		for part: String in ["Visual/Body", "Visual/Eye", "Visual/LeftArm", "Visual/RightArm"]:
			get_node(part).hide()
		# Keep the record's never-finishing loading halo and orbiting pages; drop the slabs.
		for child: Node in $Visual/RecordDetails.get_children():
			if child.name != "Throbber" and child.name != "Pages":
				(child as Node3D).hide()
		# Bars and labels clear the head of taller bodies.
		var top: float = maxf(2.35, MonsterRig.KINDS[rig_kind].height + .35)
		$HealthBack.position.y = top
		$HealthFill.position.y = top
		label.position.y = maxf(label.position.y, top + .2)
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
	ElementFx.clear_from(self)
	last_state = State.IDLE
	if rig != null:
		rig.reset()
	melee.cancel()
	visual.reset_pose()
	tell.hide()
	drop_shield()
	awareness = Awareness.ENGAGED if starts_aware else Awareness.MANIFESTING
	awareness_left = .9
	unaware_time = 0.0
	lost_left = 0.0
	backoff_left = 0.0
	home = global_position
	wander_target = home
	last_seen = home
	orbit_sign = 1.0 if get_instance_id() % 2 == 0 else -1.0
	activity = ACTIVITIES[get_instance_id() % ACTIVITIES.size()]
	collision_layer = 4
	health_changed.emit(health)
	label.text = ""
	reset_physics_interpolation()


func receive_damage(amount: int, source: Vector3) -> bool:
	if health <= 0:
		return false
	if shield_left > 0:
		show_blocked()
		return false
	if awareness != Awareness.ENGAGED and awareness != Awareness.NOTICING:
		# Surprise code review: the first hit on an unaware record lands double.
		amount *= 2
		label.text = "SURPRISE REVIEW ×2"
		awareness_left = 0.0
		engage(source, true)
		if get_parent().has_method("on_surprise"):
			get_parent().on_surprise(self)
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
		_dissolve_magic()
		died.emit()
	return true


## Commit to the engineer now; optionally pass the word to nearby colleagues.
func engage(seen: Vector3 = Vector3.INF, propagate: bool = false) -> void:
	if health <= 0:
		return
	var was: Awareness = awareness
	awareness = Awareness.ENGAGED
	lost_left = 0.0
	if seen != Vector3.INF:
		last_seen = seen
	elif is_instance_valid(target):
		last_seen = target.global_position
	if propagate and was != Awareness.ENGAGED:
		_alert_allies()


## The beat of realizing: turn, flag it, tell the team. Then the chase.
func notice(propagate: bool = true) -> void:
	if health <= 0 or awareness in [Awareness.NOTICING, Awareness.ENGAGED]:
		return
	awareness = Awareness.NOTICING
	awareness_left = randf_range(.45, .7)
	label.text = "ASSIGNED TO YOU"
	if DisplayServer.get_name() != "headless":
		var ping: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		ping.stream = preload("res://assets/audio/sfx/chat_ping_soft.ogg")
		ping.bus = &"Effects"
		ping.volume_db = -4
		ping.pitch_scale = randf_range(.9, 1.15)
		add_child(ping)
		ping.play()
		ping.finished.connect(ping.queue_free)
	if propagate:
		_alert_allies()
	if get_parent().has_method("on_enemy_noticed"):
		get_parent().on_enemy_noticed(self)


func _alert_allies() -> void:
	for other: Node in get_tree().get_nodes_in_group("enemies"):
		if other != self and other is CharacterBody3D and other.has_method("notice") and other.global_position.distance_to(global_position) < 10.0:
			other.notice(false)


## Sight in a forward cone with line of sight, hearing for loud actions, touch.
func _senses() -> bool:
	if not is_instance_valid(target) or target.health <= 0:
		return false
	var offset: Vector3 = target.global_position - global_position
	var distance: float = Vector2(offset.x, offset.z).length()
	if distance < 2.2:
		return true
	if (target.melee.attacking and distance < 9.0) or (target.dodging and distance < 6.0) or (Vector2(target.velocity.x, target.velocity.z).length() > 6.5 and distance < 7.0):
		return true
	if distance > sight_range:
		return false
	var facing: Vector3 = Vector3(-sin(visual.rotation.y), 0, -cos(visual.rotation.y))
	if facing.dot(Vector3(offset.x, 0, offset.z).normalized()) < cos(deg_to_rad(sight_fov * .5)):
		return false
	return _line_of_sight()


func _line_of_sight() -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.5, target.global_position + Vector3.UP * 1.5, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Advances awareness; returns the movement wish for non-engaged behavior,
## or null when the enemy is engaged and the combat steering should run.
func _awareness(delta: float) -> Variant:
	sense_left -= delta
	var sensing: bool = sense_left <= 0
	if sensing:
		sense_left = .2
	match awareness:
		Awareness.MANIFESTING:
			awareness_left -= delta
			visual.scale = Vector3(1, 1, 1) * (1.0 - .25 * absf(sin(awareness_left * 40.0)) * awareness_left)
			if awareness_left <= 0:
				visual.scale = Vector3.ONE
				awareness = Awareness.UNAWARE
			return Vector3.ZERO
		Awareness.NOTICING:
			awareness_left -= delta
			_face(target.global_position)
			if awareness_left <= 0:
				engage()
			return Vector3.ZERO
		Awareness.UNAWARE:
			unaware_time += delta
			if (sensing and _senses()) or unaware_time > patience:
				notice()
				return Vector3.ZERO
			# Busywork: drift between nearby spots at a stroll.
			wander_left -= delta
			if wander_left <= 0 or global_position.distance_to(wander_target) < .5:
				wander_left = randf_range(2.5, 4.5)
				var angle: float = randf() * TAU
				wander_target = home + Vector3(cos(angle), 0, sin(angle)) * randf_range(.5, 2.5)
			return _route(wander_target) * .3
		Awareness.SEARCHING:
			if sensing and _senses():
				notice()
				return Vector3.ZERO
			awareness_left -= delta
			if global_position.distance_to(last_seen) > 1.0 and awareness_left > 2.5:
				return _route(last_seen) * .7
			visual.rotation.y += delta * 1.6 * orbit_sign
			if awareness_left <= 0:
				home = global_position
				unaware_time = 0.0
				awareness = Awareness.UNAWARE
			return Vector3.ZERO
	# Engaged: keep a memory of where the engineer was; long losses become a search.
	if sensing and not starts_aware:
		if _line_of_sight():
			last_seen = target.global_position
			lost_left = 0.0
		else:
			lost_left += .2
			if lost_left > 5.0 and global_position.distance_to(target.global_position) > 9.0:
				awareness = Awareness.SEARCHING
				awareness_left = 7.0
	return null


func _route(point: Vector3) -> Vector3:
	var direction: Vector3 = Vector3(point.x - global_position.x, 0, point.z - global_position.z).normalized()
	if NavigationServer3D.map_get_iteration_id(navigation.get_navigation_map()) > 0:
		navigation.target_position = point
		var next: Vector3 = navigation.get_next_path_position() - global_position
		direction = Vector3(next.x, 0, next.z).normalized()
	if not direction.is_zero_approx():
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), .2)
	return direction


func _face(point: Vector3) -> void:
	var planar: Vector3 = Vector3(point.x - global_position.x, 0, point.z - global_position.z)
	if not planar.is_zero_approx():
		visual.rotation.y = atan2(-planar.x, -planar.z)


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


func _cast_magic() -> void:
	ElementFx.sigil(self, global_position, magic_color, magic_radius, melee.windup + melee.active_time + .15, 2.2)
	ElementFx.motes(self, global_position + Vector3.UP * .2, magic_color, 10, 1.6, melee.windup + .1, 2.5, .12)
	if attack_style == "quake" or attack_style == "cataclysm":
		# The floor starts to rumble under a heavy wind-up.
		ElementFx.dust(self, global_position, .6, melee.windup)
		ElementFx.tremor(self, global_position, .25, 10.0)


func _release_magic() -> void:
	var forward: Vector3 = -visual.global_basis.z
	forward = Vector3(forward.x, 0, forward.z).normalized()
	var ground: Vector3 = global_position
	var front: Vector3 = ground + forward * melee.reach * .6
	match attack_style:
		"quake":
			ElementFx.quake(self, front, magic_color, 2.4, .85)
		"cataclysm":
			ElementFx.quake(self, front, magic_color, 3.4, 1.0)
			ElementFx.quake(self, ground, magic_accent, 2.0, .3)
			ElementFx.fissure(self, front, ground + forward * 9.0, magic_accent)
			for side in [-1.0, 1.0]:
				ElementFx.fissure(self, front, ground + forward.rotated(Vector3.UP, side * .6) * 7.0, magic_color, .8)
			ElementFx.bolt(self, global_position + Vector3.UP * 3.4, front, magic_accent, .3, .1)
		"splat":
			ElementFx.motes(self, front + Vector3.UP * .3, magic_color, 26, 5.0, .55, -9.0, .2)
			ElementFx.shards(self, front + Vector3.UP * .4, magic_accent, 12, 5.0, .9, Vector3.UP, .14)
			ElementFx.shockwave(self, front, magic_color, 2.6, .4)
			ElementFx.tremor(self, front, .3, 6.0)
		_:
			ElementFx.gust(self, ground + Vector3.UP * 1.1 + forward * .3, visual.global_basis, magic_color, 2.4, .3)
			ElementFx.fissure(self, ground + forward * .5, ground + forward * (melee.reach + 1.2), magic_color, .6)
			ElementFx.shards(self, ground + Vector3.UP * 1.1 + forward * .4, magic_accent, 10, 4.5, .6, forward + Vector3.UP * .4)
			ElementFx.tremor(self, front, .3, 7.0)
	ElementFx.glyphs(self, global_position + Vector3.UP * 2.0, magic_color, [magic_words.pick_random()], .6, .3)


func _dissolve_magic() -> void:
	ElementFx.motes(self, global_position + Vector3.UP * .9, magic_color, 30, 4.0, .9, 1.5, .16)
	ElementFx.shards(self, global_position + Vector3.UP * .9, magic_accent, 16, 4.0, 1.1)
	ElementFx.shockwave(self, global_position, magic_color, 2.6, .5)


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
	if state != last_state:
		if state == State.TELEGRAPH:
			_cast_magic()
		elif state == State.ATTACK:
			_release_magic()
		last_state = state
	knockback = knockback.move_toward(Vector3.ZERO, delta * 18.0)
	var direction: Vector3 = Vector3.ZERO
	var pace: float = 1.0
	var wish: Variant = _awareness(delta) if is_instance_valid(target) and target.health > 0 else Vector3.ZERO
	if wish != null:
		direction = wish
		pace = direction.length()
		direction = direction.normalized()
		if state == State.IDLE and not direction.is_zero_approx():
			state = State.APPROACH
	elif is_instance_valid(target) and target.health > 0:
		var offset: Vector3 = target.global_position - global_position
		var planar: Vector3 = Vector3(offset.x, 0, offset.z)
		var distance: float = planar.length()
		# After a swing, step back out of the engineer's counter instead of standing in it.
		if was_attacking and not melee.attacking and not starts_aware:
			backoff_left = .55
		was_attacking = melee.attacking
		backoff_left = maxf(0, backoff_left - delta)
		if state == State.IDLE and distance < detection_distance:
			visual.rotation.y = atan2(-planar.x, -planar.z)
			var allowed: bool = not get_parent().has_method("request_attack") or get_parent().request_attack(self)
			if distance <= attack_distance and absf(offset.y) < 0.7:
				var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, target.global_position + Vector3.UP, 1)
				# A crowd takes turns: the incident caps simultaneous telegraphs.
				if allowed and get_world_3d().direct_space_state.intersect_ray(query).is_empty():
					melee.start()
					state = State.TELEGRAPH
			# Being close through furniture is not an attack opportunity: keep routing.
			if state != State.TELEGRAPH:
				state = State.APPROACH
				if backoff_left > 0:
					direction = -planar.normalized()
					pace = .6
				elif not allowed and distance < 3.6 and not starts_aware:
					# Waiting for a turn: circle at a respectful distance instead of queueing in place.
					var tangent: Vector3 = planar.normalized().cross(Vector3.UP) * orbit_sign
					direction = (tangent + planar.normalized() * (distance - 2.8) * .8).normalized()
					pace = .55
				else:
					# Approach from staggered angles so a wave surrounds rather than stacks.
					var goal: Vector3 = target.global_position
					if distance > 4.0 and not starts_aware:
						goal += (-planar.normalized()).rotated(Vector3.UP, orbit_sign * .6) * 2.2
					direction = planar.normalized()
					# The office has furniture; use its baked routes without changing attacks.
					if NavigationServer3D.map_get_iteration_id(navigation.get_navigation_map()) > 0:
						navigation.target_position = goal
						var next: Vector3 = navigation.get_next_path_position() - global_position
						direction = Vector3(next.x, 0, next.z).normalized()
					direction = (direction + _separation()).normalized()
	# Enemies do not collide with each other; a constant gentle spread keeps a
	# crowd readable even while it stands and swings.
	var spread: Vector3 = _separation() * 1.2
	velocity.x = direction.x * move_speed * pace + knockback.x + spread.x
	velocity.z = direction.z * move_speed * pace + knockback.z + spread.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 22.0 * delta
	move_and_slide()
	tell.visible = state == State.TELEGRAPH
	if tell.visible:
		# The warning shows the full damage reach from the first wind-up frame.
		tell.scale = Vector3.ONE
	# Overhead text is reserved for states the arc cannot show.
	if awareness == Awareness.NOTICING or label.text == "SURPRISE REVIEW ×2" and stagger_left > 0:
		pass
	elif awareness == Awareness.UNAWARE and is_instance_valid(target) and target.global_position.distance_to(global_position) < 12.0:
		label.text = activity
	elif awareness == Awareness.SEARCHING:
		label.text = "LOOKING FOR AN OWNER…"
	else:
		label.text = "STAGGERED" if state == State.REACT else ""
	if blocked_cooldown > 0 or shield_left > 0:
		label.text = "BLOCKED" if blocked_cooldown > 0 else "PROTECTED"
	if global_position.y < -8:
		reset_enemy()
