extends "res://game/enemies/incident.gd"
## Escalating threat. Every few seconds it goes unhit, it grows: bigger reach, more
## damage, more health, and at the last stage a full spin. Any hit resets the clock.

signal grew(stage: int)
const VISUAL: PackedScene = preload("res://game/enemies/scope_creep_visual.tscn")
const SCALES: Array[float] = [.75, 1.05, 1.35, 1.7]
@export var growth_seconds: float = 6.0
@export var growth_health: int = 50
var growth: int = 0
var unhit: float = 0.0
var spin_next: bool = false
var base_damage: int = 10
var base_reach: float = 1.45
var details: Node3D
var pop: Label3D
var pop_left: float = 0.0
var sting: AudioStreamPlayer3D


func _ready() -> void:
	title = "SCOPE CREEP"
	magic_color = Color(.72, 1, .3)
	magic_accent = Color(1, .9, .3)
	magic_words = ["+1 REQ", "JUST ONE MORE", "NICE TO HAVE", "ALSO MOBILE"]
	rig_kind = "scope"
	attack_style = "splat"
	motto = "One tiny additional requirement."
	max_health = 90
	speed_scale = 1.35
	super._ready()
	for part: String in ["Visual/Body", "Visual/Eye", "Visual/LeftArm", "Visual/RightArm", "Visual/RecordDetails"]:
		get_node(part).hide()
	details = VISUAL.instantiate()
	visual.add_child(details)
	# A slime wearing every requirement anyone stuck on it: notes plastered over the dome.
	for part: String in ["Eye-1", "Eye1", "Leg-1", "Leg1"]:
		details.get_node(part).hide()
	var dome: AABB = rig.bounds()
	var radius: Vector3 = Vector3(dome.size.x * .5, dome.size.y, dome.size.z * .5)
	for index in range(12):
		var angle: float = index * 2.39996 + .6
		var rise: float = .2 + 1.1 * fmod(index * .618, 1.0)
		var out: Vector3 = Vector3(cos(angle) * cos(rise), sin(rise), sin(angle) * cos(rise))
		var note: Node3D = details.get_node("Note%d" % index)
		note.position = Vector3(dome.get_center().x, dome.position.y, dome.get_center().z) + out * radius * .97
		# Flat against the slime: the note's thin axis follows the surface normal.
		var normal: Vector3 = (out / radius).normalized()
		var side: Vector3 = normal.cross(Vector3.UP if absf(normal.y) < .95 else Vector3.RIGHT).normalized()
		note.basis = Basis(side, normal, side.cross(normal)).rotated(normal, index * .7) * Basis.from_scale(Vector3(.55, 1, .55))
	pop = Label3D.new()
	pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pop.font_size = 64
	pop.pixel_size = .005
	pop.outline_size = 12
	pop.modulate = Color(1, .9, .35)
	pop.position.y = 3.0
	add_child(pop)
	sting = AudioStreamPlayer3D.new()
	sting.stream = preload("res://assets/audio/sfx/chat_ping.ogg")
	sting.bus = &"Effects"
	add_child(sting)
	_apply_growth()


func reset_enemy() -> void:
	super.reset_enemy()
	growth = 0
	unhit = 0
	if details != null:
		_apply_growth()


func _apply_growth() -> void:
	var size: float = SCALES[growth]
	# Only the model grows; the strike arc and telegraph stay in world units so the
	# warning always shows the true reach.
	details.scale = Vector3.ONE * size
	if rig != null:
		rig.scale = Vector3.ONE * size
	melee.damage = roundi(base_damage * (1.0 + .3 * growth))
	melee.reach = base_reach * size / SCALES[0]
	melee.windup = .45
	melee.active_time = .12
	melee.recovery = .6
	melee.half_angle_degrees = 60
	melee.arc_color = Color(1, .9, .3)
	melee.rebuild_arc()
	tell.mesh = melee.arc.mesh
	attack_distance = 1.2 * size / SCALES[0]
	for index in range(12):
		details.get_node("Note%d" % index).visible = index < 6 + growth * 2


func grow() -> void:
	if growth >= SCALES.size() - 1 or health <= 0:
		return
	growth += 1
	unhit = 0
	max_health += growth_health
	health += growth_health
	health_changed.emit(health)
	_apply_growth()
	pop.text = "+1 REQUIREMENT"
	ElementFx.shards(self, global_position + Vector3.UP * .6, magic_accent, 14 + growth * 6, 5.0, 1.1, Vector3.UP, .14)
	ElementFx.shockwave(self, global_position, magic_color, 2.0 + growth, .5)
	pop_left = 1.6
	if DisplayServer.get_name() != "headless":
		sting.pitch_scale = 1.0 + growth * .18
		sting.play()
	grew.emit(growth)


func receive_damage(amount: int, source: Vector3) -> bool:
	var accepted: bool = super.receive_damage(amount, source)
	if accepted:
		unhit = 0
	if health <= 0 and details != null:
		details.rotation.z = 1.3
		details.position.y = -.3
	return accepted


func _physics_process(delta: float) -> void:
	var was_attacking: bool = melee.attacking
	super._physics_process(delta)
	if health <= 0 or hitstop_left > 0:
		return
	# It only grows while it is actually working on you.
	if awareness == Awareness.ENGAGED:
		unhit += delta
	if unhit >= growth_seconds:
		grow()
	# Final stage alternates its jab with a full spin: stop chasing, start leaving.
	if was_attacking and not melee.attacking and growth == SCALES.size() - 1:
		spin_next = not spin_next
		melee.half_angle_degrees = 180 if spin_next else 60
		melee.rebuild_arc()
		tell.mesh = melee.arc.mesh
	pop_left = maxf(0, pop_left - delta)
	pop.visible = pop_left > 0
	pop.position.y = 3.0 * SCALES[growth] + (1.6 - pop_left) * .5
	if label.text.is_empty() and growth > 0:
		label.text = "+%d SCOPE" % growth
	label.position.y = 2.5 * SCALES[growth] / SCALES[0] * .8
