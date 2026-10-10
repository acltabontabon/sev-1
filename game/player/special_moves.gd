extends Node
## The engineer's special moves, on top of the three-hit combo. Both reuse the combo's own
## swings for the body (rigged_engineer.gd animates combo steps), and fire on the swing's
## active frame so the visible strike and the effect agree.
##
## HOTFIX WAVE (C / middle mouse): an overhead cut throws a crescent blade 13 m forward,
## piercing everything in its path until a wall breaks it. 3.5 s cooldown.
## FORCE ROLLBACK (V): the ultimate. Landed hits fill FOCUS; at 100 the engineer leaps,
## time slows, and the slam rolls back everything within 7.5 m (shields included).

signal focus_changed(value: float)

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

var player: CharacterBody3D
var wave_cooldown: float = 0.0
var focus: float = 0.0
## The special waiting for its swing to land: "wave", "rollback" or empty.
var queued: String = ""
var blades: Array[Dictionary] = []
static var blade_mesh: ArrayMesh
static var blade_material: StandardMaterial3D


func _ready() -> void:
	player = get_parent() as CharacterBody3D
	player.hit_confirmed.connect(_on_hit)


func reset() -> void:
	wave_cooldown = 0.0
	queued = ""
	for blade: Dictionary in blades:
		if is_instance_valid(blade.node):
			blade.node.queue_free()
	blades.clear()
	add_focus(-focus)


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
		and player.hurt_left <= 0 and not player.melee.is_active() and player.hitstop_left <= 0 and queued.is_empty()


func hotfix_wave() -> bool:
	if wave_cooldown > 0 or not _can_act():
		return false
	player.melee.cancel()
	player.clear_combo()
	if not player._start_step(0):
		return false
	queued = "wave"
	wave_cooldown = WAVE_COOLDOWN
	return true


func rollback() -> bool:
	if not ultimate_ready() or not _can_act():
		return false
	player.melee.cancel()
	player.clear_combo()
	if not player._start_step(2):
		return false
	queued = "rollback"
	add_focus(-100.0)
	player.invulnerable_left = maxf(player.invulnerable_left, 1.4)
	var at: Vector3 = player.global_position
	ElementFx.glyphs(player, at + Vector3.UP * 2.6, ROLLBACK_COLOR, ["FORCE ROLLBACK"], .9, 0.0)
	ElementFx.motes(player, at + Vector3.UP * .4, ROLLBACK_COLOR, 30, 3.0, .8, 4.0, .16)
	# The leap hangs in slow motion; the slam snaps time back.
	ElementFx.freeze(player, .4, .3)
	return true


func _physics_process(delta: float) -> void:
	wave_cooldown = maxf(0.0, wave_cooldown - delta)
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
	ElementFx.glyphs(player, player.global_position + Vector3.UP * 2.3, WAVE_COLOR, ["HOTFIX WAVE"], .7, 0.0)
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
	for candidate in player.get_tree().get_nodes_in_group("enemies"):
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
		if target.receive_damage(roundi(WAVE_DAMAGE * player.melee.damage_multiplier), after - blade.direction * 2.0):
			if target.has_method("apply_hitstop"):
				target.apply_hitstop(.06)
			if target.has_method("show_impact"):
				target.show_impact(WAVE_COLOR)
			ElementFx.shards(player, center, WAVE_COLOR, 10, 6.0, .5, blade.direction)
			player.camera_rig.add_impulse(.5)
			player.hit_confirmed.emit()
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
	ElementFx.motes(player, at + Vector3.UP * .5, ROLLBACK_COLOR, 60, 9.0, 1.0, 3.0, .2)
	ElementFx.glyphs(player, at + Vector3.UP * 3.0, Color(1, 1, 1), ["git reset --hard"], 1.4, 0.0)
	ElementFx.tremor(player, at, 1.4, 16.0)
	ElementFx.freeze(player, .14, .04)
	player.camera_rig.add_impulse(2.2)
	for candidate in player.get_tree().get_nodes_in_group("enemies"):
		var target: Node3D = candidate as Node3D
		if target == null or not target.has_method("receive_damage") or target.get("health") == 0:
			continue
		var offset: Vector3 = target.global_position - at
		if absf(offset.y) > 3.0 or Vector2(offset.x, offset.z).length() > ROLLBACK_RADIUS:
			continue
		# A rollback restores the state before any shield went up.
		if target.has_method("drop_shield"):
			target.drop_shield()
		if target.receive_damage(roundi(ROLLBACK_DAMAGE * player.melee.damage_multiplier), at):
			if target.has_method("show_impact"):
				target.show_impact(ROLLBACK_COLOR)


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
