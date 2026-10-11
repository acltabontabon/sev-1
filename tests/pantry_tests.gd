extends "res://tests/incident_tests.gd"
## Real E interactions, harmless repeat visits, pause, expiry and retry.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	incident._cleanup()
	await frames(3)
	var pantry: Node3D = incident.room.get_node("PantryAntics")
	var map: RID = player.get_world_3d().navigation_map
	var route: PackedVector3Array = NavigationServer3D.map_get_path(map, Vector3(16.3, 0, 8.5), Vector3(22.5, 0, 14), true)
	check(not route.is_empty() and route[route.size() - 1].distance_to(Vector3(22.5, 0, 14)) < 1.0, "navigation reaches the expanded back of the pantry")
	player.camera_rig.reset_view()
	player.position = Vector3(16.3, .05, 8.5)
	Input.action_press("move_right")
	await frames(80)
	Input.action_release("move_right")
	check(player.position.x > 20.0, "the engineer walks through the wider pantry doorway")
	player.position = Vector3(22.5, .05, 8.5)
	player.velocity = Vector3.ZERO
	var before_dodge: Vector3 = player.position
	check(player.request_dodge(), "the engineer can dodge in the open pantry centre")
	await frames(30)
	check(absf(player.position.distance_to(before_dodge) - player.dodge_distance) < .1, "the pantry centre allows a full dodge away from the appliances")
	var node_count: int = pantry.find_children("*", "", true, false).size()
	var health: int = player.health
	var debt: int = incident.run.debt
	var stage: int = incident.stage
	for appliance: String in ["microwave", "vending", "fridge", "poster"]:
		player.position = incident.interactions[appliance].position
		for visit in range(3):
			await key(KEY_E)
			check(pantry.counts.get(appliance, 0) == visit + 1 and pantry.caption.visible, "%s visit %d responds through E" % [appliance, visit + 1])
		check(pantry.caption.text == pantry.LINES[appliance][2], "%s reaches its final authored punchline" % appliance)
		if appliance == "microwave":
			check(pantry.council.visible and not pantry.leftovers.visible, "microwave summons the mug tribunal")
		elif appliance == "fridge":
			check(pantry.leftovers.visible and not pantry.council.visible, "fridge floats the organised leftovers")
		elif appliance == "vending":
			check(pantry.receipt.visible, "vending leaves a visible disappointment receipt")
	check(player.health == health and incident.run.debt == debt and incident.stage == stage, "appliance hauntings do not hurt, charge debt or advance the incident")
	var before: float = pantry.remaining
	paused = true
	await frames(20)
	check(pantry.remaining == before, "pantry antics freeze in pause")
	paused = false
	await frames(450)
	check(not pantry.caption.visible and not pantry.council.visible and not pantry.leftovers.visible, "haunting settles after seven playable seconds")
	check(is_equal_approx(incident.room.get_node("PantryLight").light_energy, pantry.light_energy), "wellness breathing restores the original room light")
	for repeat in range(25):
		incident.use("microwave")
	check(pantry.find_children("*", "", true, false).size() == node_count, "repeat haunting reuses its props without accumulating nodes")
	check(pantry.caption.text == pantry.LINES.microwave[2], "extra presses keep the final punchline bounded")
	scene.reset_encounter()
	check(pantry.counts.is_empty() and not pantry.receipt.visible and not pantry.caption.visible, "restart clears reactions and receipt")
	check(incident.coffee_cups == 0 and player.move_multiplier == 1.0, "retry preserves the coffee and movement baseline")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
