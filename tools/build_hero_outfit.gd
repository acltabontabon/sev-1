extends SceneTree
## Offline CC0 mesh edit: re-dresses the engineer's Quaternius casual body as a
## developer in a hoodie with pushed-up sleeves, joggers and high-top sneakers.
## No new geometry: existing triangles move between clothing surfaces, so the source
## skin, bind poses and every retargeted clip keep working unchanged.
## sh tools/godot.sh --headless --path . --script tools/build_hero_outfit.gd
const SOURCE: String = "res://assets/characters/quaternius/casual_male.fbx"
const OUTPUT: String = "res://assets/characters/hero_outfit/dev_hoodie.res"
const FLAGS: int = Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
## FBX mesh space is Z up with -Y forward; one unit is this many metres on the rig.
const METRES: float = 64.0
## Arms run along X in the bind T-pose: the sleeves are shoved up past the elbow
## (the runtime adds the bunched fabric there), leaving bare forearms.
const SLEEVE_END: float = .6
## Heights in metres: hoodie hem rib, jogger cuff, shoe collar and sole.
const HEM: float = .79
const JOGGER_CUFF: float = .19
const SHOE_TOP: float = .125
const SOLE_TOP: float = .045
## Fingerless gloves cover the hand up to the knuckles (arm reach in the T-pose).
const GLOVE_END: float = .93
const SURFACES: Array[String] = ["Skin", "Glove", "Hoodie", "Rib", "Pants", "Belt", "Shoe", "Sole", "Face", "Hair", "Streak"]


func _initialize() -> void:
	_build.call_deferred()


func _build() -> void:
	var body: Node3D = load(SOURCE).instantiate()
	root.add_child(body)
	var instance: MeshInstance3D = body.find_child("Body*", true, false)
	assert(instance != null and instance.skin != null)
	var buckets: Dictionary = {}
	var templates: Dictionary = {}
	for name_ in SURFACES:
		buckets[name_] = _empty()
	for surface in range(instance.mesh.get_surface_count()):
		var source: Material = instance.mesh.surface_get_material(surface)
		var arrays: Array = instance.mesh.surface_get_arrays(surface)
		templates[source.resource_name] = source
		var indices: PackedInt32Array = _indices(arrays)
		for offset in range(0, indices.size(), 3):
			var triangle: PackedInt32Array = indices.slice(offset, offset + 3)
			var target: String = _classify(source.resource_name, arrays, triangle, instance.skin)
			for index in triangle:
				_copy_vertex(buckets[target], arrays, index)
	var mesh: ArrayMesh = ArrayMesh.new()
	for name_ in SURFACES:
		var arrays: Array = buckets[name_]
		if arrays[Mesh.ARRAY_VERTEX].is_empty():
			continue
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, FLAGS)
		# Own materials in the exported mesh; never depend on cached FBX subresource IDs.
		var material: StandardMaterial3D = (templates.get(name_, templates["Shirt"]) as StandardMaterial3D).duplicate(true)
		material.resource_name = name_
		mesh.surface_set_material(mesh.get_surface_count() - 1, material)
		print("SURFACE ", name_, ": ", arrays[Mesh.ARRAY_VERTEX].size() / 3, " triangles")
	mesh.resource_name = "dev_hoodie"
	DirAccess.make_dir_recursive_absolute(OUTPUT.get_base_dir())
	var error: Error = ResourceSaver.save(mesh, OUTPUT, ResourceSaver.FLAG_COMPRESS)
	assert(error == OK)
	print("OUTFIT ", OUTPUT)
	body.free()
	quit()


func _classify(surface: String, arrays: Array, triangle: PackedInt32Array, skin: Skin) -> String:
	var centre: Vector3 = Vector3.ZERO
	for index in triangle:
		centre += arrays[Mesh.ARRAY_VERTEX][index] * METRES / 3.0
	var height: float = centre.z
	var reach: float = absf(centre.x)
	var bone: String = _dominant_bone(arrays, triangle, skin)
	match surface:
		"Skin":
			if bone.begins_with("UpperArm") or bone.begins_with("LowerArm") and reach < SLEEVE_END:
				return "Hoodie"
			if bone.begins_with("Foot") or bone.contains("Leg") and height < SHOE_TOP:
				return "Sole" if height < SOLE_TOP else "Shoe"
			if bone.contains("Leg"):
				return "Rib" if height < JOGGER_CUFF else "Pants"
			if bone.begins_with("Fist") and reach < GLOVE_END:
				return "Glove"
			return "Skin"
		"Hair":
			# One dyed streak through the front-left fringe (the rig faces -Y here).
			return "Streak" if centre.x > .06 and centre.x < .24 and centre.y < -.2 and height > 1.86 else "Hair"
		"Shirt":
			# The open front and its tee are runtime panels: this mesh is too coarse
			# for a clean zip edge.
			return "Rib" if height < HEM else "Hoodie"
		"Pants":
			return "Pants"
	return surface


func _dominant_bone(arrays: Array, triangle: PackedInt32Array, skin: Skin) -> String:
	var influences: Dictionary = {}
	for index in triangle:
		for influence in range(8):
			var bind: int = arrays[Mesh.ARRAY_BONES][index * 8 + influence]
			influences[bind] = float(influences.get(bind, 0.0)) + arrays[Mesh.ARRAY_WEIGHTS][index * 8 + influence]
	var best: int = influences.keys()[0]
	for bind: int in influences:
		if influences[bind] > influences[best]:
			best = bind
	return String(skin.get_bind_name(best))


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
