extends Node3D
## Small, harmless appliance hauntings. The incident owns E, coffee and progression;
## this room component owns repeat reactions, props and a clean restart.

const LINES: Dictionary = {
	"microwave": [
		"SAM: Nobody panic. Lunch has requested legal representation.",
		"SAM: The mugs have formed a tribunal. You're being tried for reheating fish.",
		"SAM: Unanimous verdict: lunch gets a lunch break. We don't."],
	"vending": [
		"SNACK-O-MATIC: Payment accepted. Snack promoted to a management position.",
		"SNACK-O-MATIC: Your crisps are in a meeting. Here is their expense claim.",
		"SNACK-O-MATIC: Refund denied. You have been charged a disappointment fee."],
	"fridge": [
		"CASEY: That lunch predates my employment. It now has more annual leave than me.",
		"CASEY: The leftovers have unionised. Honestly? Good for them.",
		"CASEY: They want dental. They don't have teeth. Yet."],
	"poster": [
		"WELLNESS: Breathe in. Hold. Hold until your manager approves the exhale.",
		"WELLNESS: Your mandatory relaxation has been marked as a performance concern.",
		"WELLNESS: Congratulations. You are now the designated wellness champion. No extra pay."]}

var counts: Dictionary = {}
var room: Node3D
var caption: Label3D
var council: Node3D
var leftovers: Node3D
var receipt: MeshInstance3D
var sound: AudioStreamPlayer3D
var active: String = ""
var remaining: float = 0.0
var clock: float = 0.0
var vending_home: Vector3
var light_energy: float


func _ready() -> void:
	room = get_parent()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	vending_home = room.get_node("VendingBody").position
	light_energy = room.get_node("PantryLight").light_energy
	caption = Label3D.new()
	caption.name = "ApplianceReply"
	caption.font = preload("res://assets/fonts/inter_variable.ttf")
	caption.font_size = 32
	caption.pixel_size = .0045
	caption.width = 720
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.outline_size = 8
	caption.modulate = Color(1, .86, .64)
	add_child(caption)
	council = Node3D.new()
	council.name = "LunchTribunal"
	council.position = Vector3(29.8, 1.55, 8.8)
	add_child(council)
	for index in range(3):
		var mug: Node3D = Node3D.new()
		mug.position = Vector3(-.45, 0, (index - 1) * .4)
		council.add_child(mug)
		_cylinder(mug, .12, .24, preload("res://game/rooms/office/ceramic.tres"))
		var handle: TorusMesh = TorusMesh.new()
		handle.inner_radius = .038
		handle.outer_radius = .063
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.mesh = handle
		mesh.material_override = preload("res://game/rooms/office/ceramic.tres")
		mesh.position.x = .12
		mesh.rotation.x = PI / 2
		mug.add_child(mesh)
		# Two coffee-dark eyes: office crockery has acquired a quorum.
		for z: float in [-.03, .03]:
			var eye: MeshInstance3D = _box(mug, Vector3(.008, .025, .018), preload("res://game/rooms/office/black.tres"))
			eye.position = Vector3(-.117, .04, z)
	leftovers = Node3D.new()
	leftovers.name = "OrganisedLeftovers"
	leftovers.position = Vector3(29.55, 1.5, 11.55)
	add_child(leftovers)
	for index in range(3):
		var tub: MeshInstance3D = _box(leftovers, Vector3(.22, .12, .18), preload("res://game/rooms/office/ceramic.tres"))
		tub.position = Vector3(0, index * .22, (index - 1) * .28)
		var lid: MeshInstance3D = _box(tub, Vector3(.24, .025, .2), preload("res://game/rooms/office/mint.tres"))
		lid.position.y = .07
	var placard: Label3D = Label3D.new()
	placard.text = "LEFTOVERS LOCAL 404\nLET US EXPIRE"
	placard.font_size = 28
	placard.pixel_size = .002
	placard.rotation.y = -PI / 2
	placard.position = Vector3(-.13, .35, 0)
	leftovers.add_child(placard)
	receipt = _box(self, Vector3(.28, .7, .005), preload("res://game/rooms/office/paper.tres"))
	receipt.name = "DisappointmentReceipt"
	receipt.position = vending_home + Vector3(0, -.42, -.43)
	# Printed stripes imply a receipt; the actual joke stays readable in the caption.
	for index in range(7):
		var stripe: MeshInstance3D = _box(receipt, Vector3(.18 if index < 5 else .1, .012, .002), preload("res://game/rooms/office/black.tres"))
		stripe.position = Vector3(0, .23 - index * .075, -.004)
	sound = AudioStreamPlayer3D.new()
	sound.stream = preload("res://assets/audio/sfx/ui_error.ogg")
	sound.bus = "Effects"
	sound.volume_db = -12
	sound.max_distance = 9
	add_child(sound)
	reset()


func _box(parent: Node3D, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var shape: BoxMesh = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh


func _cylinder(parent: Node3D, radius: float, height: float, material: Material) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var shape: CylinderMesh = CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	mesh.mesh = shape
	mesh.material_override = material
	parent.add_child(mesh)


func reset() -> void:
	counts.clear()
	_settle()
	receipt.hide()
	sound.stop()


func _settle() -> void:
	active = ""
	remaining = 0.0
	clock = 0.0
	caption.hide()
	council.hide()
	leftovers.hide()
	room.get_node("VendingBody/Mesh").position = Vector3.ZERO
	room.get_node("PantryLight").light_energy = light_energy


func react(key: String, crew: Node3D) -> String:
	if not LINES.has(key):
		return ""
	_settle()
	counts[key] = int(counts.get(key, 0)) + 1
	var line: String = LINES[key][mini(int(counts[key]) - 1, 2)]
	active = key
	remaining = 7.0
	caption.text = line
	var anchor: String = {"microwave": "Microwave", "vending": "VendingMachine", "fridge": "Fridge", "poster": "WellnessPoster"}[key]
	caption.position = room.get_node("SpawnPoints/" + anchor).position + Vector3.UP * 2.45
	caption.show()
	council.visible = key == "microwave"
	leftovers.visible = key == "fridge"
	if key == "vending":
		receipt.show()
	if DisplayServer.get_name() != "headless":
		sound.stream = preload("res://assets/audio/sfx/chat_ping_soft.ogg") if key == "poster" else preload("res://assets/audio/sfx/ui_error.ogg")
		sound.position = caption.position - Vector3.UP
		sound.play()
	# Let the existing worker react without moving them or interrupting a talk/fight.
	if key in ["microwave", "fridge"] and not crew.was_fighting:
		var person: Dictionary = crew.person("Facilities" if key == "microwave" else "Microwave")
		if not person.is_empty() and not person.dead and person.aid_hold <= 0.0:
			var animator: AnimationPlayer = person.animator
			if animator.has_animation("ual/no"):
				animator.play("ual/no", .2)
				person.aid_hold = 1.5
	return line


func _process(delta: float) -> void:
	if remaining <= 0.0:
		return
	remaining = maxf(0.0, remaining - delta)
	clock += delta
	if active == "microwave":
		for index in range(council.get_child_count()):
			var mug: Node3D = council.get_child(index)
			mug.position.y = .08 * sin(clock * 2.8 + index * 2.0)
			mug.rotation.z = .16 * sin(clock * 3.0 + index)
	elif active == "fridge":
		leftovers.position.y = 1.5 + .12 * sin(clock * 2.0)
		leftovers.rotation.x = .08 * sin(clock * 3.0)
	elif active == "vending":
		room.get_node("VendingBody/Mesh").position.x = .025 * sin(clock * 35) * maxf(0.0, 1.0 - clock)
	elif active == "poster":
		room.get_node("PantryLight").light_energy = light_energy * (1.0 + .15 * sin(clock * 1.8))
	if remaining == 0.0:
		_settle()
