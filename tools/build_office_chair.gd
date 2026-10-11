extends SceneTree
## Offline consolidation of the licensed chair: preserve geometry, UVs and materials,
## combine 60 separate pieces into five material surfaces. No runtime generation.


func _initialize() -> void:
	_build.call_deferred()


func _build() -> void:
	var source: Node3D = load("res://assets/environment/innerscene_chair/vector_office_chair_source.glb").instantiate()
	root.add_child(source)
	var groups: Dictionary = {}
	var triangles: int = 0
	for node in source.find_children("*", "MeshInstance3D", true, false):
		var part: MeshInstance3D = node
		for surface in range(part.mesh.get_surface_count()):
			var material: Material = part.get_active_material(surface)
			if not groups.has(material):
				var tool: SurfaceTool = SurfaceTool.new()
				tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				tool.set_material(material)
				groups[material] = tool
			groups[material].append_from(part.mesh, surface, source.global_transform.affine_inverse() * part.global_transform)
			var arrays: Array = part.mesh.surface_get_arrays(surface)
			triangles += arrays[Mesh.ARRAY_INDEX].size()/3
	var merged: ArrayMesh = ArrayMesh.new()
	for material: Material in groups:
		var tool: SurfaceTool = groups[material]
		tool.optimize_indices_for_cache()
		tool.commit(merged)
	var chair: Node3D = Node3D.new()
	chair.name = "VectorOfficeChair"
	var mesh_node: MeshInstance3D = MeshInstance3D.new()
	mesh_node.name = "ChairMesh"
	mesh_node.mesh = merged
	chair.add_child(mesh_node)
	var document: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	var error: Error = document.append_from_scene(chair, state)
	if error == OK:
		var bytes: PackedByteArray = document.generate_buffer(state)
		var file: FileAccess = FileAccess.open("res://assets/environment/innerscene_chair/vector_office_chair.glb", FileAccess.WRITE)
		if file == null or bytes.is_empty():
			error = ERR_CANT_CREATE
		else:
			file.store_buffer(bytes)
			file.close()
	print("Chair: ", triangles, " triangles, ", merged.get_surface_count(), " material surfaces; bounds ", merged.get_aabb())
	chair.free()
	source.queue_free()
	await process_frame
	quit(0 if error == OK else 1)
