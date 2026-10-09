extends "res://tests/incident_tests.gd"


func decision_fixture() -> void:
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	incident._enter(incident.Stage.ENCOUNTER_ONE)
	incident._enter(incident.Stage.INVESTIGATION)
	player.position = incident.CONSOLE_POSITION
	incident.inspect_console()
	incident.choose_system(3)


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	var run: Node = incident.run
	var base_nodes: int = scene.find_children("*", "", true, false).size()
	check(run.burnout == 0 and run.burnout_band() == 0, "fresh run is composed")
	player.camera_rig.set_capture(true)
	await frames(60)
	check(run.burnout == 0, "elapsed time alone creates no burnout")
	player.receive_damage(5, Vector3.ZERO)
	check(run.burnout == 0, "minor accepted hit creates no burnout")
	player.invulnerable_left = 0
	player.receive_damage(20, Vector3.ZERO)
	check(run.burnout == 8 and player.health == 75, "meaningful accepted hit adds eight once")
	player.receive_damage(20, Vector3.ZERO)
	check(run.burnout == 8 and player.health == 75, "rejected repeat hit adds neither damage nor burnout")
	for value in [0, 29, 30, 69, 70, 100]:
		scene.reset_encounter()
		run.change_burnout(value, "Boundary fixture")
		run.apply_to(player)
		run.apply_to(player)
		var expected_band: int = 0 if value < 30 else (1 if value < 70 else 2)
		check(run.burnout_band() == expected_band, "burnout boundary %d" % value)
		var damages: Array[int] = [25, 28, 31]
		player.melee.configure(player.combo[0])
		check(player.melee.effective_damage() == damages[expected_band], "outgoing damage rounds once at %d" % value)
		player.receive_damage(20, Vector3.ZERO)
		var incoming: Array[int] = [20, 22, 25]
		check(player.health == 100 - incoming[expected_band], "accepted incoming damage uses pre-hit band at %d" % value)
		check(run.debt == 0 and player.dodge_recovery_multiplier == 1, "burnout leaves debt and dodge unchanged")
	scene.reset_encounter()
	run.change_burnout(1000, "Clamp")
	check(run.burnout == 100, "burnout clamps to configured maximum")
	run.change_burnout(-1000, "Clamp")
	check(run.burnout == 0, "recovery cannot make burnout negative")
	# Combined upgrade/burnout damage goes through the actual melee hit path.
	player.camera_rig.set_capture(true)
	run.select(0)
	run.select(0)
	run.change_burnout(70, "Combined")
	run.apply_to(player)
	incident._enter(incident.Stage.ENCOUNTER_ONE)
	incident._spawn()
	var foe: CharacterBody3D = incident.active_enemy
	foe.position = Vector3(0, .05, 3.4)
	foe.set_physics_process(false)
	player.position = Vector3(0, .05, 5)
	await frames(5)
	var hp: int = foe.health
	await key(KEY_F)
	await frames(40)
	check(hp - foe.health == 49, "two damage upgrades plus overload deal one additive 49-point slash")
	check(run.debt == 60 and run.outgoing() <= 2 and run.incoming() <= 1.25, "combined systems remain bounded and independent")
	scene.reset_encounter()
	run.select(1)
	run.select(1)
	run.change_burnout(70, "Defense")
	run.apply_to(player)
	player.receive_damage(20, Vector3.ZERO)
	check(player.health == 83, "two defense upgrades plus overload yield 17 incoming damage")
	for choice in range(3):
		decision_fixture()
		run.change_burnout(40, "Fixture")
		run.apply_to(player)
		var elapsed_before: float = incident.elapsed
		await frames(120)
		player.camera_rig.set_capture(true)
		check(paused and incident.elapsed == elapsed_before and not is_instance_valid(incident.active_enemy), "decision freezes encounter and blocks capture")
		incident.choose_corporate(-1)
		check(incident.decision_pending, "invalid decision leaves modal pending")
		await key([KEY_1, KEY_2, KEY_3][choice])
		incident.choose_corporate(choice)
		var expected: Array[int] = [75, 48, 20]
		check(run.burnout == expected[choice] and incident.corporate_choice == choice and run.debt == 0, "choice %d applies once without debt" % choice)
		check(not paused and not incident.modal_pending() and not incident.upgrade_ui.panel.visible, "selection closes modal and resumes")
		check(incident.remaining == (4 if choice == 2 else 3), "dependency only adds one containment record")
		player.max_health = 10000
		player.health = 10000
		await defeat_wave()
		check(incident.upgrade_pending and paused, "containment still reaches second upgrade")
		var recovered: int = run.burnout
		incident._on_record_died(incident.actors.back())
		check(run.burnout == recovered, "stale death cannot apply recovery twice")
		check(run.burnout == expected[choice] - (35 if choice == 0 else 15), "containment gives single recovery and earned commitment bonus")
		await key(KEY_2)
		incident._spawn()
		var boss: CharacterBody3D = incident.active_enemy
		boss.exposed = true
		boss.receive_damage(10000, player.position)
		check(incident.terminal() and paused and incident.corporate_title() in incident.report and "Burnout:" in incident.report, "every corporate path reaches victory with truthful summary")
	decision_fixture()
	await frames(3)
	var button: Button = incident.upgrade_ui.buttons[2]
	var point: Vector2 = button.get_global_rect().get_center()
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await frames(2)
	for pressed in [true, false]:
		var click: InputEventMouseButton = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = point
		click.pressed = pressed
		root.push_input(click, true)
		await frames(2)
	check(incident.corporate_choice == 2 and not paused and incident.remaining == 4, "real mouse selects corporate dependency card and resumes")
	incident.remaining = 1
	incident._spawn()
	check("DEPENDENCY RETURNED" in incident.active_enemy.get_node("RecordMarker").text, "extra dependency record has an observable identity")
	decision_fixture()
	incident.upgrade_ui.buttons[1].grab_focus()
	await key(KEY_ENTER)
	check(incident.corporate_choice == 1 and not paused, "Enter selects focused corporate card")
	decision_fixture()
	await key(KEY_1)
	player.camera_rig.set_capture(false)
	var time_before: float = incident.challenge_left
	await frames(120)
	check(incident.challenge_left == time_before, "commitment clock stops on pause")
	player.camera_rig.set_capture(true)
	incident.challenge_left = .05
	await frames(10)
	check(incident.challenge_result == "Expired — no penalty" and run.burnout == 35, "expiry has no damage or burnout penalty")
	await defeat_wave()
	check(run.burnout == 20, "expired commitment earns only standard recovery")
	await key(KEY_R)
	check(run.burnout == 0 and incident.corporate_choice == -1 and incident.challenge_left == 0, "restart clears burnout, decision, and challenge")
	for index in range(3):
		decision_fixture()
		await key(KEY_R)
		await frames(3)
		check(not incident.modal_pending() and not incident.upgrade_ui.panel.visible and run.burnout == 0, "restart from decision clears modal")
		check(scene.find_children("*", "", true, false).size() == base_nodes, "retries retain bounded nodes")
	check(player.damage_accepted.get_connections().size() == 1 and incident.upgrade_ui.selected.get_connections().size() == 1, "retry does not duplicate damage or modal subscriptions")
	decision_fixture()
	await key(KEY_1)
	player.invulnerable_left = 0
	player.receive_damage(100000, Vector3.ZERO)
	check(incident.stage == incident.Stage.FAILED and paused and incident.challenge_result == "Interrupted", "defeat ends challenge and opens report")
	scene.queue_free()
	paused = false
	await frames(3)
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	check(scene.get_node("Incident").run.burnout == 0 and scene.get_node("Incident").corporate_choice == -1, "fresh scene has no stale corporate state")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
