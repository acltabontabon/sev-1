extends Node3D
## A small, staged midnight frontage. Owned and removed by the ending, no gameplay AI.
const MOTION: AnimationLibrary = preload("res://game/player/engineer_animations.res")
const CREW: Script = preload("res://game/incidents/coworkers.gd")
const FONT: Font = preload("res://assets/fonts/barlow_condensed_semibold.ttf")
const PINK: Color = Color(1.0, .08, .4)
const CYAN: Color = Color(.08, .8, 1.0)
var walkers: Array[Dictionary] = []
var patrons: Array[Node3D] = []
var club_light: OmniLight3D
var pink: StandardMaterial3D


func _ready() -> void:
	name = "NightlifeStreet"
	position = Vector3(-14.5, -70, 0)
	rotation.y = -PI / 2.0
	var stone: StandardMaterial3D = _material(Color(.09, .1, .12), .55)
	var metal: StandardMaterial3D = _material(Color(.025, .025, .035), .35)
	var glass: StandardMaterial3D = _material(Color(.06, .09, .13), .12)
	glass.metallic = .65
	pink = _material(PINK, .3, 2.2)
	var cyan: StandardMaterial3D = _material(CYAN, .3, 2.0)
	var amber: StandardMaterial3D = _material(Color(1, .55, .12), .4, 1.4)
	# Ground-level shopfronts conceal only the bottom of the existing curtain wall.
	_box("ClubFacade", Vector3(1.5, 2.25, 0), Vector3(7, 4.5, .3), metal)
	_box("ClubCanopy", Vector3(1.5, 3.6, .9), Vector3(7.3, .25, 1.9), metal)
	_box("CanopyNeon", Vector3(1.5, 3.49, 1.83), Vector3(7.1, .045, .045), pink)
	_box("ClubSign", Vector3(1.5, 2.95, .22), Vector3(6.4, .9, .15), stone)
	_text("ClubName", "VELVET", Vector3(1.5, 3.08, .32), .010, PINK)
	_text("ClubType", "STRIP CLUB  /  OPEN LATE", Vector3(1.5, 2.66, .32), .0034, Color(1, .65, .8))
	_box("ClubDoor", Vector3(1.3, 1.24, .22), Vector3(1.45, 2.48, .12), glass)
	for side in [-1.0, 1.0]:
		_box("DoorNeon", Vector3(1.3 + side * .79, 1.26, .32), Vector3(.035, 2.52, .04), pink)
		_box("Window", Vector3(1.5 + side * 2.35, 1.25, .22), Vector3(1.7, 2.15, .08), glass)
		for slat in range(9):
			_box("Louvre", Vector3(1.5 + side * 2.35, .3 + slat * .23, .3), Vector3(1.74, .065, .1), metal)
	_box("DoorHandle", Vector3(1.79, 1.1, .32), Vector3(.035, .45, .04), amber)
	_text("EntryNotice", "21+", Vector3(1.3, 1.55, .31), .004, Color(1, .75, .8))
	# A warm food counter and cyan bar make a district, rather than one isolated sign.
	_box("FoodFacade", Vector3(-4.8, 1.95, 0), Vector3(4.8, 3.9, .3), stone)
	_box("FoodWindow", Vector3(-4.8, 1.7, .2), Vector3(3.9, 1.6, .08), amber)
	_box("FoodCounter", Vector3(-4.8, .94, .7), Vector3(4.2, .17, 1.25), metal)
	_box("FoodAwning", Vector3(-4.8, 2.6, .85), Vector3(4.8, .17, 1.8), metal)
	_text("FoodSign", "MIDNIGHT NOODLES", Vector3(-4.8, 3.08, .23), .0048, Color(1, .7, .28))
	_text("Menu", "HOT BOWLS  /  COLD DRINKS", Vector3(-4.8, 1.93, .27), .0028, Color(.16, .08, .04))
	_box("BarFacade", Vector3(10.25, 2.0, 0), Vector3(5.5, 4, .3), stone)
	_box("BarGlass", Vector3(10.25, 1.3, .22), Vector3(4.6, 2.3, .12), glass)
	_text("BarSign", "BLUE HOUR", Vector3(10.25, 2.96, .3), .008, CYAN)
	_text("BarCaption", "COCKTAILS  /  LIVE SET", Vector3(10.25, 2.45, .3), .003, Color(.5, .8, 1))
	_box("BarNeon", Vector3(10.25, 3.5, .28), Vector3(4.7, .045, .045), cyan)
	# An unmistakable office exit keeps his departure distinct from the club entrance.
	_box("OfficeEntrance", Vector3(6.2, 1.8, 0), Vector3(2.2, 3.6, .3), metal)
	_box("OfficeDoor", Vector3(6.2, 1.35, .2), Vector3(1.65, 2.7, .09), glass)
	_box("OfficeDoorRail", Vector3(6.2, 1.0, .3), Vector3(1.65, .055, .07), stone)
	_text("OfficeExitSign", "SYNERGEX / EXIT", Vector3(6.2, 3.08, .26), .003, Color(.75, .86, 1))
	# Pavement, kerb and wet asphalt; the engineer's route is outside the patrons.
	_box("Sidewalk", Vector3(0, -.015, 2.3), Vector3(27, .07, 4.6), stone)
	var asphalt: StandardMaterial3D = _material(Color(.022, .028, .04), .16)
	_box("WetRoad", Vector3(0, -.025, 9), Vector3(42, .06, 9), asphalt)
	_box("Kerb", Vector3(0, .015, 4.58), Vector3(27, .14, .16), stone)
	for index in range(12):
		_box("PavingJoint", Vector3(-13 + index * 2.3, .024, 2.3), Vector3(.022, .008, 4.4), metal)
	for index in range(5):
		_box("LaneDash", Vector3(-16 + index * 7, .012, 9.5), Vector3(3.0, .008, .12), _material(Color(.45, .43, .3), .3))
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
		reflection.position = Vector3(1.5 if index == 0 else 10.25, .013, 6.8)
		reflection.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(reflection)
	club_light = _light(Vector3(1.5, 2.6, 1.9), PINK, 2.5, 7.5)
	_light(Vector3(10.2, 2.3, 1.5), CYAN, 2.1, 7)
	_light(Vector3(-4.8, 2.2, 1.4), Color(1, .62, .28), 2.0, 6)
	# Rope line, door host, two conversations and people taking the late train home.
	for index in range(3):
		_box("QueuePost", Vector3(2.8 + index * .9, .5, 2.2), Vector3(.07, 1, .07), metal)
		if index < 2:
			_box("VelvetRope", Vector3(3.25 + index * .9, .85, 2.2), Vector3(.9, .055, .055), _material(Color(.32, .02, .05), .8))
	_person("DoorHost", "suit_male.fbx", Vector3(.1, 0, 1.4), .2, "ual/idle", Color(.045, .045, .065))
	_person("PatronA", "casual_female.fbx", Vector3(3.3, 0, 1.2), -1.0, "ual/talking", Color(.55, .035, .15))
	_person("PatronB", "casual2_male.fbx", Vector3(4.1, 0, 1.45), 1.7, "ual/phone", Color(.17, .28, .4))
	_person("BarPatronA", "casual2_female.fbx", Vector3(9.6, 0, 1.1), -1.1, "ual/talking", Color(.16, .35, .4))
	_person("BarPatronB", "casual_male.fbx", Vector3(10.6, 0, 1.5), 1.2, "ual/yes", Color(.32, .15, .3))
	_person("FoodCustomer", "casual3_male.fbx", Vector3(-4.7, 0, 1.7), PI, "ual/phone", Color(.45, .27, .12))
	_walker("PedestrianA", "casual_male.fbx", Vector3(-7.5, 0, 3.4), Vector3(-2.5, 0, 3.4), Color(.3, .42, .5))
	_walker("PedestrianB", "casual2_female.fbx", Vector3(13, 0, 3.65), Vector3(9, 0, 3.65), Color(.6, .22, .4))
	_walker("PedestrianC", "casual2_male.fbx", Vector3(-.8, 0, 3.15), Vector3(-5.7, 0, 3.15), Color(.3, .3, .18))


func tick(time: float) -> void:
	# Real cinematic time, independent of combat slow motion and global animation speed.
	for walker: Dictionary in walkers:
		var body: Node3D = walker.body
		body.position = (walker.from as Vector3).lerp(walker.to, clampf(time / 7.5, 0, 1))
	club_light.light_energy = 2.5 + sin(time * 2.2) * .12


func _material(color: Color, roughness: float, glow: float = 0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if glow > 0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material


func _box(label: String, at: Vector3, size: Vector3, material: Material) -> void:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = label
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	add_child(instance)


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
	animator.play(clip)
	patrons.append(body)
	return body


func _walker(label: String, model: String, from: Vector3, to: Vector3, shirt: Color) -> void:
	var body: Node3D = _person(label, model, from, atan2(from.x - to.x, from.z - to.z), "CharacterArmature|Walk", shirt)
	var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
	# Match 0.65 m/s to the same walk cycle used by the cinematic engineer.
	animator.speed_scale = .6
	walkers.append({"body": body, "from": from, "to": to})
