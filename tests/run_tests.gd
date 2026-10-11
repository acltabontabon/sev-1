extends SceneTree
## Integration checks run real CharacterBody3D motion against the test room.

var failures: int = 0
var player: CharacterBody3D
var rig: Node3D


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func release_actions() -> void:
	for action in ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump"]:
		Input.action_release(action)


func reset_at(position: Vector3 = Vector3(0, 0.05, 8)) -> void:
	release_actions()
	player.reset_player()
	player.global_position = position
	rig.set_capture(true)
	await frames(15)


func _run() -> void:
	var scene: Node = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	rig = player.get_node("CameraRig")
	# Locomotion regression tests isolate the room from the new opponent.
	scene.get_node("Enemy").process_mode = Node.PROCESS_MODE_DISABLED
	scene.get_node("Enemy").collision_layer = 0
	rig.set_capture(true)
	await frames(30)
	check(player.is_on_floor(), "player spawns on the floor")

	await reset_at()
	var origin: Vector3 = player.position
	Input.action_press("move_forward")
	await frames(60)
	var walk_distance: float = origin.distance_to(player.position)
	check(walk_distance > 4.0 and walk_distance < 5.3, "walk moves about five meters per second")
	release_actions()
	await frames(20)
	check(Vector2(player.velocity.x, player.velocity.z).length() < 0.01, "release stops horizontal motion")

	await reset_at()
	origin = player.position
	Input.action_press("move_forward")
	Input.action_press("move_right")
	await frames(60)
	check(origin.distance_to(player.position) < walk_distance * 1.12, "diagonal input does not increase speed")

	await reset_at()
	origin = player.position
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await frames(60)
	check(origin.distance_to(player.position) > walk_distance * 1.4, "sprint is faster than walking")

	await reset_at()
	rig.rotation.y = PI / 2.0
	Input.action_press("move_forward")
	await frames(30)
	check(player.position.x < -1.5 and absf(player.position.z - 8.0) < 0.1, "forward follows camera yaw")

	await reset_at()
	Input.action_press("jump")
	await frames(1)
	Input.action_release("jump")
	await frames(16)
	check(player.position.y > 0.6, "jump leaves the ground")
	await frames(70)
	check(player.is_on_floor() and absf(player.position.y) < 0.1, "jump lands back on floor")

	await reset_at(Vector3(4.5, 0.05, -14))
	Input.action_press("move_forward")
	await frames(60)
	check(player.position.z > -15.5 and player.position.z < -15.0, "solid wall blocks the player")

	await reset_at(Vector3(0, 0.05, -12))
	Input.action_press("move_forward")
	await frames(60)
	check(player.position.z > -13.8 and player.position.z < -13.4, "Operations console blocks walking before the visible cabinet")

	await reset_at(Vector3(8, 0.05, 4))
	Input.action_press("move_forward")
	await frames(160)
	check(player.position.y > 1.4 and player.is_on_floor(), "player climbs ramp and stays on raised deck")

	await reset_at(Vector3(0, 0.05, 14))
	var arm: SpringArm3D = rig.get_node("SpringArm3D")
	await frames(10)
	check(arm.get_hit_length() < 2.0, "camera retracts before the rear wall")
	rig.orbit(Vector2(0, 100000))
	check(arm.rotation.x >= deg_to_rad(-65.01), "camera downward pitch is bounded")
	rig.orbit(Vector2(0, -100000))
	check(arm.rotation.x <= deg_to_rad(25.01), "camera upward pitch is bounded")

	await reset_at()
	rig.set_capture(false)
	origin = player.position
	Input.action_press("move_forward")
	await frames(30)
	check(player.position.distance_to(origin) < 0.05, "released mouse disables movement input")
	release_actions()

	rig.set_capture(true)
	player.position.y = -10.0
	await frames(10)
	check(player.position.distance_to(player.spawn_position) < 0.2, "falling out resets to spawn")
	for index in range(10):
		player.reset_player()
		await frames(2)
	check(player.position.distance_to(player.spawn_position) < 0.2, "ten resets preserve a usable spawn")
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
