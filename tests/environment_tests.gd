extends "res://tests/incident_tests.gd"
## Milestone 12 office: reachable areas, the vault gate, corridor camera and the pantry.
## Outcome checks on the real scene; they do not judge layout quality or fun.


func path_reaches(from: Vector3, to: Vector3) -> bool:
	var map: RID = player.get_world_3d().navigation_map
	var points: PackedVector3Array = NavigationServer3D.map_get_path(map, from, to, true)
	return not points.is_empty() and points[points.size() - 1].distance_to(to) < 1.0


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
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
