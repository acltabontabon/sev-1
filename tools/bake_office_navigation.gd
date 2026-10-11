extends SceneTree
## Bake static world collision offline. No runtime bake or editor clicks required.

func _initialize() -> void:
	_bake.call_deferred()


func _bake() -> void:
	var room: Node3D = load("res://game/rooms/office/office_after_hours.tscn").instantiate()
	root.add_child(room)
	var mesh: NavigationMesh = NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.agent_radius = 0.75
	mesh.agent_height = 2.0
	mesh.agent_max_climb = 0.25
	mesh.agent_max_slope = 40
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	mesh.filter_baking_aabb = AABB(Vector3(-14, -1, -52), Vector3(46, 10, 68))
	var source: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, source, room)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	var error: Error = ResourceSaver.save(mesh, "res://game/rooms/office/navigation.tres")
	print("Navigation polygons: ", mesh.get_polygon_count())
	room.queue_free()
	await process_frame
	quit(0 if error == OK and mesh.get_polygon_count() > 0 else 1)
