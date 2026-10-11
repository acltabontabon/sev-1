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
const STYLES: Array[String] = ["side_part", "pompadour", "bedhead", "curly", "man_bun", "horseshoe",
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
	material.roughness = .72
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
			# A neat manager's part: combed over to one side, a little volume on top.
			_cap(hair, {"line": [60, 98, 148], "lift": .05, "crown": .04, "strands": .012})
			_blob(hair, _on(-28, 34, .06), Vector3(.3, .1, .24), Vector3(.25, 0, .3))
			_blob(hair, _on(30, 50, .04), Vector3(.24, .08, .26), Vector3(0, 0, -.35))
			accented = false
		"pompadour":
			# Tight sides, everything else swept up and out over the forehead: the sales pitch.
			_cap(hair, {"line": [58, 98, 148], "lift": .035, "crown": .04, "brow": .3, "strands": .012})
			accented = false
		"bedhead":
			# Slept at the desk: lumpy, with tufts going every which way.
			_cap(hair, {"line": [64, 98, 148], "lift": .05, "lumps": .03, "seed": 3.0})
			for tuft: Array in [[0, 8, .2, 10], [40, 30, .18, -20], [-50, 26, .2, 15], [150, 34, .2, 30],
					[-140, 40, .18, -25], [95, 50, .16, 0], [-95, 52, .16, 10], [10, 40, .17, -30], [180, 58, .15, 0]]:
				var root: Vector3 = _on(tuft[0], tuft[1], .02)
				var out: Vector3 = (root - SCALP).normalized().rotated(Vector3.UP, deg_to_rad(tuft[3]))
				_cone(hair, root, root + out * tuft[2] + Vector3.UP * .05, .09)
			accented = false
		"curly":
			# A mop of tight curls over a short cap.
			_cap(hair, {"line": [62, 98, 146], "lift": .05})
			for row: Array in [[8, 3, 0.0], [28, 8, 20.0], [48, 11, 0.0], [68, 12, 15.0], [88, 10, 0.0], [110, 7, 180.0]]:
				for index in range(row[1]):
					var azimuth: float = row[2] + 360.0 * index / row[1]
					if row[0] >= 68 and absf(wrapf(azimuth, -180, 180)) < (40 if row[0] < 100 else 110):
						continue
					_blob(hair, _on(azimuth, row[0], .08), Vector3.ONE * .12, Vector3.ZERO, 7, 4)
			accented = false
		"man_bun":
			# Scraped back into a bun, the scrum master's tell.
			_cap(hair, {"line": [60, 98, 148], "lift": .035, "strands": .018})
			_blob(hair, _on(180, 42, .17), Vector3(.17, .16, .16))
			_blob(accent, _on(180, 46, .06), Vector3(.12, .12, .05), Vector3(-.75, 0, 0))
		"horseshoe":
			# Bald on top, a ring round the back: forty minutes waiting for the microwave.
			_cap(hair, {"top": [70, 60, 54], "line": [64, 100, 150], "lift": .04, "lumps": .012})
			accented = false
		"shoulder":
			# Working from home since 2020; the haircut never came back from lockdown.
			_cap(hair, {"line": [56, 132, 154], "lift": .06, "crown": .03, "strands": .014, "drape": 1.0})
			accented = false
		"chignon":
			# Sleek, side-swept and pinned low at the nape: a director's updo.
			_cap(hair, {"line": [60, 100, 150], "lift": .035, "strands": .016})
			_blob(hair, _on(-22, 40, .05), Vector3(.28, .09, .22), Vector3(.2, 0, .35))
			_blob(hair, _on(180, 128, .12), Vector3(.24, .17, .16))
			accented = false
		"mullet":
			# Business under the cap, party down the back.
			_cap(hair, {"top": [72, 74, 76], "line": [80, 100, 168], "lift": .045, "lumps": .015, "drape": 1.0,
				"centre": 180, "span": 72})
			accented = false
		"undercut":
			# Clipped dark sides; a dyed quiff down the middle, tallest over the forehead.
			_cap(accent, {"line": [66, 98, 148], "lift": .03})
			_blob(hair, Vector3(0, .98, -.04), Vector3(.24, .12, .5), Vector3(-.12, 0, 0))
			_blob(hair, _on(0, 36, .13), Vector3(.24, .15, .22), Vector3(-.55, 0, 0))
		"buzz_beard":
			# Clippers on a three, and a full beard that is on a different incident.
			_cap(hair, {"line": [64, 98, 148], "lift": .03})
			_cap(hair, {"top": [122, 98, 98], "line": [168, 118, 118], "lift": .045, "lumps": .01, "centre": 0,
				"span": 112})
			accented = false
		"high_ponytail":
			_cap(hair, {"line": [58, 98, 146], "lift": .035, "strands": .018})
			_blob(accent, _on(180, 36, .07), Vector3(.1, .1, .06), Vector3(-.5, 0, 0))
			# Gathered at the crown, it arcs out and falls between the shoulder blades.
			var tail: Array = []
			for step in range(13):
				var along: float = step / 12.0
				tail.append(_on(180, 36 + 86 * along, .09 + .15 * sin(along * PI * .75)))
			for step in range(12):
				_segment(hair, tail[step], tail[step + 1], lerpf(.13, .06, step / 11.0))
		"slick_back":
			# Combed straight back with product, high off the forehead.
			_cap(hair, {"line": [54, 98, 150], "lift": .045, "crown": .03, "brow": .05, "strands": .03})
			accented = false
		"spiky":
			_cap(hair, {"line": [62, 98, 146], "lift": .035})
			for index in range(13):
				var azimuth: float = 360.0 * index / 10.0 if index < 10 else 120.0 * (index - 10)
				var polar: float = 42.0 if index < 10 else 14.0
				var root: Vector3 = _on(azimuth, polar, .02)
				var out: Vector3 = ((root - SCALP).normalized() + Vector3.UP * .8).normalized()
				_cone(hair, root, root + out * .22, .09)
			accented = false
		"bob":
			# A blunt jaw-length bob with a full fringe.
			_cap(hair, {"line": [66, 132, 136], "lift": .07, "crown": .03, "strands": .01, "drape": 1.0})
			accented = false
		"top_knot":
			_cap(hair, {"line": [58, 98, 146], "lift": .03, "strands": .02})
			_blob(hair, Vector3(0, 1.1, -.12), Vector3(.17, .15, .17))
			_blob(accent, Vector3(0, .99, -.1), Vector3(.11, .05, .11))
		"receding":
			# The temples gave up years ago; the middle is holding on for the next reorg.
			_cap(hair, {"line": [58, 100, 150], "temples": 34, "lift": .035, "strands": .014})
			accented = false
		"braid":
			_cap(hair, {"line": [58, 100, 152], "lift": .04, "strands": .02})
			for link in range(7):
				var side: float = .035 if link % 2 == 0 else -.035
				_blob(hair, Vector3(side, .12 - link * .1, -.46 + link * .012), Vector3(.1, .08, .08), Vector3(0, 0, side * 8.0))
			_blob(accent, Vector3(0, -.6, -.38), Vector3(.06, .04, .06))
		"afro":
			_cap(hair, {"line": [60, 94, 136], "lift": .16, "crown": .12, "lumps": .045, "seed": 1.7})
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
	var skin: float = _scalp(azimuth, polar)
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
	var columns: int = 28 if whole else maxi(8, int(28.0 * span / PI))
	var rows: int = 9
	var crowned: bool = top.max() > .5
	var grid: Array = []
	for column in range(columns + (0 if whole else 1)):
		var azimuth: float = centre - span + 2.0 * span * column / columns
		var from: float = _profile(top, azimuth)
		var temple: float = (absf(wrapf(azimuth, -PI, PI)) - deg_to_rad(42)) / deg_to_rad(16)
		var to: float = maxf(from, _profile(line, azimuth) - deg_to_rad(spec.get("temples", 0.0)) * exp(-temple * temple))
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
	thickness += spec.get("lumps", 0.0) * (sin(azimuth * 5.0 + seed) * sin(polar * 6.0 + seed * 1.3) + .5 * sin(azimuth * 11.0 + polar * 7.0 + seed * 2.1))
	thickness += spec.get("strands", 0.0) * absf(sin(azimuth * 9.0))
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


## A rounded length of hair from `from` to `to`, overlapping its neighbours and lying
## flatter against the head than across it.
static func _segment(tool: SurfaceTool, from: Vector3, to: Vector3, thickness: float) -> void:
	var length: Vector3 = to - from
	var along: Vector3 = length.normalized()
	var out: Vector3 = ((from + to) * .5 - SCALP).normalized()
	out = (out - along * out.dot(along)).normalized()
	var turn: Basis = Basis(along.cross(out), along, out)
	_ellipsoid(tool, (from + to) * .5, Vector3(thickness, length.length(), thickness * .6), turn, 10, 6)


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


## A five-sided faceted tuft from `root` to `tip`.
static func _cone(tool: SurfaceTool, root: Vector3, tip: Vector3, width: float) -> void:
	var axis: Vector3 = (tip - root).normalized()
	var side: Vector3 = axis.cross(Vector3.FORWARD if absf(axis.y) > .9 else Vector3.UP).normalized()
	for index in range(5):
		var a: Vector3 = root + side.rotated(axis, TAU * index / 5.0) * width
		var b: Vector3 = root + side.rotated(axis, TAU * (index + 1) / 5.0) * width
		var normal: Vector3 = (b - a).cross(tip - a).normalized()
		if normal.dot((a + b) * .5 - root) < 0.0:
			normal = -normal
		_triangle(tool, [a, normal], [b, normal], [tip, normal])


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
