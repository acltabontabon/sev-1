extends "res://tests/combat_tests.gd"
## Environment integration: floor, furnishings, camera clearance, and actual pursuit.


func visible_bounds(node: Node3D) -> AABB:
	var box: AABB
	var first: bool = true
	for part in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_part: MeshInstance3D = part
		if mesh_part.mesh == null or not mesh_part.is_visible_in_tree():
			continue
		var bounds: AABB = mesh_part.global_transform * mesh_part.get_aabb()
		box = bounds if first else box.merge(bounds)
		first = false
	return box

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
	check(scene.find_children("DetailedDesk", "", true, false).size() == 8,
		"all eight office workstations share the detailed desk")
	var visual_clear: bool = true
	var combat_lane: AABB = AABB(Vector3(-4, .08, -13), Vector3(8, 2.1, 21))
	for node in scene.get_node("OfficeAfterHours/OfficeFinish").find_children("*", "MeshInstance3D", true, false):
		var detail: MeshInstance3D = node
		if detail.mesh != null and combat_lane.intersects(detail.global_transform * detail.get_aabb()):
			visual_clear = false
	check(visual_clear, "office finish leaves the central fighting lane visually clear")
	var detailed_chairs: Array[Node] = scene.find_children("DetailedChair", "", true, false)
	var chairs_fit: bool = detailed_chairs.size() >= 8
	for node in detailed_chairs:
		var detail: Node3D = node
		var chair: Node3D = detail.get_parent()
		var chair_bounds: AABB
		var first_part: bool = true
		for part in detail.find_children("*", "MeshInstance3D", true, false):
			var mesh_part: MeshInstance3D = part
			var box: AABB = chair.global_transform.affine_inverse() * mesh_part.global_transform * mesh_part.get_aabb()
			chair_bounds = box if first_part else chair_bounds.merge(box)
			first_part = false
		if first_part or absf(chair_bounds.position.y) > .003 or chair_bounds.size.x > .75 \
				or chair_bounds.size.z > .75 or chair_bounds.size.y > 1.10:
			chairs_fit = false
		if not is_equal_approx(chair.get_node("SeatReference").position.y, .56):
			chairs_fit = false
	check(chairs_fit, "detailed chairs sit on the floor and fit the desk bays at the established seated height")
	var room: Node3D = scene.get_node("OfficeAfterHours")
	var lounge_chair: AABB = visible_bounds(room.get_node("Decor/LoungeChairEast"))
	var lounge_clear: bool = true
	for neighbor: String in ["LoungeSofa", "LoungePlantB", "LoungeTV", "LoungeSpeakerB"]:
		lounge_clear = lounge_clear and not lounge_chair.intersects(visible_bounds(room.get_node("Decor/" + neighbor)))
	check(lounge_clear, "relocated lounge chair clears the sofa, plant, screen and speaker")
	var supported: bool = true
	for index in range(6):
		var desk: Node3D = room.get_node("Workstation%d" % index)
		var top: AABB = AABB(desk.position + Vector3(-1.125,.8225,-.475), Vector3(2.25,.01,.95))
		for prefix: String in ["DeskPlant", "DeskBooks"]:
			var prop_bounds: AABB = visible_bounds(room.get_node("Decor/%s%d" % [prefix,index]))
			if absf(prop_bounds.position.y-top.position.y) > .002 or prop_bounds.position.x < top.position.x \
					or prop_bounds.end.x > top.end.x or prop_bounds.position.z < top.position.z or prop_bounds.end.z > top.end.z:
				supported = false
	check(supported, "desk plants and books rest on their tabletops without sinking or overhanging")
	for index in range(2):
		var lamp: AABB = visible_bounds(room.get_node("Decor/DeskLamp%d" % index))
		var desk: Node3D = room.get_node("Workstation%d" % (index*4))
		check(absf(lamp.position.y-.8225) < .002 and lamp.position.x > desk.position.x-1.125 \
			and lamp.end.x < desk.position.x+1.125 and lamp.position.z > desk.position.z-.475 \
			and lamp.end.z < desk.position.z+.475, "desk lamp %d is supported by one desk" % index)
	for index in range(6):
		var box: AABB = visible_bounds(room.get_node("Decor/DeskBox%d" % index))
		var clear: bool = true
		for desk_index in range(6):
			if box.intersects(visible_bounds(room.get_node("Workstation%d/DetailedDesk" % desk_index))):
				clear = false
		check(clear, "supply box %d does not intersect desk drawers" % index)
	# Actual walking must stop at the chair and drawer, not pass through visible art.
	player.camera_rig.reset_view()
	player.position = Vector3(-9,.05,7.5)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	await frames(70)
	Input.action_release("move_forward")
	check(player.position.z > 6.5 and player.position.z < 7.2, "walking stops in front of the office chair")
	player.position = Vector3(-8.15,.05,7)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	await frames(70)
	Input.action_release("move_forward")
	check(player.position.z > 5.75 and player.position.z < 6.3, "walking stops at the desk's drawer pedestal")

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
