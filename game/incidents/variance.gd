extends "res://game/enemies/incident.gd"
## The existing pursuer with one bounded false-positive event and visible openings.
signal false_positives

var duplicated: bool = false
var phase_time: float = 0.0
var exposed: bool = false
var marker: Label3D
var seal: MeshInstance3D


func _ready() -> void:
	super._ready()
	title = "THE VARIANCE"
	motto = "Difference detected. Explanation unavailable."
	marker = Label3D.new()
	marker.position.y = 3.1
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 44
	marker.modulate = Color(.5, 1, .95)
	add_child(marker)
	label.hide()
	seal = MeshInstance3D.new()
	var shape: BoxMesh = BoxMesh.new()
	shape.size = Vector3(.36, .36, .12)
	seal.mesh = shape
	seal.position.y = 2.4
	seal.rotation.z = PI / 4
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(.4, 1, .9)
	seal.material_override = material
	add_child(seal)
	_crown()


## Three truths orbit its head: the same transaction as each system reports it.
var crown: Node3D


func _crown() -> void:
	crown = Node3D.new()
	crown.position.y = 2.9
	visual.add_child(crown)
	for index in range(3):
		var state: Array = [["SUCCESS", Color(.3, 1, .6)], ["FAILED", Color(1, .3, .18)], ["NOT FOUND", Color(1, .75, .25)]][index]
		var screen: MeshInstance3D = MeshInstance3D.new()
		var panel: BoxMesh = BoxMesh.new()
		panel.size = Vector3(.78, .36, .04)
		screen.mesh = panel
		var glow: StandardMaterial3D = StandardMaterial3D.new()
		glow.albedo_color = Color(.02, .03, .04)
		glow.emission_enabled = true
		glow.emission = state[1] * .35
		screen.material_override = glow
		screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var angle: float = index * TAU / 3
		screen.position = Vector3(cos(angle), 0, sin(angle)) * .95
		screen.rotation.y = -angle - PI * .5
		crown.add_child(screen)
		var word: Label3D = Label3D.new()
		word.text = state[0]
		word.font = preload("res://assets/fonts/barlow_condensed_bold.ttf")
		word.font_size = 64
		word.pixel_size = .004
		word.modulate = state[1]
		word.outline_size = 0
		word.double_sided = true
		word.position.z = .03
		screen.add_child(word)
	# A split body: one half reconciled cyan, the other failed red.
	var cold: StandardMaterial3D = StandardMaterial3D.new()
	cold.albedo_color = Color(.12, .2, .26)
	cold.emission_enabled = true
	cold.emission = Color(.1, .5, .6) * .4
	var hot: StandardMaterial3D = cold.duplicate()
	hot.albedo_color = Color(.26, .1, .12)
	hot.emission = Color(.7, .12, .1) * .4
	for index in range(4):
		visual.get_node("RecordDetails/Slab%d" % index).material_override = cold if index % 2 == 0 else hot


func receive_damage(amount: int, source: Vector3) -> bool:
	if not exposed:
		show_blocked()
		return false
	var accepted: bool = super.receive_damage(amount, source)
	if health <= 0:
		marker.text = "✓ RECONCILED"
		seal.hide()
	if health > 0 and health <= max_health / 2 and not duplicated:
		duplicated = true
		false_positives.emit()
	return accepted


func _physics_process(delta: float) -> void:
	if health <= 0:
		marker.text = "✓  RECONCILED"
		return
	# The opening is combat time: impact must freeze it alongside the actor/weapon.
	if hitstop_left > 0:
		super._physics_process(delta)
		return
	crown.rotation.y += delta * (1.6 if exposed else .5)
	crown.position.y = 2.9 + sin(phase_time * 2.0) * .08
	phase_time = fmod(phase_time + delta, 8.0)
	exposed = phase_time >= 4.5
	if exposed:
		melee.cancel()
		var saved_target: CharacterBody3D = target
		target = null
		super._physics_process(delta)
		target = saved_target
		marker.text = "◆  VERIFIED ORIGINAL\nOPEN — STRIKE NOW"
	else:
		super._physics_process(delta)
		marker.text = "◆  VERIFIED ORIGINAL\nSHIELDED — EVADE"
	label.text = "THE VARIANCE  /  %d" % health
