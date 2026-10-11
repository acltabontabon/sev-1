extends StaticBody3D
## Six finite arena props. No kill credit, loot or damage to the player. Baked routes avoid intact props.
@export var canister: bool = false
var health: int = 32
var intact: Node3D
var shape: CollisionShape3D
var debris: Array[RigidBody3D] = []
var hit_sound: AudioStreamPlayer3D


func _ready() -> void:
	add_to_group("breakables")
	collision_layer = 1
	collision_mask = 1
	intact = Node3D.new()
	add_child(intact)
	shape = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(.85, 1.3, .85)
	shape.shape = box
	shape.position.y = .65
	add_child(shape)
	var steel: Material = preload("res://game/rooms/office/metal.tres")
	var dark: Material = preload("res://game/rooms/office/plastic.tres")
	if canister:
		var drum: CylinderMesh = CylinderMesh.new()
		drum.top_radius = .32
		drum.bottom_radius = .36
		drum.height = 1.15
		drum.radial_segments = 20
		_part(drum, Vector3(0,.59,0), steel)
		for y: float in [.15, .95]:
			var rim: CylinderMesh = CylinderMesh.new()
			rim.top_radius = .375
			rim.bottom_radius = .375
			rim.height = .085
			_part(rim, Vector3(0,y,0), dark)
		_box(Vector3(0,1.22,0),Vector3(.25,.12,.18),dark)
	else:
		_box(Vector3(0,.61,0),Vector3(.85,1.15,.85),dark)
		for x: float in [-.36,.36]:
			_box(Vector3(x,.61,.44),Vector3(.08,1.18,.065),steel)
		for y: float in [.15,1.1]:
			_box(Vector3(0,y,.44),Vector3(.85,.07,.065),steel)
		_box(Vector3(0,1.22,0),Vector3(.4,.07,.12),steel)
	var tag: Label3D = Label3D.new()
	tag.name = "EquipmentLabel"
	tag.text = "SLA\nCOOLANT" if canister else "SPARE\nCAPACITY"
	tag.font = preload("res://assets/fonts/barlow_condensed_semibold.ttf")
	tag.font_size = 40
	tag.pixel_size = .0029
	tag.position = Vector3(0,.64,.37 if canister else .435)
	tag.modulate = Color(.75,.8,.72)
	tag.outline_size = 0
	intact.add_child(tag)
	hit_sound = AudioStreamPlayer3D.new()
	hit_sound.stream = preload("res://assets/audio/sfx/heavy_impact.ogg")
	hit_sound.bus = &"Effects"
	hit_sound.unit_size = 8
	hit_sound.volume_db = -8
	add_child(hit_sound)


func receive_damage(amount: int, source: Vector3) -> bool:
	if health <= 0 or amount <= 0:
		return false
	health = maxi(0, health - amount)
	if DisplayServer.get_name() != "headless":
		hit_sound.pitch_scale = .8 if health == 0 else 1.05
		hit_sound.play()
	if health > 0:
		var recoil: Tween = create_tween()
		intact.rotation.z = .09
		recoil.tween_property(intact, "rotation:z", 0.0, .18).set_trans(Tween.TRANS_SINE)
		return true
	intact.hide()
	collision_layer = 0
	shape.set_deferred("disabled", true)
	var away: Vector3 = global_position - source
	away.y = 0
	away = away.normalized() if away.length() > .01 else Vector3.BACK
	for i in range(6):
		var piece: RigidBody3D = RigidBody3D.new()
		piece.collision_layer = 128
		piece.collision_mask = 1
		piece.mass = .4
		piece.angular_damp = 2.5
		piece.linear_damp = 1.8
		var mesh: MeshInstance3D = MeshInstance3D.new()
		var size: Vector3 = Vector3(.28,.12,.38)
		if canister and i < 2:
			var cap: CylinderMesh = CylinderMesh.new()
			cap.top_radius = .35
			cap.bottom_radius = .35
			cap.height = .075
			cap.radial_segments = 20
			mesh.mesh = cap
			size = Vector3(.7,.075,.7)
		else:
			var panel: BoxMesh = BoxMesh.new()
			size = Vector3(.30,.58,.06) if canister else Vector3(.55,.07,.62)
			panel.size = size
			mesh.mesh = panel
		mesh.material_override = preload("res://game/rooms/office/metal.tres")
		piece.add_child(mesh)
		var collider: CollisionShape3D = CollisionShape3D.new()
		var bounds: BoxShape3D = BoxShape3D.new()
		bounds.size = size
		collider.shape = bounds
		piece.add_child(collider)
		add_child(piece)
		piece.position = Vector3((i%2-.5)*.3,.2+i*.16,0)
		piece.linear_velocity = away * (1.0+i*.12) + Vector3.UP * (1.4+i*.12)
		piece.angular_velocity = Vector3(i*.3,1.2,-1.0)
		debris.append(piece)
	if canister:
		ElementFx.shockwave(self, global_position + Vector3.UP * .15, Color(.55,.72,.75,.5), 1.0, .45)
	return true


func reset_prop() -> void:
	health = 32
	collision_layer = 1
	shape.set_deferred("disabled", false)
	intact.rotation = Vector3.ZERO
	intact.show()
	for piece: RigidBody3D in debris:
		if is_instance_valid(piece):
			piece.queue_free()
	debris.clear()
	ElementFx.clear_from(self)
	hit_sound.stop()


func _part(mesh: Mesh, at: Vector3, material: Material) -> void:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = at
	intact.add_child(part)


func _box(at: Vector3, size: Vector3, material: Material) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	_part(mesh, at, material)
