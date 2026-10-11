extends SceneTree
## Prints hairstyles.gd's SCALP_RADII: how far the shared Quaternius head's skin lies from
## SCALP, every 15 degrees round from the face and every 10 degrees down from the crown.
## sh tools/godot.sh --headless --path . --script tools/measure_scalp.gd

const HAIR = preload("res://game/incidents/hairstyles.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var body: Node3D = load("res://assets/characters/quaternius/casual2_male.fbx").instantiate()
	root.add_child(body)
	var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
	var head: int = skeleton.find_bone("Head")
	var frame: Transform3D = skeleton.global_transform * skeleton.get_bone_global_rest(head)
	var into_head: Transform3D = frame.affine_inverse()
	var unit: float = frame.basis.get_scale().x
	var instance: MeshInstance3D = body.find_children("*", "MeshInstance3D", true, false)[0]
	var bind: int = -1
	for index in instance.skin.get_bind_count():
		if instance.skin.get_bind_name(index) == "Head" or instance.skin.get_bind_bone(index) == head:
			bind = index
	var triangles: PackedVector3Array = []
	for surface in instance.mesh.get_surface_count():
		var material: Material = instance.mesh.surface_get_material(surface)
		if material == null or material.resource_name != "Skin":
			continue
		var arrays: Array = instance.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var per: int = bones.size() / vertices.size()
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for start in range(0, indices.size(), 3):
			var on_head: bool = true
			for corner in range(3):
				var vertex: int = indices[start + corner]
				var weight: float = 0.0
				for slot in per:
					if bones[vertex * per + slot] == bind:
						weight += weights[vertex * per + slot]
				on_head = on_head and weight >= .5
			if on_head:
				for corner in range(3):
					triangles.append(into_head * (instance.global_transform * vertices[indices[start + corner]]) * unit)
	var text: String = "const SCALP_RADII: PackedFloat32Array = [\n"
	var fallback: float = HAIR.RADIUS
	for polar in range(0, 181, 10):
		text += "\t"
		for azimuth in range(0, 360, 15):
			var a: float = deg_to_rad(azimuth)
			var p: float = deg_to_rad(polar)
			var direction: Vector3 = Vector3(sin(a) * sin(p), cos(p), cos(a) * sin(p))
			var reach: float = -1.0
			for start in range(0, triangles.size(), 3):
				var hit: Variant = Geometry3D.ray_intersects_triangle(HAIR.SCALP, direction, triangles[start], triangles[start + 1], triangles[start + 2])
				if hit != null:
					reach = maxf(reach, ((hit as Vector3) - HAIR.SCALP).length())
			if reach < 0.0:
				reach = fallback
			fallback = reach
			text += "%.3f, " % reach
		text = text.strip_edges(false, true) + "\n"
	print(text + "]")
	quit()
