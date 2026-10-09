extends SceneTree

var failures: int = 0
var scene: Node3D
var player: CharacterBody3D
var enemy: CharacterBody3D


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


func setup_pair(enemy_position: Vector3 = Vector3(0, 0.05, 3.4)) -> void:
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	player.global_position = Vector3(0, 0.05, 5)
	enemy.set_physics_process(false)
	enemy.global_position = enemy_position
	await frames(10)


func _run() -> void:
	scene = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	enemy = scene.get_node("Enemy")
	check(paused, "encounter starts paused until captured")
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await frames(2)
	check(not paused and not player.melee.attacking, "capture click resumes without also attacking")
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	Input.parse_input_event(click)

	await setup_pair()
	var attack_key: InputEventKey = InputEventKey.new()
	attack_key.physical_keycode = KEY_F
	attack_key.pressed = true
	Input.parse_input_event(attack_key)
	await frames(17)
	check(enemy.health == 75, "F input triggers a real melee hit")
	attack_key = InputEventKey.new()
	attack_key.physical_keycode = KEY_F
	attack_key.pressed = false
	Input.parse_input_event(attack_key)

	await setup_pair()
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await frames(17)
	check(enemy.health == 75, "captured left click triggers a real melee hit")
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	Input.parse_input_event(click)

	await setup_pair()
	check(player.request_attack(), "grounded player can begin a strike")
	check(not player.request_attack(), "another press cannot bypass attack recovery")
	await frames(5)
	check(enemy.health == 100, "wind-up causes no early damage")
	await frames(12)
	check(enemy.health == 75, "active window deals exactly one hit")
	await frames(22)
	check(enemy.health == 75 and not player.melee.attacking, "recovery ends without additional damage")

	await setup_pair(Vector3(0, 0.05, 7))
	player.request_attack()
	await frames(34)
	check(enemy.health == 100, "attack cannot hit behind the player")
	await setup_pair(Vector3(0, 0.05, 1))
	player.request_attack()
	await frames(34)
	check(enemy.health == 100, "attack cannot hit outside reach")
	await setup_pair(Vector3(0, 3, 3.4))
	player.request_attack()
	await frames(34)
	check(enemy.health == 100, "attack cannot hit a target on a different elevation")
	await setup_pair(Vector3(-1.6, 0.05, 5))
	player.camera_rig.rotation.y = PI / 2.0
	player.request_attack()
	await frames(34)
	check(enemy.health == 75, "strike direction follows camera aim")

	await setup_pair()
	var wall: StaticBody3D = StaticBody3D.new()
	var collider: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(3, 2, 0.2)
	collider.shape = shape
	wall.add_child(collider)
	scene.add_child(wall)
	wall.position = Vector3(0, 1, 4.2)
	await frames(2)
	player.request_attack()
	await frames(34)
	check(enemy.health == 100, "world geometry blocks melee damage")
	wall.queue_free()
	await frames(2)

	await setup_pair()
	for index in range(4):
		if index == 3:
			enemy.melee.start()
		player.request_attack()
		await frames(34)
	check(enemy.health == 0 and enemy.collision_layer == 0, "four strikes defeat and disable the enemy")
	check(not enemy.receive_damage(25, player.position), "dead enemy ignores later hits")
	check(not enemy.melee.attacking, "enemy death cancels its pending attack")

	await setup_pair()
	player.receive_damage(20, enemy.position)
	player.receive_damage(20, enemy.position)
	check(player.health == 80, "brief invulnerability rejects repeated damage")
	await frames(45)
	check(player.receive_damage(20, enemy.position) and player.health == 60, "damage resumes after invulnerability expires")

	await setup_pair(Vector3(0, 0.05, 3.5))
	enemy.set_physics_process(true)
	await frames(3)
	check(enemy.melee.attacking and enemy.tell.visible, "enemy announces a committed attack")
	await frames(25)
	check(player.health == 100, "enemy telegraph gives time before damage")
	await frames(18)
	check(player.health == 80, "enemy active window hits once for twenty damage")
	await frames(30)
	check(player.health == 80, "enemy recovery leaves an opening")

	await setup_pair(Vector3(0, 0.05, 3.5))
	enemy.set_physics_process(true)
	await frames(10)
	player.global_position.x = 2.5
	await frames(40)
	check(player.health == 100, "sidestepping the committed attack avoids damage")

	await setup_pair()
	player.request_attack()
	await frames(2)
	player.camera_rig.set_capture(false)
	var elapsed_before: float = player.melee.elapsed
	await frames(40)
	check(is_equal_approx(player.melee.elapsed, elapsed_before) and enemy.health == 100, "pause freezes combat timers and damage")
	player.camera_rig.set_capture(true)

	await setup_pair()
	player.receive_damage(100, enemy.position)
	check(player.health == 0 and paused and not player.request_attack(), "player death stops combat and releases control")
	for index in range(10):
		scene.reset_encounter()
	check(player.health == 100 and enemy.health == 100 and enemy.collision_layer == 4, "ten encounter resets restore health and collision")
	check(not player.melee.attacking and not enemy.melee.attacking, "reset clears both pending attacks")
	check(get_nodes_in_group("enemies").size() == 1, "reset never duplicates the enemy")
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)
