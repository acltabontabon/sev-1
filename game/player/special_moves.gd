extends Node
## The engineer's special moves, on top of the three-hit combo. Both reuse the combo's own
## swings for the body (rigged_engineer.gd animates combo steps), and fire on the swing's
## active frame so the visible strike and the effect agree.
##
## REPLY ALL (C / middle mouse): an overhead cut throws a crescent blade 13 m forward
## that hits everyone in its path ("RE: RE: RE:") until a wall breaks it. 3.5 s cooldown.
## FORCE ROLLBACK (V): the ultimate, omnislash style. Landed hits fill FOCUS; at 100 the
## world crawls while the engineer blinks between the enemies within 9 m for seven cuts
## (rolling back seven commits), then returns to the centre and slams everything within
## 7.5 m (shields included).
## BLAME SHIFT (X, or attack out of a dodge): a 7 m dash straight through enemies, cutting
## each one the instant it is passed and leaving it BLAMED: +30% damage taken for 4 s.
## The path flashes white on arrival. 2.5 s cooldown.
## CIRCLE BACK (Z): a steerable fire whirlwind for 1.4 s that hits everything within 3 m
## four times and drags it inward; the last pulse sends survivors to the PARKING LOT
## (stunned 1.2 s). 6 s cooldown.
## WORKS ON MY MACHINE (G): a 0.6 s counter stance inside a "localhost" dome. Anything
## that hits the engineer in the window does nothing; the attacker takes the blame instead
## (60 damage, knocked back, staggered, CANNOT REPRODUCE) and the engineer spins into a
## riposte; most of the cooldown comes back and FOCUS +20. A whiff leaves a short,
## vulnerable recovery and the full 3 s cooldown.

signal focus_changed(value: float)
## Fired after the final impact, never on request, cancellation or individual blinks.
signal rollback_completed
## A move was called out loud (anime style): its name, and whether it is the ultimate.
signal called(title: String, ultimate: bool)
## Each blink of the Force Rollback omnislash: where the engineer appeared, the target,
## and the slash number (OMNI_SLASHES is the return to the centre before the slam).
signal omnislash_step(at: Vector3, target: Vector3, index: int)

const WAVE_COOLDOWN: float = 3.5
const WAVE_RANGE: float = 13.0
const WAVE_SPEED: float = 24.0
const WAVE_DAMAGE: int = 45
## Half the blade's width; enemies this close to its path are cut.
const WAVE_HALF_WIDTH: float = 1.7
const WAVE_COLOR: Color = Color(.45, .95, 1)
const ROLLBACK_RADIUS: float = 7.5
const ROLLBACK_DAMAGE: int = 110
const ROLLBACK_COLOR: Color = Color(.62, .5, 1)
const FOCUS_PER_HIT: float = 9.0
## Force Rollback, omnislash style: seven blinks between the enemies around the
## engineer (one cut each), then back to the centre for the slam.
const OMNI_SLASHES: int = 7
const OMNI_RANGE: float = 9.0
const OMNI_DAMAGE: int = 30
const OMNI_LEAD: float = .4
const OMNI_BEAT: float = .17
const DASH_DISTANCE: float = 7.0
const DASH_TIME: float = .2
const DASH_COOLDOWN: float = 2.5
const DASH_DAMAGE: int = 55
const DASH_HALF_WIDTH: float = 1.5
const DASH_COLOR: Color = Color(1, .85, .35)
const SPIN_TIME: float = 1.4
const SPIN_TICKS: int = 4
const SPIN_RADIUS: float = 3.0
const SPIN_DAMAGE: int = 18
const SPIN_COOLDOWN: float = 6.0
const SPIN_COLOR: Color = Color(1, .5, .18)

var player: CharacterBody3D
var wave_cooldown: float = 0.0
var focus: float = 0.0
## The special waiting for its swing to land: "wave", "rollback" or empty.
var queued: String = ""
var omni_index: int = -1
var omni_clock: float = 0.0
var omni_origin: Vector3
var omni_targets: Array[Node3D] = []
var omni_last: Vector3
var blades: Array[Dictionary] = []
var dash_cooldown: float = 0.0
var dash_left: float = 0.0
var dash_from: Vector3
var dash_direction: Vector3
var dash_marked: Array[Node3D] = []
var dash_landed: bool = false
## The light wall the dash leaves along its path; it flashes white when the cuts land.
var trail: MeshInstance3D
## The engineer shouts every move's name over a whoosh; the last call is kept for checks.
const WHOOSH: Dictionary = {
	"reply_all": preload("res://assets/audio/sfx/whoosh_slice.ogg"),
	"blame_shift": preload("res://assets/audio/sfx/whoosh_dash.ogg"),
	"circle_back": preload("res://assets/audio/sfx/whoosh_spin.ogg"),
	"rollback": preload("res://assets/audio/sfx/whoosh_rise.ogg"),
	"reset_hard": preload("res://assets/audio/sfx/heavy_impact.ogg"),
	"works_on_my_machine": preload("res://assets/audio/sfx/heavy_impact.ogg"),
}
const COUNTER_WINDOW: float = .6
const COUNTER_COOLDOWN: float = 3.0
const COUNTER_DAMAGE: int = 60
const COUNTER_WHIFF: float = .35
const COUNTER_COLOR: Color = Color(.45, 1, .6)
const BLAME_SECONDS: float = 4.0
const PARKING_SECONDS: float = 1.2
var voice: AudioStreamPlayer
var whoosh: AudioStreamPlayer
var counter_cooldown: float = 0.0
## Seconds left in the stance, then in the whiff recovery.
var counter_left: float = 0.0
var counter_recover: float = 0.0
var dome: MeshInstance3D
var last_call: String = ""
var trail_left: float = 0.0
var trail_flash: float = 0.0
var spin_cooldown: float = 0.0
var spin_left: float = 0.0
var spin_tick: float = 0.0
var spin_hits: int = 0
static var blade_mesh: ArrayMesh
static var blade_material: StandardMaterial3D


func _ready() -> void:
	player = get_parent() as CharacterBody3D
	player.hit_confirmed.connect(_on_hit)
	# Built once, kept hidden: restarts never change the node count.
	trail = MeshInstance3D.new()
	trail.name = "HotSwapTrail"
	trail.mesh = ImmediateMesh.new()
	trail.top_level = true
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	trail.material_override = material
	trail.hide()
	add_child(trail)
	voice = AudioStreamPlayer.new()
	voice.bus = &"Voice"
	# Calls sit on top of the fight, not inside the dialogue mix.
	voice.volume_db = 4.0
	add_child(voice)
	# The "localhost" dome: shown only while the stance is up.
	dome = MeshInstance3D.new()
	dome.name = "LocalhostDome"
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.05
	sphere.height = 2.3
	dome.mesh = sphere
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glass: StandardMaterial3D = StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glass.albedo_color = Color(COUNTER_COLOR, .16)
	glass.rim_enabled = false
	dome.material_override = glass
	var tag: Label3D = Label3D.new()
	tag.text = "localhost:3000"
	tag.font_size = 30
	tag.pixel_size = .004
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = COUNTER_COLOR
	tag.outline_size = 8
	tag.position.y = 1.35
	dome.add_child(tag)
	dome.hide()
	add_child(dome)
	whoosh = AudioStreamPlayer.new()
	whoosh.bus = &"Effects"
	whoosh.volume_db = -2.0
	add_child(whoosh)


func reset() -> void:
	if omni_index >= 0:
		ElementFx.slow_motion(&"omnislash", 1.0)
		if player != null:
			player.narrative_hold = false
	omni_index = -1
	omni_targets.clear()
	wave_cooldown = 0.0
	queued = ""
	dash_cooldown = 0.0
	spin_cooldown = 0.0
	spin_left = 0.0
	spin_hits = 0
	counter_cooldown = 0.0
	counter_left = 0.0
	counter_recover = 0.0
	if dome != null:
		dome.hide()
	dash_marked.clear()
	_end_dash()
	trail_left = 0.0
	if is_instance_valid(trail):
		trail.hide()
	for blade: Dictionary in blades:
		if is_instance_valid(blade.node):
			blade.node.queue_free()
	blades.clear()
	add_focus(-focus)


## Call the move: the shouted line, and the cut-in banner via `called`.
func _shout(key: String, title: String, ultimate: bool = false) -> void:
	last_call = key
	var path: String = "res://assets/audio/voices/talk/call_%s.ogg" % key
	if ResourceLoader.exists(path):
		voice.stream = load(path)
		# A little variety so the tenth call is not a recording of the first.
		voice.pitch_scale = randf_range(.97, 1.05)
		if DisplayServer.get_name() != "headless":
			voice.play()
	whoosh.stream = WHOOSH.get(key)
	whoosh.pitch_scale = randf_range(.94, 1.06)
	if whoosh.stream != null and DisplayServer.get_name() != "headless":
		whoosh.play()
	called.emit(title, ultimate)


## Hit with a special, telling the target how to die if this kills it (monster_rig.gd):
## blades slice, the slam launches, the whirlwind sends bodies tumbling.
func _strike(target: Node3D, amount: int, source: Vector3, style: String) -> bool:
	if target.is_in_group("breakables"):
		target.receive_damage(roundi(amount * player.melee.damage_multiplier), source)
		return false
	target.set_meta("kill_style", style)
	var landed: bool = target.receive_damage(roundi(amount * player.melee.damage_multiplier), source)
	if is_instance_valid(target) and target.get("health") != 0:
		target.remove_meta("kill_style")
	return landed


## Reuse the rig's phased poses without an extra, unrelated combo hit.
func _swing(index: int, windup: float, active: float, recovery: float, contact: bool = false) -> void:
	player.melee.cancel()
	player.clear_combo()
	player._start_step(index)
	player.melee.presentation_only = true
	player.melee.windup = windup
	player.melee.active_time = active
	player.melee.recovery = recovery
	if contact:
		player.melee.elapsed = windup + minf(.025, active * .2)


## Confirm actual damage on contact. Travelling cuts never arrest the dash/blinks.
func _impact(target: Node3D, color: Color, duration: float, impulse: float, hold_actor: bool = true, build_focus: bool = true) -> void:
	var pause: float = duration if player.hitstop_enabled else 0.0
	if is_instance_valid(target):
		if target.has_method("apply_hitstop"):
			target.apply_hitstop(pause)
		if player.impact_particles_enabled and target.has_method("show_impact"):
			target.show_impact(color)
	if hold_actor:
		var character: Node3D = player.get_node("Visual/Character")
		if player.melee.presentation_only and character.has_method("refresh_skill_contact"):
			character.refresh_skill_contact()
		player.hitstop_left = maxf(player.hitstop_left, pause)
		player.melee.freeze_left = maxf(player.melee.freeze_left, pause)
	if DisplayServer.get_name() != "headless":
		player.get_node("HitSound").play()
	player.camera_rig.add_impulse(impulse)
	if build_focus:
		player.hit_confirmed.emit()


func add_focus(amount: float) -> void:
	focus = clampf(focus + amount, 0.0, 100.0)
	focus_changed.emit(focus)


func ultimate_ready() -> bool:
	return focus >= 100.0


func _on_hit() -> void:
	# Combo and wave hits build FOCUS; the swing that carries a special does not.
	if queued.is_empty():
		add_focus(FOCUS_PER_HIT)


func _can_act() -> bool:
	return not player.narrative_hold and player.health > 0 and not player.dodging and player.is_on_floor() \
		and player.hurt_left <= 0 and not player.melee.is_active() and player.hitstop_left <= 0 and queued.is_empty() \
		and dash_left <= 0 and spin_left <= 0 and counter_left <= 0 and counter_recover <= 0 and omni_index < 0


func reply_all() -> bool:
	if wave_cooldown > 0 or not _can_act():
		return false
	player.melee.cancel()
	player.clear_combo()
	if not player._start_step(0):
		return false
	player.melee.windup = .07
	player.melee.recovery = .16
	queued = "wave"
	wave_cooldown = WAVE_COOLDOWN
	_shout("reply_all", "REPLY ALL")
	return true


func rollback() -> bool:
	if not ultimate_ready() or not _can_act():
		return false
	player.melee.cancel()
	player.clear_combo()
	add_focus(-100.0)
	var at: Vector3 = player.global_position
	omni_origin = at
	omni_last = at
	omni_targets.clear()
	for candidate in player.get_tree().get_nodes_in_group("enemies"):
		var enemy: Node3D = candidate as Node3D
		if enemy != null and enemy.get("health") != 0 and enemy.has_method("receive_damage") and enemy.global_position.distance_to(at) <= OMNI_RANGE:
			omni_targets.append(enemy)
	omni_targets.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.global_position.distance_to(at) < b.global_position.distance_to(at))
	omni_index = 0
	omni_clock = OMNI_LEAD
	player.narrative_hold = true
	player.invulnerable_left = maxf(player.invulnerable_left, 5.0)
	_swing(2, OMNI_LEAD, .12, .12)
	ElementFx.glyphs(player, at + Vector3.UP * 2.6, ROLLBACK_COLOR, ["FORCE ROLLBACK"], .9, 0.0)
	_shout("rollback", "FORCE ROLLBACK", true)
	ElementFx.motes(player, at + Vector3.UP * .4, ROLLBACK_COLOR, 30, 3.0, .8, 4.0, .16)
	ElementFx.shockwave(player, at, ROLLBACK_COLOR, 2.0, .4)
	# The world crawls; the engineer does not (the sequence runs on unscaled time).
	if DisplayServer.get_name() != "headless":
		ElementFx.slow_motion(&"omnislash", .2)
	return true


func omnislashing() -> bool:
	return omni_index >= 0


## One blink: appear beside the next target at a new angle and cut through it.
func _omni_step() -> void:
	if omni_index >= OMNI_SLASHES:
		# Back to the centre; the slam and its kill cam take it from here.
		_blink(omni_origin)
		omnislash_step.emit(omni_origin, omni_origin, omni_index)
		omni_index = -1
		ElementFx.slow_motion(&"omnislash", 1.0)
		player.narrative_hold = false
		player.visual.rotation.y = player.camera_rig.rotation.y
		_swing(2, .10, .16, .22)
		queued = "rollback"
		return
	var live: Array[Node3D] = omni_targets.filter(func(enemy: Node3D) -> bool: return is_instance_valid(enemy) and enemy.get("health") != 0)
	var angle: float = omni_index * 2.39996 + randf_range(-.25, .25)
	var around: Vector3 = Vector3(sin(angle), 0, cos(angle))
	var target: Node3D = live[omni_index % live.size()] if not live.is_empty() else null
	var focus: Vector3 = target.global_position if target != null else omni_origin + around * 2.5
	var spot: Vector3 = focus + around * 1.5
	spot.y = omni_origin.y
	# Never blink into a wall: stop short of anything between the target and the spot.
	var wall: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(focus + Vector3.UP, spot + Vector3.UP, 1))
	if not wall.is_empty():
		spot = Vector3(wall.position.x, omni_origin.y, wall.position.z) - around * .3
	_blink(spot)
	var toward: Vector3 = Vector3(focus.x - spot.x, 0, focus.z - spot.z)
	if toward.length() > .01:
		player.visual.rotation.y = atan2(-toward.x, -toward.z)
	_swing(omni_index % 2, .04, .08, .08, true)
	if toward.length() > .01:
		player.visual.rotation.y = atan2(-toward.x, -toward.z)
	# The pose follows the unscaled blink beat while the rest of the office crawls.
	var mid: Vector3 = focus + Vector3.UP * 1.0
	var across: Vector3 = toward.normalized().cross(Vector3.UP) if toward.length() > .01 else Vector3.RIGHT
	var tilt: float = 1.0 if omni_index % 2 == 0 else -1.0
	ElementFx.bolt(player, mid - across * 1.4 + Vector3.UP * .7 * tilt, mid + across * 1.4 - Vector3.UP * .7 * tilt, Color(.85, .8, 1), .35, .1)
	ElementFx.flash(player, mid, ROLLBACK_COLOR, 2.5, 4.0, .12)
	if target != null:
		ElementFx.shards(player, mid, ROLLBACK_COLOR, 4, 5.0, .3, toward.normalized())
		if _strike(target, OMNI_DAMAGE, spot, "slice"):
			_impact(target, ROLLBACK_COLOR, .05, .35, false, false)
			if "stagger_left" in target:
				target.stagger_left = .6
	whoosh.stream = WHOOSH.reply_all
	whoosh.pitch_scale = 1.0 + omni_index * .06
	if DisplayServer.get_name() != "headless":
		whoosh.play()
	player.camera_rig.add_impulse(.5)
	omnislash_step.emit(spot, focus, omni_index)
	omni_index += 1


## Vanish here, appear there: a streak of light between the two.
func _blink(to: Vector3) -> void:
	var from: Vector3 = player.global_position
	ElementFx.bolt(player, from + Vector3.UP * 1.0, to + Vector3.UP * 1.0, ROLLBACK_COLOR, .3, .07)
	ElementFx.motes(player, from + Vector3.UP * .8, ROLLBACK_COLOR, 10, 2.0, .4, 0.0, .14)
	player.global_position = to
	player.velocity = Vector3.ZERO
	omni_last = to


## Blame Shift: allowed out of a dodge (that is the point), never mid-special.
func blame_shift() -> bool:
	if dash_cooldown > 0 or player.narrative_hold or player.health <= 0 or player.hurt_left > 0 or not player.is_on_floor() \
			or not queued.is_empty() or dash_left > 0 or spin_left > 0 or omni_index >= 0:
		return false
	player.dodging = false
	player.melee.cancel()
	player.clear_combo()
	var direction: Vector3 = -player.camera_rig.global_basis.z
	direction.y = 0
	direction = direction.normalized()
	var eye: Vector3 = player.global_position + Vector3.UP
	var distance: float = DASH_DISTANCE
	var wall: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye, eye + direction * DASH_DISTANCE, 1))
	if not wall.is_empty():
		distance = maxf(.8, eye.distance_to(wall.position) - .6)
	# The diagonal pose accompanies the dash; only its swept cuts deal damage.
	_swing(0, .025, DASH_TIME, .12)
	player.visual.rotation.y = atan2(-direction.x, -direction.z)
	dash_from = player.global_position
	dash_direction = direction
	dash_left = DASH_TIME * distance / DASH_DISTANCE
	dash_marked.clear()
	dash_landed = false
	player.dash_velocity = direction * DASH_DISTANCE / DASH_TIME
	# Straight through bodies: enemies sit on collision layer 3 (value 4).
	player.set_collision_mask_value(3, false)
	player.invulnerable_left = maxf(player.invulnerable_left, dash_left + .4)
	dash_cooldown = DASH_COOLDOWN
	ElementFx.gust(player, eye, Basis.looking_at(direction), DASH_COLOR, 2.5, .22)
	ElementFx.motes(player, player.global_position + Vector3.UP * .4, DASH_COLOR, 18, 3.0, .5, 0.0, .12, -direction, 50.0)
	ElementFx.glyphs(player, player.global_position + Vector3.UP * 2.3, DASH_COLOR, ["BLAME SHIFT"], .6, 0.0)
	_shout("blame_shift", "BLAME SHIFT")
	return true


func circle_back() -> bool:
	if spin_cooldown > 0 or not _can_act():
		return false
	player.melee.cancel()
	player.clear_combo()
	_swing(1, .08, .20, .07)
	spin_left = SPIN_TIME
	spin_tick = .08
	spin_hits = 0
	spin_cooldown = SPIN_COOLDOWN
	ElementFx.glyphs(player, player.global_position + Vector3.UP * 2.4, SPIN_COLOR, ["LET'S CIRCLE BACK"], .8, 0.0)
	_shout("circle_back", "CIRCLE BACK")
	return true


func trail_length() -> float:
	return Vector2(player.global_position.x - dash_from.x, player.global_position.z - dash_from.z).length() if dash_left > 0 else trail_span


var trail_span: float = 0.0


## A vertical sheet of light from where the dash began to where the engineer is: gold,
## brightest at the head; white for a moment on arrival, then it fades.
func _draw_trail(from: Vector3, to: Vector3) -> void:
	trail_span = Vector2(to.x - from.x, to.z - from.z).length()
	trail.global_transform = Transform3D.IDENTITY
	trail.show()
	var fade: float = clampf(trail_left / .45, 0.0, 1.0)
	var head: Color = DASH_COLOR.lerp(Color(1, 1, 1), trail_flash)
	var mesh: ImmediateMesh = trail.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for corner: Array in [[from, .0], [to, 1.0]]:
		for height in [.15, 1.9]:
			var core: float = 1.0 - absf(height - 1.0) * .6
			mesh.surface_set_color(Color(head, (.15 + .75 * corner[1]) * fade * core))
			mesh.surface_add_vertex(corner[0] + Vector3.UP * height)
	mesh.surface_end()


func works_on_my_machine() -> bool:
	if counter_cooldown > 0 or not _can_act():
		return false
	player.melee.cancel()
	player.clear_combo()
	counter_left = COUNTER_WINDOW
	counter_cooldown = COUNTER_COOLDOWN
	dome.global_position = player.global_position + Vector3.UP
	dome.show()
	ElementFx.sigil(player, player.global_position, COUNTER_COLOR, 1.3, COUNTER_WINDOW, 3.0)
	whoosh.stream = preload("res://assets/audio/sfx/force_field.ogg")
	if DisplayServer.get_name() != "headless":
		whoosh.play()
	return true


## The stance is how the counter hears about a hit: true means the hit is cancelled.
func try_counter(_amount: int, source: Vector3) -> bool:
	if counter_left <= 0:
		return false
	counter_left = 0.0
	dome.hide()
	var attacker: Node3D = null
	for candidate in player.get_tree().get_nodes_in_group("enemies"):
		var enemy: Node3D = candidate as Node3D
		if enemy == null or enemy.get("health") == 0:
			continue
		if enemy.global_position.distance_to(source) < 2.8 and (attacker == null or enemy.global_position.distance_to(source) < attacker.global_position.distance_to(source)):
			attacker = enemy
	var at: Vector3 = player.global_position
	player.invulnerable_left = maxf(player.invulnerable_left, .6)
	ElementFx.flash(player, at + Vector3.UP, COUNTER_COLOR, 4.0, 5.0, .3)
	ElementFx.shockwave(player, at, COUNTER_COLOR, 2.4, .35)
	if player.hitstop_enabled:
		ElementFx.freeze(player, .07, .04)
	player.camera_rig.add_impulse(1.2)
	_shout("works_on_my_machine", "WORKS ON MY MACHINE")
	counter_cooldown = .8
	add_focus(20.0)
	if attacker != null:
		var away: Vector3 = attacker.global_position - at
		away.y = 0
		away = away.normalized() if away.length() > .01 else Vector3.FORWARD
		player.visual.rotation.y = atan2(-away.x, -away.z)
		if "melee" in attacker and attacker.melee != null:
			attacker.melee.cancel()
		_swing(1, .04, .16, .14, true)
		player.visual.rotation.y = atan2(-away.x, -away.z)
		if _strike(attacker, COUNTER_DAMAGE, at, "slice"):
			_impact(attacker, COUNTER_COLOR, .065, .5, true, false)
		if attacker.get("health") != 0:
			if "stagger_left" in attacker:
				attacker.stagger_left = 1.0
			if "knockback" in attacker:
				attacker.knockback = away * 9.0
		ElementFx.glyphs(player, attacker.global_position + Vector3.UP * 2.2, COUNTER_COLOR, ["CANNOT REPRODUCE"], 1.0, 0.0)
		ElementFx.shards(player, attacker.global_position + Vector3.UP, COUNTER_COLOR, 14, 6.0, .5, away)
	return true


func _end_dash() -> void:
	dash_left = 0.0
	if player != null:
		player.dash_velocity = Vector3.ZERO
		player.set_collision_mask_value(3, true)


func _tick_dash(delta: float) -> void:
	dash_left -= delta
	# Everything the engineer passes is cut as they go by.
	var here: Vector3 = player.global_position
	for candidate in _damage_targets():
		var target: Node3D = candidate as Node3D
		if target == null or dash_marked.has(target) or target.get("health") == 0:
			continue
		var at: Vector3 = target.global_position
		if absf(at.y - here.y) > 1.8:
			continue
		var closest: Vector3 = Geometry3D.get_closest_point_to_segment(Vector3(at.x, here.y, at.z), dash_from, here)
		if Vector2(closest.x - at.x, closest.z - at.z).length() <= DASH_HALF_WIDTH:
			dash_marked.append(target)
			dash_landed = _cut(target) or dash_landed
	ElementFx.motes(player, here + Vector3.UP * .8, DASH_COLOR, 4, 1.5, .35, 0.0, .1, -dash_direction, 40.0)
	trail_left = .7
	trail_flash = 0.0
	_draw_trail(dash_from, here)
	if dash_left <= 0:
		# Arrival: the path flashes, a spin to finish, and a freeze-frame if anything fell.
		_end_dash()
		ElementFx.bolt(player, dash_from + Vector3.UP, here + Vector3.UP, Color(1, .95, .7), .45, .09)
		ElementFx.bolt(player, dash_from + Vector3.UP * .7, here + Vector3.UP * .7, DASH_COLOR, .55, .05)
		trail_flash = 1.0
		dash_marked.clear()
		_swing(1, .04, .12, .12, true)
		if dash_landed:
			player.camera_rig.add_impulse(1.0)


## One enemy cut by the dash, crosswise, as the engineer goes past.
func _cut(target: Node3D) -> bool:
	var at: Vector3 = target.global_position + Vector3.UP
	var across: Vector3 = dash_direction.cross(Vector3.UP).normalized()
	for tilt in [1.0, -1.0]:
		ElementFx.bolt(player, at - across * 1.3 + Vector3.UP * .8 * tilt, at + across * 1.3 - Vector3.UP * .8 * tilt, Color(1, .97, .8), .35, .13)
	ElementFx.shards(player, at, DASH_COLOR, 12, 6.0, .5, dash_direction)
	ElementFx.flash(player, at, DASH_COLOR, 2.0, 3.0, .15)
	if not _strike(target, DASH_DAMAGE, at - dash_direction * 2.0, "slice"):
		return false
	_impact(target, DASH_COLOR, .055, .4, false)
	# Shifted onto them: blamed incidents take more from everything for a while.
	if "blamed_left" in target and target.get("health") != 0:
		target.blamed_left = BLAME_SECONDS
		ElementFx.glyphs(player, at + Vector3.UP * 1.3, Color(1, .4, .3), ["BLAMED"], .9, 0.0)
	return true


func _tick_spin(delta: float) -> void:
	if player.hitstop_left > 0:
		return
	spin_left -= delta
	spin_tick -= delta
	if spin_tick > 0 or spin_hits >= SPIN_TICKS:
		return
	spin_tick = SPIN_TIME / SPIN_TICKS
	spin_hits += 1
	var last: bool = spin_hits == SPIN_TICKS
	_swing(1, .08, .20, .07, true)
	var at: Vector3 = player.global_position
	ElementFx.shockwave(player, at + Vector3.UP * .1, SPIN_COLOR, SPIN_RADIUS, .3)
	ElementFx.flame_ring(player, at, SPIN_RADIUS * .8, .35)
	ElementFx.motes(player, at + Vector3.UP * .8, SPIN_COLOR, 16, 5.0, .45, 1.0, .14)
	var landed: bool = false
	for candidate in _damage_targets():
		var target: Node3D = candidate as Node3D
		if target == null or not target.has_method("receive_damage") or target.get("health") == 0:
			continue
		var offset: Vector3 = target.global_position - at
		if absf(offset.y) > 1.8 or Vector2(offset.x, offset.z).length() > SPIN_RADIUS:
			continue
		if _strike(target, SPIN_DAMAGE, at, "tumble"):
			landed = true
			_impact(target, SPIN_COLOR, .035, .15, true, false)
			# Into the whirlwind, not away from it.
			if "knockback" in target:
				target.knockback = -Vector3(offset.x, 0, offset.z).normalized() * 4.0
			# The final pulse parks whatever is left: "let's take that offline".
			if last and target.get("health") != 0 and "stagger_left" in target:
				target.stagger_left = PARKING_SECONDS
				ElementFx.glyphs(player, target.global_position + Vector3.UP * 2.2, Color(.95, .8, .4), ["PARKING LOT"], .9, 0.0)
	if landed:
		player.hit_confirmed.emit()


func _physics_process(delta: float) -> void:
	if omni_index >= 0:
		if player.melee.attacking:
			player.melee.elapsed += delta * (1.0 / maxf(Engine.time_scale, .01) - 1.0)
		omni_clock -= delta / maxf(Engine.time_scale, .01)
		if omni_clock <= 0:
			omni_clock = OMNI_BEAT
			_omni_step()
	wave_cooldown = maxf(0.0, wave_cooldown - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	spin_cooldown = maxf(0.0, spin_cooldown - delta)
	if dash_left > 0:
		_tick_dash(delta)
	if spin_left > 0:
		_tick_spin(delta)
	counter_cooldown = maxf(0.0, counter_cooldown - delta)
	counter_recover = maxf(0.0, counter_recover - delta)
	if counter_left > 0:
		counter_left -= delta
		dome.global_position = player.global_position + Vector3.UP
		dome.scale = Vector3.ONE * (1.0 + .04 * sin(counter_left * 40.0))
		if counter_left <= 0:
			# Nothing came: it worked on nobody's machine. A short, open recovery.
			dome.hide()
			counter_recover = COUNTER_WHIFF
			ElementFx.glyphs(player, player.global_position + Vector3.UP * 2.2, Color(.7, .75, .8), ["…works on my machine?"], .8, 0.0)
	if trail_left > 0 and dash_left <= 0:
		trail_left = maxf(0.0, trail_left - delta)
		trail_flash = maxf(0.0, trail_flash - delta * 3.0)
		if trail_left == 0:
			trail.hide()
		else:
			_draw_trail(dash_from, dash_from + dash_direction * trail_length())
	if not queued.is_empty():
		if player.melee.is_active():
			if queued == "wave":
				_launch_wave()
			else:
				_slam()
			queued = ""
		elif not player.melee.attacking:
			queued = ""
	for blade: Dictionary in blades.duplicate():
		_advance(blade, delta)


func _launch_wave() -> void:
	var direction: Vector3 = -player.visual.global_basis.z
	direction.y = 0
	direction = direction.normalized()
	var origin: Vector3 = player.global_position + Vector3.UP * 1.0 + direction * .8
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh = _blade_mesh()
	node.material_override = blade_material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.top_level = true
	player.get_parent().add_child(node)
	# Rolled to follow the overhead diagonal cut that throws it.
	node.global_transform = Transform3D(Basis.looking_at(direction) * Basis(Vector3.BACK, deg_to_rad(-28.0)), origin)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = WAVE_COLOR
	light.light_energy = 2.5
	light.omni_range = 4.0
	node.add_child(light)
	blades.append({"node": node, "origin": origin, "direction": direction, "travelled": 0.0, "hit": []})
	var ground: Vector3 = Vector3(origin.x, player.global_position.y, origin.z)
	ElementFx.fissure(player, ground, ground + direction * WAVE_RANGE * .8, WAVE_COLOR, .7)
	ElementFx.gust(player, origin, Basis.looking_at(direction), WAVE_COLOR, 3.0, .3)
	ElementFx.glyphs(player, player.global_position + Vector3.UP * 2.3, WAVE_COLOR, ["REPLY ALL"], .7, 0.0)
	player.camera_rig.add_impulse(.6)


func _advance(blade: Dictionary, delta: float) -> void:
	var node: MeshInstance3D = blade.node
	if not is_instance_valid(node):
		blades.erase(blade)
		return
	var before: Vector3 = blade.origin + blade.direction * blade.travelled
	var step: float = minf(WAVE_SPEED * delta, WAVE_RANGE - blade.travelled)
	var after: Vector3 = before + blade.direction * step
	var wall: Dictionary = node.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(before, after, 1))
	if not wall.is_empty():
		after = wall.position
	blade.travelled += before.distance_to(after)
	node.global_position = after
	node.scale = Vector3.ONE * lerpf(1.0, 1.35, blade.travelled / WAVE_RANGE)
	# A trail of sparks every metre or so.
	if int(blade.travelled) != int(blade.travelled - before.distance_to(after)):
		ElementFx.motes(player, after, WAVE_COLOR, 6, 2.0, .45, -1.0, .12, -blade.direction, 60.0)
	(node.get_child(0) as OmniLight3D).light_energy = 2.5 * (1.0 - blade.travelled / WAVE_RANGE)
	for candidate in _damage_targets():
		var target: Node3D = candidate as Node3D
		if target == null or blade.hit.has(target) or not target.has_method("receive_damage") or target.get("health") == 0:
			continue
		var center: Vector3 = target.global_position + Vector3.UP
		if absf(center.y - after.y) > 1.8:
			continue
		var closest: Vector3 = Geometry3D.get_closest_point_to_segment(Vector3(center.x, after.y, center.z), before, after)
		if Vector2(closest.x - center.x, closest.z - center.z).length() > WAVE_HALF_WIDTH:
			continue
		blade.hit.append(target)
		if _strike(target, WAVE_DAMAGE, after - blade.direction * 2.0, "slice"):
			_impact(target, WAVE_COLOR, .045, .5, false)
			ElementFx.shards(player, center, WAVE_COLOR, 10, 6.0, .5, blade.direction)
			ElementFx.glyphs(player, center + Vector3.UP * 1.2, WAVE_COLOR, ["RE: RE: RE:"], .6, 0.0)
	if not wall.is_empty() or blade.travelled >= WAVE_RANGE - .01:
		ElementFx.flash(player, after, WAVE_COLOR, 3.0, 4.0, .25)
		ElementFx.shards(player, after, WAVE_COLOR, 16, 5.0, .6, -blade.direction)
		node.queue_free()
		blades.erase(blade)


func _slam() -> void:
	var at: Vector3 = player.global_position
	ElementFx.release_freeze()
	ElementFx.shockwave(player, at, ROLLBACK_COLOR, ROLLBACK_RADIUS, .7)
	ElementFx.shockwave(player, at + Vector3.UP * .2, WAVE_COLOR, ROLLBACK_RADIUS * .6, .5)
	ElementFx.quake(player, at, ROLLBACK_COLOR, ROLLBACK_RADIUS * .8, 1.2)
	ElementFx.cracks(player, at, ROLLBACK_COLOR, 4.0, 11, 1.8)
	ElementFx.flash(player, at + Vector3.UP * 1.2, ROLLBACK_COLOR, 6.0, 10.0, .45)
	ElementFx.motes(player, at + Vector3.UP * .5, ROLLBACK_COLOR, 22, 9.0, .8, 3.0, .11)
	ElementFx.glyphs(player, at + Vector3.UP * 3.0, Color(1, 1, 1), ["git reset --hard"], 1.4, 0.0)
	_shout("reset_hard", "GIT RESET --HARD", true)
	ElementFx.tremor(player, at, 1.4, 16.0)
	if player.hitstop_enabled:
		ElementFx.freeze(player, .10, .04)
	player.camera_rig.add_impulse(2.2)
	for candidate in _damage_targets():
		var target: Node3D = candidate as Node3D
		if target == null or not target.has_method("receive_damage") or target.get("health") == 0:
			continue
		var offset: Vector3 = target.global_position - at
		if absf(offset.y) > 3.0 or Vector2(offset.x, offset.z).length() > ROLLBACK_RADIUS:
			continue
		# A rollback restores the state before any shield went up.
		if target.has_method("drop_shield"):
			target.drop_shield()
		if _strike(target, ROLLBACK_DAMAGE, at, "launch"):
			_impact(target, ROLLBACK_COLOR, .08, .2, true, false)
	rollback_completed.emit()


## An upright crescent facing back at the thrower (so it reads from the camera), in
## three layers: a wide soft glow, the cyan blade and a white-hot outer edge. The node
## rolls it to match the diagonal cut; the tips fade out.
func _blade_mesh() -> ArrayMesh:
	if blade_mesh != null:
		return blade_mesh
	var triangles: PackedVector3Array = PackedVector3Array()
	var tints: PackedColorArray = PackedColorArray()
	# [half width, outer arch height, inner arch height, outer colour, inner colour]
	var layers: Array = [
		[2.6, 1.15, .1, Color(WAVE_COLOR, .3), Color(WAVE_COLOR, 0.0)],
		[2.3, 1.0, .5, Color(WAVE_COLOR, .95), Color(WAVE_COLOR, .05)],
		[2.2, 1.04, .9, Color(1, 1, 1, 1), Color(.85, 1, 1, .4)]]
	var steps: int = 24
	for layer: Array in layers:
		for index in range(steps):
			var quad: Array = []
			for edge in [0, 1]:
				var across: float = lerpf(-1.0, 1.0, float(index + edge) / steps)
				var bow: float = 1.0 - across * across
				var fade: float = sqrt(bow)
				var lean: float = -.6 * bow
				quad.append([Vector3(across * layer[0], layer[1] * bow - .5, lean), Color(layer[3], layer[3].a * fade)])
				quad.append([Vector3(across * layer[0] * .97, layer[2] * bow - .5, lean + .15), Color(layer[4], layer[4].a * fade)])
			for corner in [0, 1, 2, 2, 1, 3]:
				triangles.append(quad[corner][0])
				tints.append(quad[corner][1])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = triangles
	arrays[Mesh.ARRAY_COLOR] = tints
	blade_mesh = ArrayMesh.new()
	blade_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	blade_material = StandardMaterial3D.new()
	blade_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blade_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blade_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	blade_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	blade_material.vertex_color_use_as_albedo = true
	return blade_mesh


func _damage_targets() -> Array[Node]:
	var targets: Array[Node] = player.get_tree().get_nodes_in_group("enemies")
	targets.append_array(player.get_tree().get_nodes_in_group("breakables"))
	return targets
