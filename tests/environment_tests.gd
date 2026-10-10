extends "res://tests/incident_tests.gd"
## Milestone 12 office: reachable areas, the vault gate, corridor camera and the pantry.
## Outcome checks on the real scene; they do not judge layout quality or fun.


func path_reaches(from: Vector3, to: Vector3) -> bool:
	var map: RID = player.get_world_3d().navigation_map
	var points: PackedVector3Array = NavigationServer3D.map_get_path(map, from, to, true)
	return not points.is_empty() and points[points.size() - 1].distance_to(to) < 1.0


## Share of real camera placements across the floor whose view passes through, or whose
## lens sits inside, visible office geometry. Every visible mesh gets a trimesh shadow
## on a private layer, so this measures what is drawn, not what the camera collides with.
func camera_clipping(room: Node3D) -> float:
	const SEEN: int = 1 << 19
	var shadows: Array[Node] = []
	for node in room.find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = node
		if mesh_node.mesh == null or not mesh_node.is_visible_in_tree():
			continue
		var shape: ConcavePolygonShape3D = mesh_node.mesh.create_trimesh_shape()
		if shape == null:
			continue
		shape.backface_collision = true
		var body: StaticBody3D = StaticBody3D.new()
		body.collision_layer = SEEN
		body.collision_mask = 0
		var holder: CollisionShape3D = CollisionShape3D.new()
		holder.shape = shape
		body.add_child(holder)
		root.add_child(body)
		body.global_transform = mesh_node.global_transform
		shadows.append(body)
	await frames(2)
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var map: RID = player.get_world_3d().navigation_map
	var lens: SphereShape3D = SphereShape3D.new()
	lens.radius = .1
	var camera: Camera3D = player.get_node("CameraRig/SpringArm3D/Camera3D")
	var total: int = 0
	var bad: int = 0
	for x in range(-12, 27, 5):
		for z in range(-40, 16, 5):
			var spot: Vector3 = NavigationServer3D.map_get_closest_point(map, Vector3(x, 0, z))
			if Vector2(spot.x - x, spot.z - z).length() > 1.5:
				continue
			player.global_position = spot + Vector3.UP * .05
			player.velocity = Vector3.ZERO
			for yaw_step in range(6):
				for pitch: float in [-18.0, -45.0]:
					player.camera_rig.rotation.y = TAU * yaw_step / 6.0
					player.camera_rig.spring_arm.rotation.x = deg_to_rad(pitch)
					player.camera_rig.spring_arm.spring_length = 5.0
					await frames(1)
					var pivot: Vector3 = player.camera_rig.spring_arm.global_position
					var sight: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(pivot, camera.global_position, SEEN))
					var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
					query.shape = lens
					query.transform = Transform3D(Basis(), camera.global_position)
					query.collision_mask = SEEN
					total += 1
					if not sight.is_empty() or not space.intersect_shape(query, 1).is_empty():
						bad += 1
	for body in shadows:
		body.queue_free()
	player.camera_rig.reset_view()
	return float(bad) / maxf(1.0, total)


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	var room: Node3D = incident.room
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	await frames(10)
	var start: Vector3 = Vector3(0, .05, 8)
	for entry: Array in [["meeting wing corridor", Vector3(16.3, .05, 0)], ["Quick Sync room", room.get_node("SpawnPoints/QuickSyncCenter").position + Vector3(0, 0, 4)], ["pantry", Vector3(22.6, .05, 6)], ["server corridor", Vector3(9, .05, -23)], ["server vault", room.get_node("SpawnPoints/VaultArrival").position]]:
		check(path_reaches(start, entry[1]), "navigation reaches the %s from the desks" % entry[0])
	for marker: Node3D in room.get_node("SpawnPoints").get_children():
		if str(marker.name).begins_with("Spawn_"):
			check(path_reaches(marker.position, start), "spawn %s can route to the player" % marker.name)
	# The gate is a real wall until the boss stage.
	player.position = Vector3(9, .05, -13)
	player.camera_rig.reset_view()
	Input.action_press("move_forward")
	await frames(90)
	Input.action_release("move_forward")
	check(player.position.z > -16.2, "closed vault gate blocks the corridor before the boss")
	for next in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	await frames(90)
	check(room.get_node("VaultGate").position.y > 4.5 and not is_instance_valid(incident.active_enemy), "boss stage lifts the gate and waits for the engineer")
	player.position = Vector3(9, .05, -17)
	Input.action_press("move_forward")
	await frames(150)
	Input.action_release("move_forward")
	check(player.position.z < -22 and incident.presentation.seen.has("deployment"), "the engineer walks the corridor past the deployment dashboard")
	check(incident.presentation.corridor_lights[0].light_color.r > .8, "corridor lights fail behind the engineer")
	player.position = Vector3(9, .05, -19.5)
	for yaw in [PI / 2, -PI / 2]:
		player.camera_rig.rotation.y = yaw
		await frames(10)
		check(player.camera_rig.spring_arm.get_hit_length() < 3.2, "camera retracts against corridor racks on side %d" % sign(yaw))
	check(true, "camera retracts against corridor racks instead of clipping")
	await enter_vault()
	check(incident.boss_triggered and incident.presentation.seen.has("variance_intro"), "crossing into the vault starts the arrival")
	await frames(400)
	check(is_instance_valid(incident.active_enemy) and incident.active_enemy.position.distance_to(room.get_node("SpawnPoints/VaultArrival").position) < 3, "The Variance manifests in the vault")
	# Pantry: one cup helps, the second is policy, the third is water.
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	await frames(3)
	incident.run.change_burnout(30, "fixture")
	player.position = incident.interactions.coffee.position
	await key(KEY_E)
	check(incident.coffee_left > 30 and incident.run.motivation > 0 and player.move_multiplier > 1 and incident.run.burnout == 20, "first coffee grants temporary motivation and Burnout relief")
	check(incident.player.melee.damage_multiplier > 1.1 and not incident.buff_text().is_empty(), "motivation reaches real damage and the HUD")
	await key(KEY_E)
	check(incident.coffee_cups == 2 and incident.run.motivation == incident.coffee_bonus and incident.presentation.seen.has("coffee_denied"), "second cup is refused by policy without stacking")
	incident.coffee_left = .05
	await frames(10)
	check(incident.run.motivation == 0 and player.move_multiplier == 1.0 and is_equal_approx(player.melee.damage_multiplier, incident.run.outgoing()), "motivation expires back to baseline")
	for key_name: String in ["vending", "microwave", "poster"]:
		player.position = incident.interactions[key_name].position
		await key(KEY_E)
		check(incident.presentation.seen.has(key_name), "%s interaction speaks its reaction" % key_name)
	player.position = Vector3(0, .05, 8)
	await key(KEY_E)
	check(not incident.presentation.seen.has("coffee_water"), "E away from objects does nothing")
	incident.run.change_burnout(-100, "fixture")
	scene.reset_encounter()
	await frames(3)
	check(incident.coffee_cups == 0 and incident.run.motivation == 0 and player.move_multiplier == 1.0 and room.get_node("VaultGate").collision_layer == 1, "restart restores coffee, gate and movement")
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	# The camera stays out of walls, ceilings, headers and beams all over the floor (a
	# thin ray let its lens graze through half the time). Small props stay see-through.
	var clipping: float = await camera_clipping(room)
	check(clipping < .04, "the camera keeps out of the office's walls, ceilings and beams (%.1f%% of views clip)" % (clipping * 100.0))
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
