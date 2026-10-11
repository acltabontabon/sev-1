extends Node3D
## The Variance's moveset in the fight: the same corporate euphemisms it used on the night
## shift, aimed at the engineer while its shield is up. One move per shield cycle, in
## turn. Each telegraphs and each has a way out, named in the strip: step out from under
## Delayering, roll through Decommission's ring, stay clear of the feedback bubbles, look
## away from the exposure flash, and get out of Downsizing's beam. Owned by the boss.

const ORDER: Array[String] = ["delayer", "pop", "decommission", "expose", "downsize"]
const DAMAGE: int = 15
const PROP_DAMAGE: int = 40
const LENGTH: Dictionary = {"delayer": 1.9, "pop": 2.6, "decommission": 2.9, "expose": 2.8, "downsize": 2.6}
const NOTES: Array[String] = ["MAKE IT POP", "MORE SYNERGY", "CAN IT BE BLUE?"]
const SHRUNK: float = .55
const SHRINK_SECONDS: float = 4.0

var boss: CharacterBody3D
var target: CharacterBody3D
var move: String = ""
var t: float = 0.0
var turn: int = 0
var voiced: Dictionary = {}
var lock: Vector3
var shadow: Node3D
var ring: MeshInstance3D
var ring_radius: float = 0.0
var bubbles: Array[Node3D] = []
var shrink_left: float = 0.0


func _init(owner_boss: CharacterBody3D) -> void:
	boss = owner_boss
	name = "Moves"


func active() -> bool:
	return not move.is_empty()


func start(who: CharacterBody3D) -> void:
	target = who
	move = ORDER[turn % ORDER.size()]
	turn += 1
	t = 0.0
	ring_radius = 0.0
	lock = _feet()
	boss.rig.cast(LENGTH[move] * .6)
	var story: Node = _story()
	if story != null:
		# Voiced the first time each move comes round; the strip every time.
		story.boss_move(move, not voiced.has(move), true)
	voiced[move] = true
	match move:
		"delayer":
			shadow = ElementFx.sigil(_level(), lock, Color(.9, .1, .1), 1.7, 1.7, -.6)
		"pop":
			for index in range(NOTES.size()):
				var side: Vector3 = Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * (0.0 if index == 0 else 1.9)
				_lob(NOTES[index], lock + side, index * .12)
		"decommission":
			ElementFx.glyphs(_level(), boss.global_position + Vector3.UP * 3.0, Color(1, .3, .2), ["END OF LIFE"], .8, .2)
			ElementFx.flash(_level(), boss.global_position + Vector3.UP * 1.5, Color(1, .15, .1), 5.0, 6.0, .6)


func _physics_process(delta: float) -> void:
	_shrink(delta)
	if move.is_empty() or not is_instance_valid(target):
		return
	var before: float = t
	t += delta
	match move:
		"delayer":
			# It follows him, then commits; step out before it lands.
			if t < 1.1:
				lock = _feet()
				if is_instance_valid(shadow):
					shadow.global_position = lock
			if before < 1.55 and t >= 1.55:
				smash_props(lock, 1.7)
				ElementFx.quake(_level(), lock, Color(.9, .12, .1), 2.0, .9)
				ElementFx.cracks(_level(), lock, Color(.8, .1, .08), 1.8)
				ElementFx.dust(_level(), lock, 1.6)
				ElementFx.tremor(_level(), lock, .5, 12.0)
				if _flat(lock) < 1.7 and target.receive_damage(DAMAGE, boss.global_position):
					# Flattened, briefly: one layer removed.
					target.visual.scale = Vector3(1.45, .3, 1.45)
					var back: Tween = target.visual.create_tween()
					back.tween_property(target.visual, "scale", Vector3.ONE, .55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
					ElementFx.glyphs(_level(), target.global_position + Vector3.UP * 1.6, Color(1, .3, .25), ["DELAYERED"], .9, .2)
		"pop":
			if before < 2.0 and t >= 2.0:
				for bubble in bubbles:
					if is_instance_valid(bubble):
						_burst(bubble)
				bubbles.clear()
		"decommission":
			# An end-of-life scan rolls out from it at knee height; roll through it.
			if t >= .8:
				if ring == null:
					ring = _ring()
				var previous: float = ring_radius
				ring_radius = (t - .8) * 6.5
				ring.scale = Vector3(ring_radius, 1, ring_radius)
				smash_props(ring.global_position, ring_radius, previous)
				var away: float = Vector2(target.global_position.x - boss.global_position.x, target.global_position.z - boss.global_position.z).length()
				if previous < away and ring_radius >= away and target.receive_damage(DAMAGE, boss.global_position):
					ElementFx.glyphs(_level(), target.global_position + Vector3.UP * 1.6, Color(1, .3, .2), ["END OF LIFE"], .9, .2)
		"expose":
			# Three flashes counting down, then the big one: face it and be overexposed.
			for at: float in [.4, .9, 1.4]:
				if before < at and t >= at:
					var bulb: Vector3 = target.global_position + Vector3(randf_range(-2.0, 2.0), randf_range(1.0, 2.4), randf_range(-2.0, 2.0))
					ElementFx.flash(_level(), bulb, Color(1, 1, .95), 4.0, 4.0, .08)
					ElementFx.glyphs(_level(), target.global_position + Vector3.UP * 2.2, Color(1, .95, .6), [["3", "2", "1"][[.4, .9, 1.4].find(at)]], .45, 0.0)
			if before < 1.9 and t >= 1.9:
				smash_props(boss.global_position, 6.0)
				ElementFx.flash(_level(), boss.global_position + Vector3.UP * 2.5, Color(1, 1, .95), 10.0, 18.0, .35)
				if _facing() and target.receive_damage(DAMAGE, boss.global_position):
					ElementFx.glyphs(_level(), target.global_position + Vector3.UP * 1.6, Color(1, .95, .6), ["+EXPOSURE"], 1.0, .3)
					var story: Node = _story()
					if story != null:
						story.whiteout(.5)
				else:
					ElementFx.glyphs(_level(), target.global_position + Vector3.UP * 1.6, Color(.8, .9, 1), ["NO COMMENT"], 1.0, .2)
		"downsize":
			# A beam tracks him, then locks; out of the spot before it fires.
			if t < 1.3:
				lock = _feet()
				if int(t * 10.0) != int(before * 10.0):
					ElementFx.bolt(_level(), boss.global_position + Vector3.UP * 3.2, lock + Vector3.UP * .8, Color(.5, 1, .7), .1, .03)
			if before < 1.3 and t >= 1.3:
				ElementFx.sigil(_level(), lock, Color(.4, 1, .6), 1.2, .5, 2.0)
			if before < 1.8 and t >= 1.8:
				smash_props(lock, 1.2)
				ElementFx.bolt(_level(), boss.global_position + Vector3.UP * 3.2, lock + Vector3.UP * .5, Color(.6, 1, .8), .3, .12)
				ElementFx.flash(_level(), lock + Vector3.UP, Color(.5, 1, .7), 4.0, 5.0, .25)
				if _flat(lock) < 1.2 and target.receive_damage(DAMAGE / 2, boss.global_position):
					shrink_left = SHRINK_SECONDS
					ElementFx.glyphs(_level(), target.global_position + Vector3.UP * 1.4, Color(.6, 1, .7), ["HEADCOUNT −0.5"], 1.0, .2)
	if t >= LENGTH[move]:
		_finish()


func _finish() -> void:
	move = ""
	if is_instance_valid(shadow):
		shadow.queue_free()
	if is_instance_valid(ring):
		ring.queue_free()
	ring = null
	for bubble in bubbles:
		if is_instance_valid(bubble):
			bubble.queue_free()
	bubbles.clear()


## Stop mid-move (the boss is staggered into its opening, or dies).
func cancel() -> void:
	if not move.is_empty():
		_finish()


func _exit_tree() -> void:
	if is_instance_valid(target) and shrink_left > 0.0:
		target.visual.scale = Vector3.ONE
	shrink_left = 0.0


## Downsized: he fights at a little over half size for a while (getting hit resizes him).
func _shrink(delta: float) -> void:
	if shrink_left <= 0.0 or not is_instance_valid(target):
		return
	shrink_left = maxf(0.0, shrink_left - delta)
	target.visual.scale = Vector3.ONE * (SHRUNK if shrink_left > 0.0 else 1.0)


## A feedback bubble, lobbed from its head to where he is standing, with its note on it.
func _lob(note: String, at: Vector3, delay: float) -> void:
	var bubble: Node3D = Node3D.new()
	bubble.top_level = true
	var ball: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = .4
	sphere.height = .8
	ball.mesh = sphere
	var skin: StandardMaterial3D = StandardMaterial3D.new()
	skin.albedo_color = Color(1, .4, .75, .75)
	skin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	skin.emission_enabled = true
	skin.emission = Color(1, .3, .7)
	skin.emission_energy_multiplier = 1.4
	ball.material_override = skin
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bubble.add_child(ball)
	var label: Label3D = Label3D.new()
	label.text = note
	label.font = preload("res://assets/fonts/barlow_condensed_bold.ttf")
	label.font_size = 48
	label.pixel_size = .005
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = .75
	bubble.add_child(label)
	add_child(bubble)
	bubbles.append(bubble)
	var from: Vector3 = boss.global_position + Vector3.UP * 3.4
	bubble.global_position = from
	ElementFx.sigil(_level(), at, Color(1, .35, .7), 1.3, 2.0 - delay, 1.5)
	var flight: Tween = bubble.create_tween()
	flight.tween_interval(delay)
	flight.tween_method(func(progress: float) -> void:
		if is_instance_valid(bubble):
			bubble.global_position = from.lerp(at + Vector3.UP * .45, progress) + Vector3.UP * sin(progress * PI) * 2.5, 0.0, 1.0, .7)
	flight.tween_property(bubble, "scale", Vector3.ONE * 1.25, .6).set_trans(Tween.TRANS_ELASTIC)


func _burst(bubble: Node3D) -> void:
	var at: Vector3 = bubble.global_position
	smash_props(at, 1.3)
	for colour: Color in [Color(1, .3, .7), Color(.3, .8, 1), Color(1, .85, .2)]:
		ElementFx.shards(_level(), at, colour, 12, 5.0, 1.0)
	ElementFx.shockwave(_level(), Vector3(at.x, .05, at.z), Color(1, .4, .7), 1.4, .3)
	if _flat(at) < 1.3 and target.receive_damage(DAMAGE, at):
		ElementFx.glyphs(_level(), target.global_position + Vector3.UP * 1.6, Color(1, .4, .75), ["POPPED"], .9, .2)
	bubble.queue_free()


func _ring() -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = .96
	torus.outer_radius = 1.0
	torus.rings = 64
	mesh.mesh = torus
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1, .15, .1)
	mesh.material_override = glow
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.top_level = true
	add_child(mesh)
	mesh.global_position = Vector3(boss.global_position.x, .45, boss.global_position.z)
	return mesh


## Whether the engineer's camera is looking its way.
func _facing() -> bool:
	var view: Vector3 = -target.camera_rig.global_basis.z
	var toward: Vector3 = boss.global_position - target.global_position
	return Vector2(view.x, view.z).normalized().dot(Vector2(toward.x, toward.z).normalized()) > .3


func _feet() -> Vector3:
	return Vector3(target.global_position.x, .05, target.global_position.z)


func _flat(point: Vector3) -> float:
	return Vector2(target.global_position.x - point.x, target.global_position.z - point.z).length()


func _level() -> Node:
	return boss.get_parent()


func _story() -> Node:
	var level: Node = boss.get_parent()
	return level.get("presentation") if level != null else null


## Resolve scenery at the visible impact, independently of whether the player evades.
## The expanding ring sweeps only its newly crossed band, even on a long frame.
func smash_props(at: Vector3, radius: float, inner_radius: float = -1.0) -> void:
	for candidate: Node in get_tree().get_nodes_in_group("breakables"):
		var prop: Node3D = candidate as Node3D
		if prop == null or prop.get("health") == 0:
			continue
		var offset: Vector3 = prop.global_position - at
		var distance: float = Vector2(offset.x, offset.z).length()
		# Include the existing equipment's half-width, not just its center point.
		if absf(offset.y) > 1.8 or distance > radius + .425 or distance + .425 < inner_radius:
			continue
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			at + Vector3.UP * .65, prop.global_position + Vector3.UP * .65, 1)
		ray.hit_from_inside = true
		var obstruction: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
		if not obstruction.is_empty() and obstruction.collider != prop:
			continue
		prop.receive_damage(PROP_DAMAGE, boss.global_position)
