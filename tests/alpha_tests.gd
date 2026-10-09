extends "res://tests/combat_tests.gd"
## Exercise outcomes in the real scene; reuse only the existing test harness.

var death_count: int = 0
var hit_count: int = 0


func _count_death() -> void:
	death_count += 1


func _count_hit() -> void:
	hit_count += 1


func _run() -> void:
	scene = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	enemy = scene.get_node("Enemy")
	check(enemy.health == 180, "alpha opponent starts with the configured encounter health")
	enemy.max_health = 1000
	player.hitstop_enabled = false
	player.hit_confirmed.connect(_count_hit)
	player.died.connect(_count_death)

	await setup_pair()
	player.request_attack()
	await frames(18)
	check(player.request_attack(), "late first-swing input is accepted into the buffer")
	await frames(15)
	check(player.combo_index == 1 and player.melee.attacking, "buffer starts the reverse slash after recovery")
	await frames(18)
	check(player.request_attack(), "reverse slash accepts the finisher buffer")
	await frames(65)
	check(enemy.health == 900 and hit_count == 3, "three distinct swings deal 25 + 30 + 45 exactly once each")
	check(not player.melee.attacking and player.combo_index == -1, "finisher ends the chain without automatic looping")

	await setup_pair()
	player.request_attack()
	check(not player.request_attack(), "early duplicate press cannot queue an entire combo")
	await frames(65)
	check(enemy.health == 975, "one press never produces extra combo hits")
	player.request_attack()
	check(player.combo_index == 0, "expired link window starts at slash one")

	await setup_pair()
	player.request_attack()
	await frames(18)
	player.request_attack()
	check(player.request_dodge() and not player.melee.attacking, "dodge cancels recovery and its queued combo")
	await frames(65)
	check(enemy.health == 975 and player.combo_index == -1, "canceled combo cannot resume later")

	await setup_pair(Vector3(10, 0.05, 5))
	player.request_attack()
	check(player.request_dodge(), "dodge can cancel attack wind-up")
	await setup_pair(Vector3(10, 0.05, 5))
	player.request_attack()
	await frames(9)
	check(player.melee.is_active() and not player.request_dodge(), "active strike is committed and cannot be dodge-canceled")

	await setup_pair(Vector3(10, 0.05, 5))
	var origin: Vector3 = player.position
	check(player.request_dodge() and player.dodge_is_invulnerable(), "dodge invulnerability starts immediately by default")
	check(not player.receive_damage(20, enemy.position), "damage is rejected inside dodge invulnerability")
	check(not player.request_dodge() and not player.request_attack(), "dodge cannot chain itself or attack during travel")
	await frames(12)
	check(not player.dodge_is_invulnerable() and player.dodging, "invulnerability ends before dodge travel and recovery finish")
	check(not player.request_dodge(), "recovery prevents continuous invulnerable dodges")
	await frames(24)
	check(absf(player.position.z - origin.z - player.dodge_distance) < 0.08, "stationary dodge travels three meters backward")
	check(not player.dodging and player.request_attack(), "attack becomes available after dodge recovery")

	await setup_pair(Vector3(10, 0.05, 5))
	player.request_dodge()
	await frames(13)
	check(player.receive_damage(20, enemy.position), "late dodge recovery can take damage")
	check(player.visual.scale.is_equal_approx(Vector3.ONE), "damage clears the dodge presentation")

	await setup_pair(Vector3(10, 0.05, 5))
	player.dodge_invulnerability_start = 0.05
	player.request_dodge()
	check(not player.dodge_is_invulnerable(), "configured invulnerability delay is respected")
	await frames(4)
	check(player.dodge_is_invulnerable(), "delayed invulnerability opens at its configured time")
	player.dodge_invulnerability_start = 0.0

	await setup_pair(Vector3(10, 0.05, 5))
	origin = player.position
	Input.action_press("move_right")
	player.request_dodge()
	Input.action_release("move_right")
	await frames(36)
	check(absf(player.position.x - origin.x - 3.0) < 0.08 and absf(player.position.z - origin.z) < 0.08, "directional dodge uses camera-relative input and locks travel direction")

	for tick_rate in [30, 120]:
		Engine.physics_ticks_per_second = tick_rate
		await setup_pair(Vector3(10, 0.05, 5))
		origin = player.position
		player.request_dodge()
		await frames(tick_rate)
		check(absf(player.position.z - origin.z - 3.0) < 0.08, "dodge distance is stable at %d physics Hz" % tick_rate)
	Engine.physics_ticks_per_second = 60

	await setup_pair(Vector3(10, 0.05, 5))
	player.position = Vector3(0, 0.05, 15)
	await frames(4)
	player.request_dodge()
	await frames(36)
	check(player.position.z < 15.5, "dodge cannot tunnel through the room wall")

	await setup_pair(Vector3(10, 0.05, 5))
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_Q
	key.pressed = true
	Input.parse_input_event(key)
	await frames(2)
	check(player.dodging, "Q input starts dodge")
	key = InputEventKey.new()
	key.physical_keycode = KEY_Q
	Input.parse_input_event(key)
	await setup_pair(Vector3(10, 0.05, 5))
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await frames(2)
	check(player.dodging, "right mouse input starts dodge")
	mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	Input.parse_input_event(mouse)

	await setup_pair(Vector3(0, 0.05, 3.5))
	enemy.set_physics_process(true)
	await frames(30)
	player.request_dodge()
	await frames(20)
	check(player.health == 100, "timed dodge avoids the live enemy attack")
	check(enemy.state == enemy.State.RECOVER, "enemy enters a readable recovery state")

	await setup_pair()
	player.hitstop_enabled = true
	player.request_attack()
	await frames(8)
	var attack_time: float = player.melee.elapsed
	await frames(1)
	check(player.melee.elapsed == attack_time and player.hitstop_left > 0, "impact briefly freezes the swing without global time scaling")
	check(Engine.time_scale == 1.0, "hit-stop leaves global time scale untouched")
	await frames(12)
	check(player.melee.elapsed > attack_time, "hit-stop always releases")

	await setup_pair()
	player.receive_damage(100, enemy.position)
	player.receive_damage(100, enemy.position)
	check(death_count == 1, "player death is emitted exactly once")
	var node_count: int = scene.find_children("*", "", true, false).size()
	var connection_count: int = player.died.get_connections().size()
	for index in range(10):
		scene.reset_encounter()
		player.camera_rig.set_capture(true)
		await frames(3)
		player.request_dodge()
		enemy.show_impact(Color.WHITE)
		enemy.apply_hitstop(0.08)
		scene.reset_encounter()
	check(scene.find_children("*", "", true, false).size() == node_count, "ten resets do not accumulate enemies or effects")
	check(player.died.get_connections().size() == connection_count, "ten resets preserve signal connection count")
	check(not player.dodging and player.combo_buffer_left == 0 and player.hitstop_left == 0 and enemy.hitstop_left == 0, "reset clears dodge, buffer, and hit-stop")
	check(not enemy.get_node("ImpactSparks").visible and not player.dodge_aura.visible, "reset clears sparks and invulnerability visuals")
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)
