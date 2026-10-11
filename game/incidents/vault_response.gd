extends Node3D
## The crew's doomed fire response. Local staging, no damage or navigation changes.
## Equipment and five casualty pools remain until the incident resets.
const FIRE_SITES: Array[Vector3] = [Vector3(3.1, .15, -40), Vector3(14.6, .15, -40.6), Vector3(9, .15, -44)]
const FONT: Font = preload("res://assets/fonts/barlow_condensed_semibold.ttf")
var crew: Node
var clock: float = 0.0
var intensity: float = 1.0
var responding: bool = false
var settled: bool = false
var fires: Array[Node3D] = []
var smoke: Array[CPUParticles3D] = []
var lamps: Array[OmniLight3D] = []
var equipment: Dictionary = {}
var hose: Array[MeshInstance3D] = []
var water: Array[MeshInstance3D] = []
var casts: Dictionary = {}
var pools: Array[Decal] = []
var grip_iks: Array[TwoBoneIK3D] = []
var grip_targets: Array[Node3D] = []
var grip_poles: Array[Node3D] = []


func _init(team: Node) -> void:
	crew = team
	name = "VaultResponse"


func _ready() -> void:
	var steel: StandardMaterial3D = _material(Color(.15, .18, .19), .45)
	var red: StandardMaterial3D = _material(Color(.5, .045, .02), .3)
	for at: Vector3 in FIRE_SITES:
		var fire: Node3D = _flame(at)
		fires.append(fire)
		smoke.append(_smoke(at + Vector3.UP))
		var lamp: OmniLight3D = OmniLight3D.new()
		lamp.position = at + Vector3.UP * 1.3
		lamp.light_color = Color(1, .32, .055)
		lamp.light_energy = 3.0
		lamp.omni_range = 5.0
		add_child(lamp)
		lamps.append(lamp)
		_box(self, at + Vector3(0, .04, 0), Vector3(1.4, .08, 1.2), steel)
		var casing: MeshInstance3D = _box(self, at + Vector3(0, .32, 0), Vector3(.65, .55, .8), steel)
		casing.rotation.z = .18
		for vent in range(4):
			_box(self, at + Vector3(-.12 + vent * .09, .59, .05), Vector3(.025, .018, .48), red)
	var reel: MeshInstance3D = _cylinder(self, Vector3(16.2, .9, -33), .36, .24, red)
	reel.rotation.x = PI * .5
	for index in range(48):
		hose.append(_cylinder(self, Vector3.ZERO, .045, 1.0, _material(Color(.55, .41, .19), .8)))
	var spray: StandardMaterial3D = _material(Color(.7, .87, .94, .65), .1)
	spray.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spray.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for index in range(40):
		water.append(_cylinder(self, Vector3.ZERO, .022, 1.0, spray))
	for entry: Array in crew.CAVALRY:
		var tool: Node3D = Node3D.new()
		tool.name = entry[0] + "Equipment"
		add_child(tool)
		match entry[0]:
			"Manager":
				_cylinder(tool, Vector3(0, -.18, 0), .13, .45, red)
				_box(tool, Vector3(0, .08, 0), Vector3(.2, .035, .08), steel)
				_label(tool, "HOTFIX", Vector3(0, -.13, .135), .0025)
			"SRE":
				var nozzle: MeshInstance3D = _cylinder(tool, Vector3(0, 0, -.2), .055, .5, steel)
				nozzle.rotation.x = PI * .5
				_box(tool, Vector3(0, -.08, -.08), Vector3(.05, .18, .06), red)
			"Designer":
				_box(tool, Vector3(0, -.1, 0), Vector3(.45, .3, .07), steel)
				_label(tool, "FAN THE METRICS", Vector3(0, -.08, .04), .0013)
			"Intern":
				_cylinder(tool, Vector3(0, -.2, 0), .2, .32, steel)
				_label(tool, "CLOUD BACKUP", Vector3(0, -.16, .2), .0017)
			"Director":
				_box(tool, Vector3(0, -.08, 0), Vector3(.27, .34, .035), _material(Color(.72, .68, .5), .9))
				_label(tool, "ACCEPTED\nRISK", Vector3(0, -.08, .022), .002)
		equipment[entry[0]] = {"tool": tool, "dropped": false}
	_setup_hose_grip()


func _process(delta: float) -> void:
	clock += delta
	for index in range(fires.size()):
		fires[index].visible = not settled
		fires[index].scale = Vector3.ONE * intensity
		lamps[index].light_energy = 2.8 * intensity * (1.0 + .1 * sin(clock * 9.0 + index)) if not settled else .15
		smoke[index].emitting = not settled
	for who: String in equipment:
		var item: Dictionary = equipment[who]
		if item.dropped:
			continue
		var person: Dictionary = crew.person(who)
		var body: Node3D = person.body
		var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
		var hand: int = skeleton.find_bone("Fist.R")
		item.tool.global_position = skeleton.global_transform * skeleton.get_bone_global_pose(hand).origin
		item.tool.global_rotation = Vector3(0, body.global_rotation.y + PI, 0)
	var sre: Dictionary = crew.person("SRE")
	var nozzle: Node3D = equipment.SRE.tool
	var spraying: bool = responding and sre.charging and sre.body.position.distance_to(crew.STAGE.SRE.spot) < .4 and sre.wind < 0.0
	var forward: Vector3 = sre.body.global_basis.z.normalized()
	var right: Vector3 = -sre.body.global_basis.x.normalized()
	if spraying:
		nozzle.global_position = sre.body.global_position + Vector3.UP * .9 + forward * .44 + right * .12
		nozzle.look_at(FIRE_SITES[1] + Vector3.UP * .6)
	for index in range(grip_iks.size()):
		grip_iks[index].influence = move_toward(grip_iks[index].influence, 1.0 if spraying else 0.0, delta * 6.0)
		grip_targets[index].global_position = nozzle.to_global(Vector3(0, -.04, -.26 if index == 1 else 0))
		grip_poles[index].global_position = sre.body.global_position + Vector3.UP * .55 + right * (.8 if index == 0 else -.8)
	var origin: Vector3 = Vector3(16.2, .9, -33)
	var tip: Vector3 = nozzle.to_global(Vector3(0, 0, .08))
	var bend: Vector3 = tip + right * .5
	bend.y = .07
	for index in range(hose.size()):
		var a: float = float(index) / hose.size()
		var b: float = float(index + 1) / hose.size()
		_segment(hose[index], _hose_point(origin, bend, tip, a), _hose_point(origin, bend, tip, b))
	var muzzle: Vector3 = nozzle.to_global(Vector3(0, 0, -.45))
	for index in range(water.size()):
		water[index].visible = spraying
		if spraying:
			var a: float = float(index) / water.size()
			var b: float = float(index + 1) / water.size()
			_segment(water[index], _water_point(muzzle, FIRE_SITES[1] + Vector3.UP * .6, a), _water_point(muzzle, FIRE_SITES[1] + Vector3.UP * .6, b))


func _hose_point(origin: Vector3, bend: Vector3, tip: Vector3, t: float) -> Vector3:
	var floor_start: Vector3 = Vector3(origin.x, .07, origin.z - .3)
	if t < .12:
		return origin.bezier_interpolate(origin + Vector3.DOWN * .4, floor_start + Vector3.BACK * .2, floor_start, t / .12)
	if t < .78:
		return floor_start.bezier_interpolate(floor_start + Vector3(-.9, 0, -1.2), bend + Vector3(1.0, 0, .6), bend, (t - .12) / .66)
	return bend.bezier_interpolate(bend + Vector3.UP * .4, tip + (bend - tip) * .45 + Vector3.UP * .3, tip, (t - .78) / .22)


func _water_point(origin: Vector3, target: Vector3, t: float) -> Vector3:
	return origin.lerp(target, t) + Vector3(sin(t * 20.0 + clock * 12.0) * .025, sin(t * PI) * .45, 0)


## Persistent authored pool; ordinary combat's ten-second splats remain unchanged.
func casualty(someone: Dictionary) -> void:
	var who: String = someone.entry.name
	var item: Dictionary = equipment[who]
	if item.dropped:
		return
	item.dropped = true
	if who == "SRE":
		for ik: TwoBoneIK3D in grip_iks:
			ik.active = false
			ik.influence = 0.0
	var tool: Node3D = item.tool
	tool.global_position = someone.body.global_position + Vector3(.5, .16, .35)
	tool.rotation = Vector3(PI * .5, float(someone.slot) * .8, 0)
	if casts.has(who):
		casts[who].hide()
	Blood.prewarm()
	var pool: Decal = Decal.new()
	pool.name = who + "RemainsPool"
	pool.texture_albedo = Blood.splat_textures[someone.slot % Blood.splat_textures.size()]
	pool.texture_orm = Blood.wet_texture
	pool.modulate = Color(.38, .008, .018, .96)
	pool.size = Vector3(2.3, .6, 2.1)
	pool.cull_mask = 1
	add_child(pool)
	pool.global_position = Vector3(someone.body.global_position.x, .035, someone.body.global_position.z)
	pool.rotation.y = someone.slot * 1.2
	pools.append(pool)


## The boss's five spells have a readable source, wind-up silhouette and contact point.
func cast(someone: Dictionary, progress: float) -> void:
	var who: String = someone.entry.name
	var effect: Node3D
	if not casts.has(who):
		effect = Node3D.new()
		effect.name = who + "CorrectiveAction"
		add_child(effect)
		casts[who] = effect
		if someone.fate == "pop":
			var toward_camera: Vector3 = crew.stage_camera() - someone.body.global_position
			effect.rotation.y = atan2(toward_camera.x, toward_camera.z)
		ElementFx.bolt(crew, crew.cavalry_target.global_position + Vector3.UP * 2.6, someone.body.global_position + Vector3.UP * .9, Color(.7, .15, .035), .45, .05)
		var crimson: ShaderMaterial = ShaderMaterial.new()
		crimson.shader = preload("res://game/incidents/vault_spell.gdshader")
		for index in range(4 if someone.fate == "pop" else 3):
			var blade: MeshInstance3D = MeshInstance3D.new()
			blade.mesh = _crop_blade() if someone.fate == "pop" else _crescent()
			blade.material_override = crimson
			blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			effect.add_child(blade)
	else:
		effect = casts[who]
	effect.global_position = someone.body.global_position
	var children: Array[Node] = effect.get_children()
	for index in range(children.size()):
		var blade: MeshInstance3D = children[index]
		match someone.fate:
			"delayer":
				blade.position = Vector3(0, lerpf(3.2 + index * .4, .1 + index * .03, smoothstep(0.0, 1.0, progress)), 0)
				blade.rotation.y = progress * .4
			"decommission":
				blade.position.y = .45 + index * .45
				blade.scale = Vector3.ONE * lerpf(.45, 1.0, smoothstep(0, 1, progress))
				blade.rotation.y = progress * TAU
			"pop":
				var close: float = smoothstep(.45, 1.0, progress)
				var angle: float = index * PI * .5
				blade.position = Vector3(cos(angle), sin(angle), 0) * lerpf(1.65, .05, close) + Vector3.UP * .95
				blade.rotation = Vector3(0, 0, angle + PI * .5)
				blade.scale = Vector3.ONE
			"expose":
				blade.position = Vector3((index - 1) * .7, 2.7 - progress, 0)
				blade.rotation.z = PI * .5
				blade.scale = Vector3(1.6, 1, .6)
			"downsize":
				blade.position = Vector3((index - 1) * (1.3 - progress), .65, 0)
				blade.rotation.z = PI * .5
				blade.scale = Vector3(.7, 1, .7)


func extinguish() -> void:
	settled = true
	responding = false


func _smoke(at: Vector3) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.name = "Smoke"
	particles.amount = 7
	particles.lifetime = 2.6
	particles.preprocess = particles.lifetime
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = .45
	particles.direction = Vector3.UP
	particles.spread = 16
	particles.gravity = Vector3(0, .3, 0)
	particles.initial_velocity_min = .6
	particles.initial_velocity_max = .8
	particles.scale_amount_min = .4
	particles.scale_amount_max = 1.2
	particles.position = at
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(1.4, 1.4)
	var material: StandardMaterial3D = _material(Color.WHITE, 1)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = preload("res://assets/effects/kenney_smoke/smoke_puff.png")
	mesh.material = material
	particles.mesh = mesh
	var colors: Gradient = Gradient.new()
	colors.set_color(0, Color(.16, .15, .14, 0))
	colors.add_point(.35, Color(.14, .13, .13, .16))
	colors.set_color(2, Color(.12, .12, .13, 0))
	particles.color_ramp = colors
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	return particles


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _box(parent: Node, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.material_override = material
	part.position = at
	parent.add_child(part)
	return part


func _cylinder(parent: Node, at: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	part.mesh = mesh
	part.material_override = material
	part.position = at
	parent.add_child(part)
	return part


func _segment(mesh: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var step: Vector3 = end - start
	mesh.position = (start + end) * .5
	mesh.quaternion = Quaternion(Vector3.UP, step.normalized())
	mesh.scale.y = maxf(.001, step.length())


func _label(parent: Node, words: String, at: Vector3, pixels: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = words
	label.font = FONT
	label.font_size = 32
	label.pixel_size = pixels
	label.position = at
	label.outline_size = 0
	parent.add_child(label)


func _flame(at: Vector3) -> Node3D:
	var root: Node3D = Node3D.new()
	root.position = at
	add_child(root)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://game/incidents/vault_flame.gdshader")
	for index in range(3):
		var sheet: MeshInstance3D = MeshInstance3D.new()
		var mesh: QuadMesh = QuadMesh.new()
		mesh.size = Vector2(1.9, 2.5 - index * .25)
		sheet.mesh = mesh
		sheet.material_override = material
		sheet.position.y = mesh.size.y * .5
		sheet.rotation.y = index * PI / 3.0
		sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(sheet)
	return root


func _crescent() -> ArrayMesh:
	var vertices: PackedVector3Array = []
	var uvs: PackedVector2Array = []
	var indices: PackedInt32Array = []
	for index in range(49):
		var t: float = float(index) / 48.0
		var angle: float = t * TAU * .88
		var width: float = .24 * sin(t * PI)
		for side in range(2):
			var radius: float = 1.2 + width * (1 if side == 0 else -1)
			vertices.append(Vector3(cos(angle), 0, sin(angle)) * radius)
			uvs.append(Vector2(t, side))
		if index < 48:
			var a: int = index * 2
			indices.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _setup_hose_grip() -> void:
	var skeleton: Skeleton3D = crew.person("SRE").body.find_child("Skeleton3D", true, false)
	for side: String in ["R", "L"]:
		var target: Node3D = Node3D.new()
		var pole: Node3D = Node3D.new()
		add_child(target)
		add_child(pole)
		var ik: TwoBoneIK3D = TwoBoneIK3D.new()
		ik.setting_count = 1
		skeleton.add_child(ik)
		ik.set_root_bone_name(0, "UpperArm." + side)
		ik.set_middle_bone_name(0, "LowerArm." + side)
		ik.set_end_bone_name(0, "Fist." + side)
		ik.set_target_node(0, ik.get_path_to(target))
		ik.set_pole_node(0, ik.get_path_to(pole))
		ik.influence = 0.0
		grip_iks.append(ik)
		grip_targets.append(target)
		grip_poles.append(pole)


func _exit_tree() -> void:
	for ik: TwoBoneIK3D in grip_iks:
		if is_instance_valid(ik):
			ik.queue_free()


func _crop_blade() -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-1.8, -.1, 0), Vector3(1.8, -.1, 0), Vector3(-1.8, .1, 0), Vector3(1.8, .1, 0)])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 2, 1, 3])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
