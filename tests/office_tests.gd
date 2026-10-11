extends "res://tests/combat_tests.gd"
## Environment integration: floor, furnishings, camera clearance, and actual pursuit.

func _run() -> void:
	scene = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	enemy = scene.get_node("Enemy")
	player.camera_rig.set_capture(true)
	enemy.set_physics_process(false)
	await frames(20)
	check(player.is_on_floor(), "office spawn settles safely beside the workstation")
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var clear_floor: bool = true
	for x in [-3, 0, 3]:
		for z in [-10, -5, 0, 5, 8]:
			var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(x, 2, z), Vector3(x, -1, z), 1)
			var hit: Dictionary = space.intersect_ray(query)
			if hit.is_empty() or absf(hit.position.y) > .05:
				clear_floor = false
	check(clear_floor, "central combat lane has continuous floor and no collision clutter")
	var desk_ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(-9, 2, 5), Vector3(-9, .1, 5), 1)
	check(not space.intersect_ray(desk_ray).is_empty(), "workstation has world collision")
	var starting_desk: Node3D = scene.get_node("OfficeAfterHours/YourWorkstation")
	var desk_surface: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-2.5, 2, 9.4), Vector3(-2.5, .1, 9.4), 1))
	check(not desk_surface.is_empty() and absf(desk_surface.position.y - .8225) < .002,
		"polished desk retains the starting workstation collision height")
	var bounds: AABB
	var first_mesh: bool = true
	for node in starting_desk.get_node("DetailedDesk").find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = node
		var box: AABB = starting_desk.global_transform.affine_inverse() * mesh_node.global_transform * mesh_node.get_aabb()
		bounds = box if first_mesh else bounds.merge(box)
		first_mesh = false
	check(not first_mesh and absf(bounds.end.y - .8225) < .003 and bounds.size.x < 2.251 and bounds.size.z < .951,
		"imported desk surface aligns with its collision and stays inside the existing footprint")
	check(scene.find_children("DetailedDesk", "", true, false).size() == 1,
		"the asset trial upgrades only the engineer's workstation")

	await setup_pair(Vector3(0, .05, 0))
	player.position = Vector3(3, .05, -5)
	await frames(5)
	Input.action_press("move_right")
	player.request_dodge()
	await frames(36)
	Input.action_release("move_right")
	check(player.position.x < 4.7 and player.position.x > 4, "dodge stops at the conference deck boundary")
	player.camera_rig.rotation.y = PI / 2
	await frames(10)
	check(player.camera_rig.spring_arm.get_hit_length() < 2, "camera retracts beside conference geometry")

	await setup_pair(Vector3(-7.7, .05, 7.2))
	player.position = Vector3(-7.7, .05, 1.8)
	player.max_health = 1000
	player.health = 1000
	enemy.set_physics_process(true)
	await frames(420)
	check(enemy.global_position.distance_to(player.global_position) < 2.2, "enemy routes around workstation cluster and reaches player")

	await setup_pair(Vector3(2, .05, -5))
	player.position = Vector3(8, 1.55, -5)
	player.health = 1000
	enemy.set_physics_process(true)
	await frames(720)
	check(enemy.position.y > 1.4 and enemy.position.distance_to(player.position) < 2.2, "enemy reaches conference floor through ramp and doorway")

	# Baseline after one reset: transient combat effects from the chase are cleared by it.
	scene.reset_encounter()
	await frames(2)
	var count: int = scene.find_children("*", "", true, false).size()
	for index in range(10):
		scene.reset_encounter()
		await frames(2)
	check(scene.find_children("*", "", true, false).size() == count, "office and navigation do not accumulate nodes on reset")
	check(enemy.position.distance_to(enemy.spawn_position) < .5, "reset restores enemy to the open arena")
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)
