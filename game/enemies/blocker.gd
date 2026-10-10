extends "res://game/enemies/incident.gd"
## Defensive support. A telegraphed cast shields nearby allies; never itself.
## Counterplay: hit it during the cast, kill it first, or pull allies out of range.

signal shield_cast(count: int)
signal cast_interrupted
const VISUAL: PackedScene = preload("res://game/enemies/blocker_visual.tscn")
@export var cast_interval: float = 7.0
@export var cast_time: float = 1.1
@export var shield_seconds: float = 5.0
@export var shield_radius: float = 6.0
@export var interrupt_damage: int = 50
var cast_cooldown: float = 3.0
var casting: float = -1.0
var cast_damage: int = 0
var details: Node3D
var ring: MeshInstance3D
var beam: MeshInstance3D
var hum: AudioStreamPlayer3D


func _ready() -> void:
	title = "THE BLOCKER"
	magic_color = Color(1, .68, .12)
	magic_accent = Color(1, .86, .32)
	magic_words = ["BLOCKED", "WAITING ON", "DEPENDENCY", "PENDING APPROVAL"]
	magic_radius = 1.4
	rig_kind = "blocker"
	attack_style = "quake"
	motto = "Awaiting dependency."
	max_health = 260
	speed_scale = .7
	separation = 1.8
	super._ready()
	for part: String in ["Visual/Body", "Visual/Eye", "Visual/LeftArm", "Visual/RightArm", "Visual/RecordDetails"]:
		get_node(part).hide()
	details = VISUAL.instantiate()
	visual.add_child(details)
	# The rig is the body now; it carries the hazard-striped excuse as its shield.
	for part: String in ["Torso", "Head", "Leg-1", "Leg1"]:
		details.get_node(part).hide()
	details.get_node("Shield").scale = Vector3.ONE * .68
	details.get_node("Shield").position.y = .95
	melee.damage = 18
	melee.reach = 2.0
	melee.half_angle_degrees = 50
	melee.windup = .8
	melee.active_time = .16
	melee.recovery = 1.0
	melee.arc_color = Color(1, .62, .15)
	melee.rebuild_arc()
	tell.mesh = melee.arc.mesh
	attack_distance = 1.8
	var amber: StandardMaterial3D = StandardMaterial3D.new()
	amber.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	amber.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	amber.albedo_color = Color(1, .62, .15, .28)
	amber.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring = MeshInstance3D.new()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = shield_radius
	disc.bottom_radius = shield_radius
	disc.height = .02
	ring.mesh = disc
	ring.position.y = .04
	ring.material_override = amber
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	beam = MeshInstance3D.new()
	var column: CylinderMesh = CylinderMesh.new()
	column.top_radius = .08
	column.bottom_radius = .3
	column.height = 6
	beam.mesh = column
	beam.position.y = 3
	beam.material_override = amber
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)
	hum = AudioStreamPlayer3D.new()
	hum.stream = preload("res://assets/audio/sfx/force_field.ogg")
	hum.bus = &"Effects"
	hum.volume_db = -4
	add_child(hum)
	_stop_cast()


func reset_enemy() -> void:
	super.reset_enemy()
	if ring != null:
		cast_cooldown = 3.0
		_stop_cast()


func allies_in_range() -> Array[Node3D]:
	var found: Array[Node3D] = []
	for other: Node in get_tree().get_nodes_in_group("enemies"):
		if other != self and other is CharacterBody3D and other.health > 0 and not other.has_signal("false_positives"):
			if other.global_position.distance_to(global_position) <= shield_radius:
				found.append(other)
	return found


func receive_damage(amount: int, source: Vector3) -> bool:
	var accepted: bool = super.receive_damage(amount, source)
	if accepted and casting >= 0:
		cast_damage += amount
		if cast_damage >= interrupt_damage:
			_stop_cast()
			cast_cooldown = cast_interval * .6
			stagger_left = .7
			label.text = "INTERRUPTED"
			cast_interrupted.emit()
	if health <= 0:
		_stop_cast()
		details.rotation.x = 1.2
		details.position.y = -.4
		# The dependency is resolved: every shield it granted drops at once.
		for other: Node in get_tree().get_nodes_in_group("enemies"):
			if other is CharacterBody3D and other.shield_left > 0:
				other.drop_shield()
	return accepted


func _stop_cast() -> void:
	casting = -1.0
	ring.hide()
	beam.hide()
	hum.stop()


func _physics_process(delta: float) -> void:
	if health <= 0 or hitstop_left > 0 or casting < 0:
		super._physics_process(delta)
	if health <= 0 or hitstop_left > 0:
		return
	if casting >= 0:
		# Planted while casting: the opening to punish it.
		casting += delta
		velocity = Vector3(knockback.x, velocity.y, knockback.z)
		knockback = knockback.move_toward(Vector3.ZERO, delta * 18.0)
		move_and_slide()
		var pulse: float = .7 + .3 * sin(casting * 18.0)
		ring.scale = Vector3(pulse, 1, pulse) * smoothstep(0, cast_time, casting)
		label.text = "CASTING"
		if casting >= cast_time:
			var allies: Array[Node3D] = allies_in_range()
			for ally: Node3D in allies:
				ally.protect(shield_seconds)
			_stop_cast()
			cast_cooldown = cast_interval
			ElementFx.shockwave(self, global_position, magic_color, shield_radius * 2.0, .55)
			for ally: Node3D in allies:
				ElementFx.motes(self, ally.global_position + Vector3.UP, magic_accent, 12, 2.5, .6, 1.5, .14)
			shield_cast.emit(allies.size())
		return
	cast_cooldown -= delta
	if cast_cooldown <= 0 and awareness == Awareness.ENGAGED and not melee.attacking and stagger_left <= 0 and not allies_in_range().is_empty():
		casting = 0.0
		cast_damage = 0
		ring.show()
		beam.show()
		ElementFx.sigil(self, global_position, magic_color, shield_radius * .5, cast_time + .2, 1.2)
		rig.cast(cast_time)
		ElementFx.glyphs(self, global_position + Vector3.UP * 2.3, magic_color, ["AWAITING DEPENDENCY"], cast_time, 0.0)
		if DisplayServer.get_name() != "headless":
			hum.play()
	# Shield bash: the shield itself is the weapon.
	var shield: Node3D = details.get_node("Shield")
	var push: float = 0.0
	if melee.attacking:
		push = smoothstep(0, 1, melee.elapsed / melee.windup) * -.15 if melee.elapsed < melee.windup else (.55 if melee.is_active() else .2)
	shield.position.z = -.52 - push
