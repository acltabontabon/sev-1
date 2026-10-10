extends "res://game/enemies/incident.gd"
## Minion: a literal software bug. Fast, fragile (any accepted hit fixes it), a weak
## bite, arrives in swarms beside a wave and never blocks wave progress. The incident
## closes any survivors as WONTFIX when the wave set ends.


func _ready() -> void:
	title = "BUG"
	motto = "Cannot reproduce."
	magic_color = Color(.55, 1, .35)
	magic_accent = Color(.85, 1, .4)
	magic_radius = .55
	rig_kind = "bug"
	attack_style = "nip"
	max_health = 10
	speed_scale = 1.6
	separation = .8
	super._ready()
	melee.damage = 4
	melee.reach = 1.3
	melee.half_angle_degrees = 55
	melee.windup = .34
	melee.active_time = .1
	melee.recovery = .45
	melee.arc_color = Color(.6, 1, .35)
	melee.rebuild_arc()
	tell.mesh = melee.arc.mesh
	attack_distance = 1.15
	var shape: CapsuleShape3D = ($Collision.shape as CapsuleShape3D).duplicate()
	shape.radius = .3
	shape.height = .8
	$Collision.shape = shape
	$Collision.position.y = .4
	# One hit fixes it (the bar only shows while damaged), and no activity caption.
	label.hide()


func receive_damage(amount: int, source: Vector3) -> bool:
	return super.receive_damage(maxi(amount, health), source)
