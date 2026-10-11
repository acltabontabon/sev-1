extends Node3D
## A small, staged midnight frontage. Owned and removed by the ending, no gameplay AI.
const MOTION: AnimationLibrary = preload("res://game/player/engineer_animations.res")
const CREW: Script = preload("res://game/incidents/coworkers.gd")
const FONT: Font = preload("res://assets/fonts/barlow_condensed_semibold.ttf")
const PINK: Color = Color(.32, .14, .19)
const CYAN: Color = Color(.22, .34, .4)
var walkers: Array[Dictionary] = []
var patrons: Array[Node3D] = []
var club_light: OmniLight3D
const SECONDS: float = 12.0
const EXIT_X: float = 6.2
var door_panels: Array[MeshInstance3D] = []
var animations: Array[Dictionary] = []
var door_open: float = 0.0
var pink: StandardMaterial3D


func _ready() -> void:
	name = "NightlifeStreet"
	position = Vector3(-14.5, -70, 0)
	rotation.y = -PI / 2.0
	var stone: StandardMaterial3D = preload("res://game/rooms/office/stone.tres").duplicate()
	stone.albedo_color = Color(.22, .25, .28)
	stone.roughness = .65
	var metal: StandardMaterial3D = _material(Color(.025, .025, .035), .35)
	var glass: StandardMaterial3D = _material(Color(.06, .09, .13), .12)
	glass.metallic = .65
	pink = _material(PINK, .3, 2.2)
	var cyan: StandardMaterial3D = _material(CYAN, .3, 2.0)
	var amber: StandardMaterial3D = _material(Color(1, .55, .12), .4, 1.4)
	# Ground-level shopfronts conceal only the bottom of the existing curtain wall.
	_box("ClubFacade", Vector3(-1.5, 2.25, 0), Vector3(7, 4.5, .3), metal)
	_box("ClubCanopy", Vector3(-1.5, 3.6, .9), Vector3(7.3, .25, 1.9), metal)
	_box("CanopyNeon", Vector3(-1.5, 3.49, 1.83), Vector3(7.1, .045, .045), pink)
	_box("ClubSign", Vector3(-1.5, 2.95, .22), Vector3(6.4, .9, .15), stone)
	_text("ClubName", "VELVET", Vector3(-1.5, 3.08, .32), .010, PINK)
	_text("ClubType", "STRIP CLUB  /  LAST ORDERS", Vector3(-1.5, 2.66, .32), .0034, Color(1, .65, .8))
	_box("ClubDoor", Vector3(-1.7, 1.24, .22), Vector3(1.45, 2.48, .12), glass)
	for side in [-1.0, 1.0]:
		_box("DoorNeon", Vector3(-1.7 + side * .79, 1.26, .32), Vector3(.035, 2.52, .04), pink)
		_box("Window", Vector3(-1.5 + side * 2.35, 1.25, .22), Vector3(1.7, 2.15, .08), glass)
		for slat in range(9):
			_box("Louvre", Vector3(-1.5 + side * 2.35, .3 + slat * .23, .3), Vector3(1.74, .065, .1), metal)
	_box("DoorHandle", Vector3(-1.21, 1.1, .32), Vector3(.035, .45, .04), amber)
	_text("EntryNotice", "21+", Vector3(-1.7, 1.55, .31), .004, Color(1, .75, .8))
	# Closed counters and tired venue lights frame the empty office entrance.
	_box("FoodFacade", Vector3(-12.8, 1.95, 0), Vector3(4.8, 3.9, .3), stone)
	_box("FoodWindow", Vector3(-12.8, 1.7, .2), Vector3(3.9, 1.6, .08), metal)
	_box("FoodCounter", Vector3(-12.8, .94, .7), Vector3(4.2, .17, 1.25), metal)
	_box("FoodAwning", Vector3(-12.8, 2.6, .85), Vector3(4.8, .17, 1.8), metal)
	_text("FoodSign", "MIDNIGHT NOODLES", Vector3(-12.8, 3.08, .23), .0048, Color(1, .7, .28))
	_text("Menu", "CLOSED  /  SEE YOU MONDAY", Vector3(-12.8, 1.93, .34), .0028, Color(.6, .62, .6))
	_box("BarFacade", Vector3(15.25, 2.0, 0), Vector3(5.5, 4, .3), stone)
	_box("BarGlass", Vector3(15.25, 1.3, .22), Vector3(4.6, 2.3, .12), glass)
	_text("BarSign", "BLUE HOUR", Vector3(15.25, 2.96, .3), .008, CYAN)
	_text("BarCaption", "CLOSED  /  LAST TRAIN GONE", Vector3(15.25, 2.45, .3), .003, Color(.5, .8, 1))
	_box("BarNeon", Vector3(15.25, 3.5, .28), Vector3(4.7, .045, .045), cyan)
	# A deep vestibule: the hero begins behind opening panels, clear of the tower wall.
	_box("OfficeBack", Vector3(EXIT_X, 1.8, 0), Vector3(6.2, 3.6, .2), metal)
	for side in [-1.0, 1.0]:
		_box("OfficePier", Vector3(EXIT_X + side * 2.4, 1.8, 1.25), Vector3(1.4, 3.6, 2.5), stone)
	_box("OfficeHeader", Vector3(EXIT_X, 3.25, 1.25), Vector3(6.2, .7, 2.5), metal)
	_box("VestibuleFloor", Vector3(EXIT_X, .012, 1.3), Vector3(3.4, .024, 2.6), stone)
	for side in [-1.0, 1.0]:
		var panel: MeshInstance3D = _box("OfficeDoorLeft" if side < 0 else "OfficeDoorRight", Vector3(EXIT_X + side * .8, 1.4, 2.5), Vector3(1.58, 2.8, .08), glass)
		var rail: MeshInstance3D = _box("DoorRail", Vector3(0, -.25, .06), Vector3(1.55, .055, .07), stone)
		rail.reparent(panel, false)
		door_panels.append(panel)
	_text("OfficeExitSign", "SYNERGEX / EXIT", Vector3(EXIT_X, 3.25, 2.56), .006, Color(.75, .86, 1))
	_light(Vector3(EXIT_X, 2.7, 1.2), Color(.72, .85, 1), 1.7, 4.5)
	# Pavement, kerb and wet asphalt; the engineer's route is outside the patrons.
	_box("Sidewalk", Vector3(1, -.015, 3.3), Vector3(42, .07, 6.6), stone)
	var asphalt: StandardMaterial3D = _material(Color(.022, .028, .04), .16)
	_box("WetRoad", Vector3(1, -.025, 11.1), Vector3(60, .06, 9), asphalt)
	_box("Kerb", Vector3(1, .015, 6.58), Vector3(42, .14, .16), stone)
	for index in range(19):
		_box("PavingJoint", Vector3(-20 + index * 2.3, .024, 3.3), Vector3(.022, .008, 6.4), metal)
	for index in range(5):
		_box("LaneDash", Vector3(-16 + index * 7, .012, 11.5), Vector3(3.0, .008, .12), _material(Color(.45, .43, .3), .3))
	# Soft, broken reflections on the road, with no extra render viewport.
	for index in range(2):
		var reflection: MeshInstance3D = MeshInstance3D.new()
		reflection.name = "NeonPuddle%d" % index
		var plane: PlaneMesh = PlaneMesh.new()
		plane.size = Vector2(2.8, 4.2)
		reflection.mesh = plane
		var sheen: ShaderMaterial = ShaderMaterial.new()
		sheen.shader = preload("res://game/incidents/neon_puddle.gdshader")
		sheen.set_shader_parameter("tint", PINK if index == 0 else CYAN)
		sheen.set_shader_parameter("phase", float(index) * 1.7)
		reflection.material_override = sheen
		reflection.position = Vector3(-1.5 if index == 0 else 15.25, .013, 8.5)
		reflection.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(reflection)
	club_light = _light(Vector3(-1.5, 2.6, 1.9), PINK, .65, 6.0)
	_light(Vector3(15.2, 2.3, 1.5), CYAN, .7, 7)
	_light(Vector3(-12.8, 2.2, 1.4), Color(.72, .64, .48), .45, 6)
	# The last stragglers outside closing venues; the empty pavement carries the shot.
	for index in range(3):
		_box("QueuePost", Vector3(-.2 + index * .9, .5, 2.2), Vector3(.07, 1, .07), metal)
		if index < 2:
			_box("VelvetRope", Vector3(.25 + index * .9, .85, 2.2), Vector3(.9, .055, .055), _material(Color(.32, .02, .05), .8))
	_person("DoorHost", "suit_male.fbx", Vector3(-2.9, .02, 1.4), .2, "ual/phone", Color(.045, .045, .065))
	_person("FoodCustomer", "casual3_male.fbx", Vector3(-12.7, .02, 1.7), PI, "ual/phone", Color(.45, .27, .12))
	_walker("PedestrianA", "casual_male.fbx", Vector3(-17, .02, 4.2), Vector3(-8, .02, 4.2), Color(.3, .42, .5))
	_walker("PedestrianB", "casual2_female.fbx", Vector3(20, .02, 4.5), Vector3(11, .02, 4.5), Color(.6, .22, .4))

	# Rain-darkened frontage: downpipes, shutter, drains and a deserted waiting bench.
	for x in [-5.1, 3.0, 12.2, 18.3]:
		_box("Downpipe", Vector3(x, 1.95, .28), Vector3(.09, 3.9, .09), metal)
	for slat in range(10):
		_box("FoodShutter", Vector3(-12.8, 1.03 + slat * .14, .27), Vector3(3.86, .035, .045), stone)
	for x in [-8.0, 9.8]:
		_box("StormDrain", Vector3(x, .063, 6.25), Vector3(1.1, .025, .42), metal)
		for slot in range(7):
			_box("DrainSlot", Vector3(x - .45 + slot * .15, .078, 6.25), Vector3(.045, .008, .36), asphalt)
	for slat in range(4):
		_box("BenchSlat", Vector3(-7.7, .51, .68 + slat * .13), Vector3(2.0, .07, .11), stone)
	for x in [-8.4, -7.0]:
		_box("BenchLeg", Vector3(x, .25, .86), Vector3(.09, .5, .5), metal)
	_box("BenchBack", Vector3(-7.7, .9, .52), Vector3(2.0, .52, .075), stone)


func tick(time: float) -> void:
	door_open = smoothstep(.2, 1.4, time) * (1.0 - smoothstep(5.0, 6.4, time))
	for index in range(door_panels.size()):
		var side: float = -1.0 if index == 0 else 1.0
		door_panels[index].position.x = EXIT_X + side * (.8 + door_open * 1.65)
	for walker: Dictionary in walkers:
		var body: Node3D = walker.body
		body.position = (walker.from as Vector3).lerp(walker.to, clampf(time / SECONDS, 0, 1))
	# Absolute cinematic time drives both travel and skeletal motion, even during slow motion.
	for entry: Dictionary in animations:
		var animator: AnimationPlayer = entry.animator
		var length: float = maxf(animator.current_animation_length, .001)
		animator.seek(fposmod(time * float(entry.rate) + float(entry.phase), length), true)
		animator.advance(0.0)
	club_light.light_energy = .65 + sin(time * 1.3) * .035


## Wait for the panels, emerge and round the corner without stopping or snapping.
func travel(time: float) -> Vector4:
	var radius: float = .9
	var arc: float = radius * PI * .5
	var length: float = 2.3 + arc + 6.4
	var distance: float = _distance(time - 1.5, 10.5, length)
	var point: Vector3 = Vector3(EXIT_X, .05, .7)
	if distance < 2.3:
		point.z += distance
	elif distance < 2.3 + arc:
		var angle: float = (distance - 2.3) / radius
		point.x -= radius * (1.0 - cos(angle))
		point.z = 3.0 + radius * sin(angle)
	else:
		point.x -= radius + distance - 2.3 - arc
		point.z = 3.9
	var at: Vector3 = to_global(point)
	return Vector4(at.x, at.y, at.z, _speed(time - 1.5, 10.5, length))


func facing(time: float) -> float:
	var distance: float = _distance(time - 1.5, 10.5, 2.3 + .9 * PI * .5 + 6.4)
	return PI * .5 - clampf((distance - 2.3) / .9, 0.0, PI * .5)


func _distance(time: float, seconds: float, length: float) -> float:
	var t: float = clampf(time, 0, seconds)
	var ramp: float = .4
	var area: float
	if t < ramp:
		area = t * t * t / (ramp * ramp) - .5 * pow(t, 4) / pow(ramp, 3)
	elif t > seconds - ramp:
		var left: float = seconds - t
		area = seconds - ramp - (pow(left, 3) / pow(ramp, 2) - .5 * pow(left, 4) / pow(ramp, 3))
	else:
		area = t - ramp * .5
	return length * area / (seconds - ramp)


func _speed(time: float, seconds: float, length: float) -> float:
	return length / (seconds - .4) * smoothstep(0, .4, time) * (1.0 - smoothstep(seconds - .4, seconds, time))


func _material(color: Color, roughness: float, glow: float = 0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if glow > 0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material


func _box(label: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = label
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	add_child(instance)
	return instance


func _text(label: String, words: String, at: Vector3, pixels: float, color: Color) -> void:
	var text: Label3D = Label3D.new()
	text.name = label
	text.text = words
	text.font = FONT
	text.font_size = 64
	text.pixel_size = pixels
	text.outline_size = 0
	text.modulate = color
	text.no_depth_test = false
	text.position = at
	add_child(text)


func _light(at: Vector3, color: Color, energy: float, reach: float) -> OmniLight3D:
	var lamp: OmniLight3D = OmniLight3D.new()
	lamp.position = at
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = reach
	add_child(lamp)
	return lamp


func _person(label: String, model: String, at: Vector3, facing: float, clip: String, shirt: Color) -> Node3D:
	var body: Node3D = load("res://assets/characters/quaternius/" + model).instantiate()
	body.name = label
	body.position = at
	body.rotation.y = facing
	body.scale = Vector3.ONE * .62
	add_child(body)
	CREW.dress(body, [shirt, Color(.065, .07, .1), Color(.68, .46, .34), Color(.08, .045, .03)])
	var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
	animator.add_animation_library("ual", MOTION)
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animator.play(clip)
	animator.advance(0.0)
	animations.append({"animator": animator, "rate": 1.0, "phase": float(patrons.size()) * .23})
	patrons.append(body)
	return body


func _walker(label: String, model: String, from: Vector3, to: Vector3, shirt: Color) -> void:
	# Raw imported people face +Z, unlike the wrapped playable engineer.
	var body: Node3D = _person(label, model, from, atan2(to.x - from.x, to.z - from.z), "CharacterArmature|Walk", shirt)
	var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
	# Match skeletal stride rate to the actual distance travelled per cinematic second.
	animations.back().rate = from.distance_to(to) / SECONDS / 1.6
	animator.speed_scale = 1.0
	walkers.append({"body": body, "from": from, "to": to})
