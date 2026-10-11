extends RefCounted
## Original haircuts for the Quaternius office bodies, so the night shift is not a dozen
## people sharing three haircuts. `coworkers.gd dress()` strips a body's stock Hair surface
## and fits one of these to the animated Head bone. Everything is built here, in the
## head's own frame and the body's own units: +Y up, +Z toward the face, measured out from
## SCALP. Each style is built once and shared.

const SCALP: Vector3 = Vector3(0, .47, -.01)
const RADIUS: float = .49
## The pack's boxy head, which every body shares: how far its skin lies from SCALP every
## 15 degrees round from the face (columns) and 10 degrees down from the crown (rows).
## Baked by tools/measure_scalp.gd.
const SCALP_RADII: PackedFloat32Array = [
	0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489, 0.489,
	0.490, 0.487, 0.485, 0.485, 0.485, 0.487, 0.486, 0.484, 0.482, 0.481, 0.482, 0.484, 0.486, 0.485, 0.483, 0.482, 0.483, 0.484, 0.487, 0.488, 0.486, 0.485, 0.486, 0.488,
	0.502, 0.497, 0.493, 0.492, 0.494, 0.497, 0.499, 0.494, 0.490, 0.489, 0.490, 0.494, 0.499, 0.494, 0.491, 0.489, 0.490, 0.494, 0.499, 0.498, 0.494, 0.492, 0.494, 0.498,
	0.529, 0.523, 0.518, 0.515, 0.518, 0.519, 0.521, 0.516, 0.514, 0.512, 0.514, 0.512, 0.516, 0.512, 0.515, 0.512, 0.515, 0.518, 0.522, 0.521, 0.518, 0.516, 0.518, 0.524,
	0.539, 0.531, 0.537, 0.550, 0.532, 0.527, 0.530, 0.522, 0.528, 0.537, 0.524, 0.518, 0.526, 0.519, 0.524, 0.539, 0.530, 0.523, 0.531, 0.527, 0.533, 0.551, 0.538, 0.532,
	0.566, 0.556, 0.563, 0.551, 0.558, 0.552, 0.558, 0.548, 0.554, 0.538, 0.549, 0.543, 0.547, 0.543, 0.549, 0.540, 0.554, 0.548, 0.558, 0.552, 0.558, 0.552, 0.563, 0.557,
	0.544, 0.546, 0.568, 0.570, 0.565, 0.535, 0.530, 0.532, 0.551, 0.557, 0.546, 0.520, 0.518, 0.520, 0.547, 0.558, 0.551, 0.531, 0.529, 0.534, 0.564, 0.571, 0.570, 0.546,
	0.532, 0.534, 0.551, 0.569, 0.548, 0.524, 0.519, 0.521, 0.535, 0.552, 0.529, 0.509, 0.507, 0.509, 0.530, 0.552, 0.534, 0.520, 0.517, 0.523, 0.547, 0.569, 0.552, 0.535,
	0.512, 0.518, 0.542, 0.567, 0.537, 0.507, 0.499, 0.505, 0.525, 0.548, 0.518, 0.492, 0.486, 0.492, 0.519, 0.548, 0.524, 0.503, 0.497, 0.506, 0.536, 0.567, 0.543, 0.519,
	0.505, 0.511, 0.534, 0.558, 0.528, 0.499, 0.491, 0.497, 0.517, 0.540, 0.510, 0.484, 0.478, 0.484, 0.511, 0.540, 0.516, 0.496, 0.490, 0.498, 0.527, 0.558, 0.535, 0.511,
	0.512, 0.518, 0.542, 0.567, 0.536, 0.507, 0.498, 0.504, 0.525, 0.548, 0.518, 0.492, 0.486, 0.492, 0.519, 0.548, 0.524, 0.503, 0.497, 0.505, 0.535, 0.566, 0.543, 0.519,
	0.537, 0.543, 0.567, 0.589, 0.560, 0.531, 0.522, 0.528, 0.547, 0.567, 0.540, 0.515, 0.509, 0.516, 0.541, 0.566, 0.546, 0.527, 0.521, 0.529, 0.559, 0.589, 0.568, 0.544,
	0.583, 0.589, 0.606, 0.610, 0.587, 0.557, 0.549, 0.553, 0.568, 0.570, 0.553, 0.530, 0.527, 0.530, 0.555, 0.570, 0.567, 0.552, 0.548, 0.556, 0.586, 0.610, 0.607, 0.590,
	0.659, 0.653, 0.642, 0.624, 0.607, 0.578, 0.573, 0.570, 0.564, 0.553, 0.540, 0.526, 0.529, 0.526, 0.540, 0.553, 0.564, 0.569, 0.572, 0.577, 0.606, 0.623, 0.642, 0.653,
	0.680, 0.660, 0.639, 0.626, 0.607, 0.594, 0.588, 0.577, 0.557, 0.541, 0.530, 0.522, 0.526, 0.522, 0.530, 0.541, 0.557, 0.577, 0.587, 0.593, 0.607, 0.626, 0.640, 0.660,
	0.634, 0.623, 0.623, 0.608, 0.597, 0.600, 0.593, 0.576, 0.554, 0.536, 0.525, 0.518, 0.521, 0.518, 0.525, 0.537, 0.555, 0.576, 0.593, 0.600, 0.597, 0.609, 0.624, 0.624,
	0.599, 0.593, 0.588, 0.588, 0.587, 0.585, 0.574, 0.564, 0.558, 0.541, 0.528, 0.525, 0.527, 0.525, 0.528, 0.541, 0.558, 0.564, 0.575, 0.586, 0.588, 0.588, 0.588, 0.594,
	0.573, 0.570, 0.569, 0.569, 0.570, 0.565, 0.559, 0.553, 0.548, 0.545, 0.543, 0.543, 0.543, 0.543, 0.543, 0.545, 0.549, 0.553, 0.559, 0.565, 0.570, 0.569, 0.569, 0.570,
	0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555, 0.555,
]
## Every style a body can be given. "" keeps the stock hair.
const STYLES: Array[String] = ["side_part", "pompadour", "bedhead", "curly", "man_bun", "mohawk",
	"shoulder", "chignon", "mullet", "undercut", "buzz_beard", "high_ponytail", "slick_back", "spiky",
	"bob", "top_knot", "receding", "braid", "afro"]
## Strangers who are not in the cast draw from these.
const POOL: Array[String] = ["slick_back", "bob", "curly", "high_ponytail", "side_part", "afro",
	"buzz_beard", "shoulder", "top_knot", "spiky"]
## Second surface: dark hair ties, or the undercut's natural shaved sides under a dyed top.
const TIE: Color = Color(.07, .07, .08)
const ROOTS: Color = Color(.1, .075, .06)

static var built: Dictionary = {}
static var bald: Dictionary = {}


## A stranger's haircut, stable for their name.
static func pick(who: String) -> String:
	return POOL[absi(hash(who)) % POOL.size()]


## The body's mesh without its stock Hair surface (shared per source mesh).
static func without_hair(mesh: Mesh) -> Mesh:
	if bald.has(mesh):
		return bald[mesh]
	var hair: int = -1
	for surface in mesh.get_surface_count():
		var material: Material = mesh.surface_get_material(surface)
		if material != null and material.resource_name == "Hair":
			hair = surface
	if hair < 0:
		bald[mesh] = mesh
		return mesh
	var result: ArrayMesh = ArrayMesh.new()
	for surface in mesh.get_surface_count():
		if surface == hair:
			continue
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var flags: int = Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if bones.size() == vertices.size() * 8 else 0
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
		result.surface_set_material(result.get_surface_count() - 1, mesh.surface_get_material(surface))
	bald[mesh] = result
	return result


## Attach `style` to the body's head in `color`. `stock` is the body's own hair material,
## so the new cut is lit like the rest of the pack.
static func fit(body: Node3D, style: String, color: Color, stock: Material = null) -> MeshInstance3D:
	var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
	var head: BoneAttachment3D = BoneAttachment3D.new()
	head.name = "Hairstyle"
	head.bone_name = "Head"
	skeleton.add_child(head)
	# The armature is scaled up from the body; undo it so the cut is in body units.
	var unit: float = 1.0
	var node: Node = skeleton
	while node != body and node is Node3D:
		unit *= (node as Node3D).transform.basis.get_scale().x
		node = node.get_parent()
	var holder: Node3D = Node3D.new()
	holder.scale = Vector3.ONE / unit
	head.add_child(holder)
	var hair: MeshInstance3D = MeshInstance3D.new()
	hair.name = "Hair"
	hair.mesh = mesh(style)
	holder.add_child(hair)
	hair.set_surface_override_material(0, _material(color, stock))
	if hair.mesh.get_surface_count() > 1:
		var second: Color = ROOTS if style == "undercut" else TIE
		hair.set_surface_override_material(1, _material(second, stock))
	return hair


static func _material(color: Color, stock: Material) -> StandardMaterial3D:
	var material: StandardMaterial3D = (stock as StandardMaterial3D).duplicate() if stock is StandardMaterial3D else StandardMaterial3D.new()
	material.resource_name = "Hair"
	material.albedo_color = color
	material.roughness = .58
	material.metallic_specular = .32
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func mesh(style: String) -> ArrayMesh:
	if built.has(style):
		return built[style]
	var hair: SurfaceTool = SurfaceTool.new()
	hair.begin(Mesh.PRIMITIVE_TRIANGLES)
	var accent: SurfaceTool = SurfaceTool.new()
	accent.begin(Mesh.PRIMITIVE_TRIANGLES)
	var accented: bool = true
	match style:
		"side_part":
			# A sculpted swept pixie: a clean temple and a long diagonal fringe.
			_cap(hair, {"line": [57, 91, 136], "lift": .065, "crown": .06})
			for index in range(6):
				var t: float = index / 5.0
				_lock(hair, Vector3(-.37 + t * .09, .82, -.24 + t * .42),
					Vector3(-.3, 1.18, -.12 + t * .52), Vector3(.26, 1.18 - t * .12, .16 + t * .4),
					Vector3(.43, .64 + t * .06, .26 + t * .19), .105, .052)
			accented = false
		"pompadour":
			_cap(hair, {"line": [56, 92, 138], "lift": .075, "crown": .085, "brow": .085})
			for index in range(7):
				var t: float = index / 6.0
				_lock(hair, Vector3(-.35, .85, -.28 + t * .52),
					Vector3(-.32, 1.28, -.2 + t * .64), Vector3(.28, 1.25, -.08 + t * .58),
					Vector3(.46, .75 + t * .1, -.18 + t * .46), .105, .07)
			accented = false
		"bedhead":
			# Tousled crop; broad overlapping locks instead of upright cones.
			_cap(hair, {"line": [62, 94, 140], "lift": .07, "crown": .055})
			for index in range(9):
				var x: float = -.38 + index * .093
				var wave: float = sin(index * 2.3)
				_lock(hair, Vector3(x, .88, -.3), Vector3(x - .16, 1.13 + wave * .07, -.05),
					Vector3(x + .13, 1.12, .34), Vector3(x + .07, .71 + wave * .06, .55), .09, .055)
			accented = false
		"curly":
			# Dense, overlapping curl clumps above a neat tapered perimeter.
			_cap(hair, {"line": [60, 91, 138], "lift": .13, "crown": .12, "curl": .025, "lumps": .018, "edge": .6})
			accented = false
		"man_bun":
			_cap(hair, {"line": [58, 92, 140], "lift": .07, "crown": .06, "strands": .009})
			_swept(hair, .015, 0.0)
			_bun(hair, Vector3(0, .91, -.5), Vector3(.2, .15, .17))
			_blob(accent, Vector3(0, .88, -.43), Vector3(.125, .105, .065))
		"mohawk":
			# Bare clipped sides and a narrow, continuous crest with swept tips.
			_crest_base(hair)
			for index in range(9):
				var angle: float = deg_to_rad(62.0 - index * 20.0)
				var azimuth: float = 0.0 if angle >= 0.0 else 180.0
				var root: Vector3 = _on(azimuth, absf(rad_to_deg(angle)), .018)
				var out: Vector3 = Vector3(0, cos(angle), sin(angle))
				var back: Vector3 = Vector3(0, sin(angle), -cos(angle))
				var height: float = .22 + .045 * sin(index * .7)
				_lock(hair, root - out * .04, root + out * height * .7,
					root + out * height + back * .08, root + out * height + back * .19,
					.135, .14)
			accented = false
		"shoulder":
			_cap(hair, {"line": [54, 148, 157], "lift": .075, "crown": .045, "drape": 1.0, "strands": .01})
			_layers(hair, .16)
			accented = false
		"chignon":
			_cap(hair, {"line": [57, 94, 143], "lift": .065, "strands": .008})
			for index in range(5):
				var t: float = index / 4.0
				_lock(hair, Vector3(-.36, .88, -.12 + t * .3), Vector3(-.18, 1.12, .38 + t * .18),
					Vector3(.42, .98, .43), Vector3(.46, .57 + t * .025, .15), .09, .035)
			_bun(hair, Vector3(0, .07, -.5), Vector3(.25, .16, .16))
			accented = false
		"mullet":
			_cap(hair, {"top": [72, 74, 76], "line": [80, 98, 162], "lift": .065, "drape": 1.0,
				"centre": 180, "span": 72, "strands": .01})
			accented = false
		"undercut":
			_cap(accent, {"line": [62, 91, 138], "lift": .065})
			# Rose-coloured swept quiff, rooted in the darker clipped sides.
			_cap(hair, {"line": [55, 43, 72], "lift": .075, "crown": .13, "brow": .17, "strands": .012})
			_swept(hair, .20, .12, .28)
		"buzz_beard":
			_cap(hair, {"line": [61, 94, 140], "lift": .06})
			_cap(hair, {"top": [125, 96, 98], "line": [164, 116, 116], "lift": .07, "centre": 0, "span": 110})
			accented = false
		"high_ponytail":
			_cap(hair, {"line": [57, 94, 140], "lift": .07, "crown": .06, "strands": .01})
			_swept(hair, .015, 0.0)
			for index in range(5):
				var x: float = (index - 2) * .043
				_lock(hair, Vector3(x, .94, -.39), Vector3(x * 1.6, 1.12, -.94),
					Vector3(x * 1.8, .2, -.92), Vector3(x * .5 + .1, -.36, -.59), .065, .055)
			_blob(accent, Vector3(0, .96, -.45), Vector3(.13, .115, .05), Vector3(-.4, 0, 0))
		"slick_back":
			_cap(hair, {"line": [54, 92, 138], "lift": .075, "crown": .075, "brow": .04})
			_swept(hair, .08, 0.0)
			accented = false
		"spiky":
			_cap(hair, {"line": [61, 92, 139], "lift": .065, "crown": .04})
			for index in range(8):
				var x: float = -.35 + index * .1
				_lock(hair, Vector3(x, .86, -.25), Vector3(x - .1, 1.04, .04),
					Vector3(x + .12, 1.17, .29), Vector3(x + .15, 1.12 + .09 * sin(index * 2.1), .46), .11, .07)
			accented = false
		"bob":
			_cap(hair, {"line": [57, 133, 133], "lift": .075, "crown": .045, "drape": 1.0, "strands": .008})
			_layers(hair, -.02)
			accented = false
		"top_knot":
			_cap(hair, {"line": [57, 93, 140], "lift": .065, "strands": .009})
			_bun(hair, Vector3(0, 1.1, -.16), Vector3(.19, .16, .18))
			_blob(accent, Vector3(0, .98, -.14), Vector3(.12, .045, .12))
		"receding":
			_cap(hair, {"line": [57, 96, 143], "temples": 24, "lift": .08, "strands": .006})
			accented = false
		"braid":
			_cap(hair, {"line": [57, 95, 145], "lift": .065, "strands": .009})
			# Three continuous interwoven sections, ending in a tapered loose tail.
			for strand in range(3):
				for link in range(8):
					var a: float = strand * TAU / 3.0 + link * PI * .75
					var b: float = a + PI * .75
					var y: float = .28 - link * .095
					var r: float = .082 - link * .004
					var start: Vector3 = Vector3(sin(a) * r, y, -.54 + cos(a) * r)
					var end: Vector3 = Vector3(sin(b) * r, y - .095, -.54 + cos(b) * r)
					_lock(hair, start, start + Vector3.DOWN * .04, end + Vector3.UP * .04, end, .06 - link * .002, .045, false)
			_blob(accent, Vector3(0, -.49, -.54), Vector3(.08, .04, .075))
			_lock(hair, Vector3(0, -.5, -.54), Vector3(-.03, -.58, -.55), Vector3(.01, -.63, -.51), Vector3(.04, -.69, -.5), .07, .045)
		"afro":
			_cap(hair, {"line": [59, 91, 131], "lift": .20, "crown": .07, "lumps": .022, "seed": 1.7, "curl": .025, "round": .8, "edge": .6})
			accented = false
		_:
			push_error("No hairstyle called " + style)
			_cap(hair, {"line": [60, 98, 148]})
			accented = false
	var result: ArrayMesh = ArrayMesh.new()
	hair.commit(result)
	if accented:
		accent.commit(result)
	built[style] = result
	return result


## Continuous sculpted locks with an elliptical section and a pointed finish. Parallel
## transported-looking frames use the scalp direction, keeping broad faces on the outside.
## Shared per style; no per-frame geometry or extra draw calls per lock.
static func _lock(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		width: float, depth: float, tapered: bool = true) -> void:
	var grid: Array = []
	const STEPS: int = 16
	const SIDES: int = 10
	for step in range(STEPS + 1):
		var t: float = step / float(STEPS)
		var u: float = 1.0 - t
		var at: Vector3 = a * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t
		var tangent: Vector3 = ((b - a) * 3.0 * u * u + (c - b) * 6.0 * u * t + (d - c) * 3.0 * t * t).normalized()
		var out: Vector3 = (at - SCALP).normalized()
		var side: Vector3 = tangent.cross(out).normalized()
		if side.length_squared() < .01:
			side = tangent.cross(Vector3.RIGHT).normalized()
		out = side.cross(tangent).normalized()
		var taper: float = lerpf(1.0, .025, pow(t, 2.0)) * lerpf(.3, 1.0, smoothstep(0.0, .18, t)) if tapered else 1.0
		var strip: Array = []
		for index in range(SIDES):
			var angle: float = TAU * index / SIDES
			var normal: Vector3 = (side * cos(angle) / width + out * sin(angle) / depth).normalized()
			strip.append([at + (side * cos(angle) * width + out * sin(angle) * depth) * taper, normal])
		grid.append(strip)
	for step in range(STEPS):
		for index in range(SIDES):
			var next: int = (index + 1) % SIDES
			_quad(tool, grid[step][index], grid[step][next], grid[step + 1][index], grid[step + 1][next])


## The close-cut strip joins the mohawk's raised locks; the rest of the scalp stays bare.
static func _crest_base(tool: SurfaceTool) -> void:
	var grid: Array = []
	for index in range(33):
		var angle: float = deg_to_rad(65.0 - index * 5.4)
		var azimuth: float = 0.0 if angle >= 0.0 else 180.0
		var out: Vector3 = Vector3(0, cos(angle), sin(angle))
		var at: Vector3 = _on(azimuth, absf(rad_to_deg(angle)), .035)
		grid.append([[at - Vector3.RIGHT * .12, out], [at + Vector3.RIGHT * .12, out]])
	for index in range(grid.size() - 1):
		_quad(tool, grid[index][0], grid[index][1], grid[index + 1][0], grid[index + 1][1])


static func _swept(tool: SurfaceTool, height: float, lean: float, half_width: float = .39) -> void:
	for index in range(8):
		var x: float = lerpf(-half_width, half_width, index / 7.0)
		var arch: float = 1.0 - absf(x) / .65
		_lock(tool, Vector3(x, .77, .36), Vector3(x + lean, 1.04 + height * arch, .49),
			Vector3(x + lean, 1.06 + height * .3, -.28), Vector3(x * .8, .72, -.5), half_width * .3, .055)


## A curved curtain at each temple, with a shaped perimeter and longer layers at the nape.
static func _layers(tool: SurfaceTool, length: float) -> void:
	for side in [-1.0, 1.0]:
		for index in range(6):
			var t: float = index / 5.0
			_lock(tool, Vector3(side * .035, 1.02, .28 - t * .53),
				Vector3(side * .5, 1.00, .53 - t * .85), Vector3(side * .57, .4, .42 - t * .88),
				Vector3(side * (.44 + .06 * t), .05 - length - t * .035, .22 - t * .64), .115, .047)


static func _bun(tool: SurfaceTool, at: Vector3, size: Vector3) -> void:
	_blob(tool, at, size, Vector3.ZERO, 20, 12)
	for index in range(5):
		var t: float = index / 4.0
		_lock(tool, at + Vector3(-size.x * .8, -.045 + t * .03, 0),
			at + Vector3(-size.x, size.y * 1.2, -size.z * .8 + t * .2),
			at + Vector3(size.x, size.y * 1.2, -size.z + t * .18),
			at + Vector3(size.x * .85, -.06, 0), .042, .025)


## A point `out` above the scalp, `azimuth` degrees round from the face, `polar` down from the crown.
static func _on(azimuth: float, polar: float, out: float) -> Vector3:
	var a: float = deg_to_rad(azimuth)
	var p: float = deg_to_rad(polar)
	return SCALP + (Vector3(sin(a), 0, cos(a)) * sin(p) + Vector3.UP * cos(p)) * (_scalp(a, p) + out)


## The skin's distance from SCALP in this direction (radians), from SCALP_RADII.
static func _scalp(azimuth: float, polar: float) -> float:
	var column: float = wrapf(rad_to_deg(azimuth), 0.0, 360.0) / 15.0
	var row: float = clampf(rad_to_deg(polar) / 10.0, 0.0, 18.0)
	var left: int = int(column) % 24
	var right: int = (left + 1) % 24
	var upper: int = mini(int(row), 17)
	var across: float = column - floorf(column)
	var down: float = row - upper
	var top: float = lerpf(SCALP_RADII[upper * 24 + left], SCALP_RADII[upper * 24 + right], across)
	var bottom: float = lerpf(SCALP_RADII[(upper + 1) * 24 + left], SCALP_RADII[(upper + 1) * 24 + right], across)
	return lerpf(top, bottom, down)


## Where the hair sits from: the skin, or for draped hair below the ears, the width at the ears.
static func _base(spec: Dictionary, azimuth: float, polar: float) -> float:
	var skin: float = lerpf(_scalp(azimuth, polar), .54, spec.get("round", 0.0))
	return lerpf(skin, _scalp(azimuth, minf(polar, PI * .5)), spec.get("drape", 0.0)) if polar > PI * .5 else skin


## Front / side / back profile, blended round the head. The front value holds over the
## forehead and drops at the temples (a sideburn edge just behind the eyes); the back
## value is reached soon behind the ears, so the nape is covered rather than the whole
## hairline running on a diagonal.
static func _profile(values: Array, azimuth: float) -> float:
	var facing: float = cos(azimuth)
	var degrees: float = lerpf(values[1], values[0], smoothstep(.5, .82, facing)) if facing >= 0.0 else lerpf(values[1], values[2], smoothstep(.15, .75, -facing))
	return deg_to_rad(degrees)


## A shell over the scalp between the `top` and `line` hairlines (degrees from the crown at
## the front, sides and back), `lift` thick, with a tucked edge so no gap shows beneath.
## crown/brow add volume on top and at the forehead; lumps and strands texture it; drape
## lets hair below the ears hang straight instead of following the skull; centre/span
## limit it to part of the way round (a beard, a mullet).
static func _cap(tool: SurfaceTool, spec: Dictionary) -> void:
	var top: Array = spec.get("top", [0, 0, 0])
	var line: Array = spec.line
	var span: float = deg_to_rad(spec.get("span", 180.0))
	var centre: float = deg_to_rad(spec.get("centre", 0.0))
	var whole: bool = span >= PI
	var columns: int = 112 if whole else maxi(16, int(72.0 * span / PI))
	var rows: int = 36 if spec.has("curl") else 22
	var crowned: bool = top.max() > .5
	var grid: Array = []
	for column in range(columns + (0 if whole else 1)):
		var azimuth: float = centre - span + 2.0 * span * column / columns
		var from: float = _profile(top, azimuth)
		var temple: float = (absf(wrapf(azimuth, -PI, PI)) - deg_to_rad(42)) / deg_to_rad(16)
		var to: float = maxf(from, _profile(line, azimuth) - deg_to_rad(spec.get("temples", 0.0)) * exp(-temple * temple))
		to += deg_to_rad(spec.get("edge", 0.0)) * sin(azimuth * 23.0)
		var strip: Array = []
		if crowned:
			strip.append([_point(spec, azimuth, from, _base(spec, azimuth, from) - .03), -_along(spec, azimuth, from)])
		for row in range(rows + 1):
			var polar: float = lerpf(from, to, float(row) / rows)
			strip.append([_surface(spec, azimuth, polar), _normal(spec, azimuth, polar)])
		strip.append([_point(spec, azimuth, to, _base(spec, azimuth, to) - .03), _along(spec, azimuth, to)])
		grid.append(strip)
	var count: int = grid.size() if whole else grid.size() - 1
	for column in range(count):
		var here: Array = grid[column]
		var next: Array = grid[(column + 1) % grid.size()]
		for row in range(here.size() - 1):
			_quad(tool, here[row], next[row], here[row + 1], next[row + 1])


static func _thickness(spec: Dictionary, azimuth: float, polar: float) -> float:
	var seed: float = spec.get("seed", 0.0)
	var thickness: float = spec.get("lift", .05)
	thickness += spec.get("crown", 0.0) * clampf(1.0 - polar / deg_to_rad(75), 0, 1)
	thickness += spec.get("brow", 0.0) * pow(maxf(cos(azimuth), 0.0), 3) * clampf(1.0 - absf(polar - deg_to_rad(38)) / deg_to_rad(36), 0, 1)
	thickness += spec.get("lumps", 0.0) * (sin(azimuth * 5.0 + seed) * sin(polar * 6.0 + seed * 1.3) + .5 * sin(azimuth * 11.0 + polar * 7.0 + seed * 2.1)) * minf(polar * 4.0, 1.0)
	thickness += spec.get("strands", 0.0) * absf(sin(azimuth * 9.0 + polar * 1.5))
	thickness += spec.get("curl", 0.0) * cos(polar * 18.0) * cos(azimuth * 18.0 + sin(polar * 9.0)) * minf(polar * 5.0, 1.0)
	return thickness


static func _point(spec: Dictionary, azimuth: float, polar: float, radius: float) -> Vector3:
	var out: Vector3 = Vector3(sin(azimuth), 0, cos(azimuth))
	var hug: Vector3 = SCALP + (out * sin(polar) + Vector3.UP * cos(polar)) * radius
	var drape: float = spec.get("drape", 0.0)
	if polar <= PI * .5 or drape <= 0.0:
		return hug
	# Below the ears it falls straight down, the same distance it would have curled in.
	var hang: Vector3 = SCALP + out * radius + Vector3.DOWN * (polar - PI * .5) * radius
	return hug.lerp(hang, drape)


static func _surface(spec: Dictionary, azimuth: float, polar: float) -> Vector3:
	return _point(spec, azimuth, polar, _base(spec, azimuth, polar) + _thickness(spec, azimuth, polar))


## Down the hair at this point: the way the tucked edges face.
static func _along(spec: Dictionary, azimuth: float, polar: float) -> Vector3:
	return (_surface(spec, azimuth, polar + .02) - _surface(spec, azimuth, polar - .02)).normalized()


static func _normal(spec: Dictionary, azimuth: float, polar: float) -> Vector3:
	var at: float = maxf(polar, .03)
	var down: Vector3 = _surface(spec, azimuth, at + .01) - _surface(spec, azimuth, at - .01)
	var round_: Vector3 = _surface(spec, azimuth + .01, at) - _surface(spec, azimuth - .01, at)
	var normal: Vector3 = down.cross(round_).normalized()
	var point: Vector3 = _surface(spec, azimuth, at)
	return -normal if normal.dot(point - Vector3(SCALP.x, minf(point.y, SCALP.y), SCALP.z)) < 0.0 else normal


## An ellipsoid of half-size `size`, turned by `tilt` (Euler radians).
static func _blob(tool: SurfaceTool, at: Vector3, size: Vector3, tilt: Vector3 = Vector3.ZERO, segments: int = 12, rings: int = 7) -> void:
	_ellipsoid(tool, at, size, Basis.from_euler(tilt), segments, rings)


static func _ellipsoid(tool: SurfaceTool, at: Vector3, size: Vector3, turn: Basis, segments: int, rings: int) -> void:
	var grid: Array = []
	for ring in range(rings + 1):
		var polar: float = PI * ring / rings
		var strip: Array = []
		for segment in range(segments):
			var azimuth: float = TAU * segment / segments
			var unit: Vector3 = Vector3(sin(polar) * cos(azimuth), cos(polar), sin(polar) * sin(azimuth))
			var normal: Vector3 = turn * (unit / size).normalized()
			strip.append([at + turn * (unit * size), normal])
		grid.append(strip)
	for ring in range(rings):
		for segment in range(segments):
			var next: int = (segment + 1) % segments
			_quad(tool, grid[ring][segment], grid[ring][next], grid[ring + 1][segment], grid[ring + 1][next])


static func _quad(tool: SurfaceTool, a: Array, b: Array, c: Array, d: Array) -> void:
	_triangle(tool, a, b, c)
	_triangle(tool, b, d, c)


## Godot's front faces wind clockwise; flip any triangle that would face inward.
static func _triangle(tool: SurfaceTool, a: Array, b: Array, c: Array) -> void:
	var face: Vector3 = (b[0] - a[0]).cross(c[0] - a[0])
	if face.length_squared() < 1e-12:
		return
	var facing: Vector3 = a[1] + b[1] + c[1]
	var order: Array = [a, c, b] if face.dot(facing) > 0.0 else [a, b, c]
	for vertex: Array in order:
		tool.set_normal(vertex[1])
		tool.add_vertex(vertex[0])
