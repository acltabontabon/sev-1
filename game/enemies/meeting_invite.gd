extends "res://game/enemies/incident.gd"
## Area control. Keeps its distance and books telegraphed meeting zones at the
## engineer's feet. Counterplay: leave the circle before it starts, or close in and kill it.

signal zone_requested(position: Vector3)
const VISUAL: PackedScene = preload("res://game/enemies/meeting_invite_visual.tscn")
@export var zone_interval: float = 6.0
@export var preferred_distance: float = 7.0
var zone_cooldown: float = 2.5
var clock: float = 0.0
var details: Node3D


func _ready() -> void:
	title = "THE MEETING INVITE"
	magic_color = Color(.74, .5, 1)
	magic_accent = Color(.55, .78, 1)
	magic_words = ["9:00", "SYNC", "1:1", "ALL HANDS", "RSVP"]
	rig_kind = "invite"
	attack_style = "quake"
	motto = "Your attendance is mandatory."
	max_health = 100
	speed_scale = .9
	super._ready()
	for part: String in ["Visual/Body", "Visual/Eye", "Visual/LeftArm", "Visual/RightArm", "Visual/RecordDetails"]:
		get_node(part).hide()
	details = VISUAL.instantiate()
	visual.add_child(details)
	# The invite itself hovers above the mech that keeps sending it.
	details.get_node("Card").position = Vector3(0, 3.25, 0)
	details.get_node("Card").scale = Vector3.ONE * .75


func reset_enemy() -> void:
	super.reset_enemy()
	zone_cooldown = 2.5


func receive_damage(amount: int, source: Vector3) -> bool:
	var accepted: bool = super.receive_damage(amount, source)
	if health <= 0 and details != null:
		details.rotation.x = -1.4
		details.position.y = -1.3
	return accepted


func _physics_process(delta: float) -> void:
	if hitstop_left > 0:
		hitstop_left = maxf(0, hitstop_left - delta)
		return
	flash_left = maxf(0.0, flash_left - delta)
	blocked_cooldown = maxf(0, blocked_cooldown - delta)
	if shield_left > 0:
		shield_left = maxf(0, shield_left - delta)
		if shield_left == 0:
			drop_shield()
	if health <= 0:
		return
	clock += delta
	stagger_left = maxf(0.0, stagger_left - delta)
	knockback = knockback.move_toward(Vector3.ZERO, delta * 18.0)
	var direction: Vector3 = Vector3.ZERO
	var wish: Variant = _awareness(delta) if is_instance_valid(target) and target.health > 0 else Vector3.ZERO
	if wish != null:
		direction = wish
	elif is_instance_valid(target) and target.health > 0:
		var offset: Vector3 = target.global_position - global_position
		var planar: Vector3 = Vector3(offset.x, 0, offset.z)
		var distance: float = planar.length()
		visual.rotation.y = atan2(-planar.x, -planar.z)
		if stagger_left <= 0:
			if distance < preferred_distance - 1.5:
				direction = -planar.normalized()
			elif distance > preferred_distance + 2.0:
				direction = planar.normalized()
				if NavigationServer3D.map_get_iteration_id(navigation.get_navigation_map()) > 0:
					navigation.target_position = target.global_position
					var next: Vector3 = navigation.get_next_path_position() - global_position
					direction = Vector3(next.x, 0, next.z).normalized()
			else:
				direction = planar.normalized().cross(Vector3.UP) * (.4 if sin(clock * .7) > 0 else -.4)
			direction = (direction + _separation()).normalized() if not direction.is_zero_approx() else _separation()
		zone_cooldown -= delta
		if zone_cooldown <= 0 and distance < 16:
			zone_cooldown = zone_interval
			ElementFx.sigil(self, global_position, magic_color, 1.0, 1.0, 3.0)
			rig.cast(1.0)
			# The meeting drops from above onto the booked spot as the zone opens.
			ElementFx.pillar(self, Vector3(target.global_position.x, global_position.y, target.global_position.z), magic_color, 1.4, 1.1)
			ElementFx.glyphs(self, target.global_position + Vector3.UP * 1.9, magic_color, magic_words.slice(0, 3), 1.1, .9)
			zone_requested.emit(Vector3(target.global_position.x, global_position.y, target.global_position.z))
	velocity.x = direction.x * move_speed + knockback.x
	velocity.z = direction.z * move_speed + knockback.z
	if wish != null and awareness != Awareness.NOTICING:
		label.text = activity if awareness == Awareness.UNAWARE else "LOOKING FOR AN OWNER…"
	velocity.y = 0.0 if is_on_floor() else velocity.y - 22.0 * delta
	move_and_slide()
	# Hovering card: a slow bob and a little tilt toward its invitee.
	details.position.y = sin(clock * 2.0) * .12
	details.rotation.z = sin(clock * 1.3) * .08
	var booking: bool = zone_cooldown < 1.2 and wish == null
	if wish == null:
		label.text = "BOOKING…" if booking else ""
	if blocked_cooldown > 0 or shield_left > 0:
		label.text = "BLOCKED" if blocked_cooldown > 0 else "PROTECTED"
