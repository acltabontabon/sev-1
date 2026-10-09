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
