extends SceneTree
## Offline CC0 mesh edits. Existing skins and animation rigs remain in the source FBX.
const OUTPUT: String = "res://assets/characters/office_outfits/"
const SOURCE: String = "res://assets/characters/quaternius/"
const FLAGS: int = Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS


func _initialize() -> void:
	_build.call_deferred()


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for entry: Array in [["casual_female", "casual_skirt", .0062, false], ["casual2_female", "blouse_skirt", .0053, false], ["suit_female", "suit_skirt", .0062, false], ["suit_female", "director_skirt", .0072, true]]:
		var body: Node3D = load(SOURCE + entry[0] + ".fbx").instantiate()
		root.add_child(body)
		var instance: MeshInstance3D = body.find_child("Body*", true, false)
		assert(instance != null and instance.skin != null)
		var mesh: ArrayMesh = ArrayMesh.new()
		for surface in range(instance.mesh.get_surface_count()):
			var source: Material = instance.mesh.surface_get_material(surface)
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			if source.resource_name in ["Pants", "Black"]:
				_split_legs(mesh, arrays, source, bool(entry[3]))
			elif entry[3] and source.resource_name in ["Shirt", "Details"]:
				var blouse_material: Material = source.duplicate()
				blouse_material.resource_name = "Shirt"
				_neckline(mesh, arrays, blouse_material)
			else:
				_add(mesh, arrays, source)
		_skirt(mesh, instance.skin, float(entry[2]))
		_earrings(mesh, instance.skin, instance.mesh)
		mesh.resource_name = entry[1]
		var error: Error = ResourceSaver.save(mesh, OUTPUT + entry[1] + ".res", ResourceSaver.FLAG_COMPRESS)
		assert(error == OK)
		print("OUTFIT ", entry[1], ": ", mesh.get_surface_count(), " surfaces")
		body.free()
	quit()


func _add(mesh: ArrayMesh, arrays: Array, material: Material) -> void:
	if arrays[Mesh.ARRAY_VERTEX].is_empty():
		return
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, FLAGS)
	# Own materials in the exported mesh; never depend on cached FBX subresource IDs.
	var owned: Material = material.duplicate(true)
	mesh.surface_set_material(mesh.get_surface_count() - 1, owned)


func _empty() -> Array:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	arrays[Mesh.ARRAY_BONES] = PackedInt32Array()
	arrays[Mesh.ARRAY_WEIGHTS] = PackedFloat32Array()
	return arrays


func _copy_vertex(out: Array, source: Array, index: int) -> void:
	out[Mesh.ARRAY_VERTEX].append(source[Mesh.ARRAY_VERTEX][index])
	out[Mesh.ARRAY_NORMAL].append(source[Mesh.ARRAY_NORMAL][index])
	var uv: Vector2 = source[Mesh.ARRAY_TEX_UV][index] if source[Mesh.ARRAY_TEX_UV] != null else Vector2.ZERO
	out[Mesh.ARRAY_TEX_UV].append(uv)
	for influence in range(8):
		out[Mesh.ARRAY_BONES].append(source[Mesh.ARRAY_BONES][index * 8 + influence])
		out[Mesh.ARRAY_WEIGHTS].append(source[Mesh.ARRAY_WEIGHTS][index * 8 + influence])


func _indices(arrays: Array) -> PackedInt32Array:
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		for index in range(arrays[Mesh.ARRAY_VERTEX].size()):
			indices.append(index)
	return indices


func _skin_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.resource_name = "OutfitSkin"
	material.roughness = .85
	return material


func _split_legs(mesh: ArrayMesh, arrays: Array, material: Material, low_cut: bool) -> void:
	var clothes: Array = _empty()
	var legs: Array = _empty()
	var indices: PackedInt32Array = _indices(arrays)
	for offset in range(0, indices.size(), 3):
		var centre: Vector3 = Vector3.ZERO
		for corner in range(3):
			centre += arrays[Mesh.ARRAY_VERTEX][indices[offset + corner]] / 3.0
		# Imported FBX mesh space is centimetres with Z up. Keep shoes and jacket;
		# the skirt covers the hips, while lower legs use the character's skin palette.
		var neckline: bool = low_cut and centre.z > .014 and centre.z < .0213 and absf(centre.x) < .0012 and centre.y < .0007
		var target: Array = legs if neckline or centre.z > .0015 and centre.z < .0085 else clothes
		for corner in range(3):
			_copy_vertex(target, arrays, indices[offset + corner])
	_add(mesh, clothes, material)
	_add(mesh, legs, _skin_material())


func _interpolate(out: Array, arrays: Array, triangle: PackedInt32Array, barycentric: Vector3) -> void:
	var position_: Vector3 = Vector3.ZERO
	var normal: Vector3 = Vector3.ZERO
	var uv: Vector2 = Vector2.ZERO
	var influences: Dictionary = {}
	for corner in range(3):
		var index: int = triangle[corner]
		var mix: float = barycentric[corner]
		position_ += arrays[Mesh.ARRAY_VERTEX][index] * mix
		normal += arrays[Mesh.ARRAY_NORMAL][index] * mix
		if arrays[Mesh.ARRAY_TEX_UV] != null:
			uv += arrays[Mesh.ARRAY_TEX_UV][index] * mix
		for influence in range(8):
			var bone: int = arrays[Mesh.ARRAY_BONES][index * 8 + influence]
			var weight: float = arrays[Mesh.ARRAY_WEIGHTS][index * 8 + influence] * mix
			influences[bone] = float(influences.get(bone, 0)) + weight
	var ordered: Array = influences.keys()
	ordered.sort_custom(func(a: int, b: int) -> bool: return influences[a] > influences[b])
	var total: float = 0
	for index in range(mini(8, ordered.size())):
		total += influences[ordered[index]]
	out[Mesh.ARRAY_VERTEX].append(position_)
	out[Mesh.ARRAY_NORMAL].append(normal.normalized())
	out[Mesh.ARRAY_TEX_UV].append(uv)
	for index in range(8):
		out[Mesh.ARRAY_BONES].append(ordered[index] if index < ordered.size() else 0)
		out[Mesh.ARRAY_WEIGHTS].append(float(influences[ordered[index]]) / total if index < ordered.size() else 0.0)


func _neckline(mesh: ArrayMesh, arrays: Array, material: Material) -> void:
	var blouse: Array = _empty()
	var skin: Array = _empty()
	var indices: PackedInt32Array = _indices(arrays)
	const STEPS: int = 8
	for offset in range(0, indices.size(), 3):
		var triangle: PackedInt32Array = indices.slice(offset, offset + 3)
		for row in range(STEPS):
			for column in range(STEPS - row):
				var a: Vector3 = Vector3(1.0 - float(row + column) / STEPS, float(row) / STEPS, float(column) / STEPS)
				var b: Vector3 = a + Vector3(-1, 1, 0) / STEPS
				var c: Vector3 = a + Vector3(-1, 0, 1) / STEPS
				_neck_triangle(blouse, skin, arrays, triangle, [a, b, c])
				if row + column < STEPS - 1:
					_neck_triangle(blouse, skin, arrays, triangle, [b, b + Vector3(-1, 0, 1) / STEPS, c])
	_add(mesh, blouse, material)
	_add(mesh, skin, _skin_material())


func _neck_triangle(blouse: Array, skin: Array, arrays: Array, triangle: PackedInt32Array, points: Array[Vector3]) -> void:
	var midpoint: Vector3 = Vector3.ZERO
	for barycentric in points:
		for corner in range(3):
			midpoint += arrays[Mesh.ARRAY_VERTEX][triangle[corner]] * barycentric[corner] / 3.0
	var width: float = .0025 * clampf((midpoint.z - .0158) / .005, 0, 1)
	var exposed: bool = midpoint.z > .0158 and midpoint.z < .0212 and midpoint.y < .0007 and absf(midpoint.x) < width
	for barycentric in points:
		_interpolate(skin if exposed else blouse, arrays, triangle, barycentric)


func _bind(skin: Skin, name_: String) -> int:
	for index in range(skin.get_bind_count()):
		if skin.get_bind_name(index) == name_:
			return index
	assert(false, "Missing clothing bone: " + name_)
	return 0


func _skirt(mesh: ArrayMesh, skin: Skin, hem: float) -> void:
	var arrays: Array = _empty()
	var hips: int = _bind(skin, "Hips")
	var left: int = _bind(skin, "UpperLeg.L")
	var right: int = _bind(skin, "UpperLeg.R")
	const RINGS: int = 6
	const SIDES: int = 24
	for ring in range(RINGS):
		for side in range(SIDES):
			var t: float = float(ring) / (RINGS - 1)
			var angle: float = TAU * side / SIDES
			var width: float = lerpf(.0045, .0055, t)
			var depth: float = lerpf(.0036, .0038, t)
			var pleat: float = 1.0 + .025 * cos(angle * 12) * t
			var point: Vector3 = Vector3(cos(angle) * width * pleat, sin(angle) * depth * pleat, lerpf(.0122, hem, t))
			arrays[Mesh.ARRAY_VERTEX].append(point)
			arrays[Mesh.ARRAY_NORMAL].append(Vector3(cos(angle), sin(angle), .18).normalized())
			arrays[Mesh.ARRAY_TEX_UV].append(Vector2(float(side) / SIDES, t))
			var leg: float = .78 * t
			var left_share: float = smoothstep(-.0012, .0012, point.x)
			for influence in range(8):
				arrays[Mesh.ARRAY_BONES].append([hips, left, right][influence] if influence < 3 else 0)
				arrays[Mesh.ARRAY_WEIGHTS].append([1.0 - leg, leg * left_share, leg * (1.0 - left_share)][influence] if influence < 3 else 0.0)
	var indices: PackedInt32Array = PackedInt32Array()
	for ring in range(RINGS - 1):
		for side in range(SIDES):
			var a: int = ring * SIDES + side
			var b: int = ring * SIDES + (side + 1) % SIDES
			indices.append_array(PackedInt32Array([a, a + SIDES, b, b, a + SIDES, b + SIDES]))
	arrays[Mesh.ARRAY_INDEX] = indices
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.resource_name = "Skirt"
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = .9
	_add(mesh, arrays, material)


func _earrings(mesh: ArrayMesh, skin: Skin, original: Mesh) -> void:
	var arrays: Array = _empty()
	var indices: PackedInt32Array = PackedInt32Array()
	var head: int = _bind(skin, "Head")
	const SIDES: int = 16
	const TUBE: int = 6
	for side: float in [-1.0, 1.0]:
		var anchor: Vector3 = Vector3.ZERO
		for surface in range(original.get_surface_count()):
			if original.surface_get_material(surface).resource_name != "Skin":
				continue
			var source: Array = original.surface_get_arrays(surface)
			for vertex: Vector3 in source[Mesh.ARRAY_VERTEX]:
				if vertex.z > .0225 and vertex.z < .0245 and vertex.x * side > anchor.x * side:
					anchor = vertex
		var centre: Vector3 = anchor + Vector3(side * .0001, 0, -.00048)
		var start: int = arrays[Mesh.ARRAY_VERTEX].size()
		for ring in range(SIDES):
			var angle: float = TAU * ring / SIDES
			for tube in range(TUBE):
				var turn: float = TAU * tube / TUBE
				var radius: float = .0005 + .00008 * cos(turn)
				var point: Vector3 = centre + Vector3(radius * cos(angle), .00008 * sin(turn), radius * sin(angle))
				arrays[Mesh.ARRAY_VERTEX].append(point)
				arrays[Mesh.ARRAY_NORMAL].append(Vector3(cos(turn) * cos(angle), sin(turn), cos(turn) * sin(angle)))
				arrays[Mesh.ARRAY_TEX_UV].append(Vector2(float(ring) / SIDES, float(tube) / TUBE))
				for influence in range(8):
					arrays[Mesh.ARRAY_BONES].append(head if influence == 0 else 0)
					arrays[Mesh.ARRAY_WEIGHTS].append(1.0 if influence == 0 else 0.0)
		for ring in range(SIDES):
			for tube in range(TUBE):
				var a: int = start + ring * TUBE + tube
				var b: int = start + ((ring + 1) % SIDES) * TUBE + tube
				var c: int = start + ring * TUBE + (tube + 1) % TUBE
				var d: int = start + ((ring + 1) % SIDES) * TUBE + (tube + 1) % TUBE
				indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	arrays[Mesh.ARRAY_INDEX] = indices
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.resource_name = "Jewelry"
	material.albedo_color = Color(.92, .65, .22)
	material.metallic = .65
	material.roughness = .28
	_add(mesh, arrays, material)
