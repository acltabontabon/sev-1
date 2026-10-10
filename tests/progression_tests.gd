extends "res://tests/incident_tests.gd"


func fixture() -> void:
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	incident._enter(incident.Stage.ENCOUNTER_ONE)
	incident._offer_upgrade(incident.Stage.INVESTIGATION)


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	var run: Node = incident.run
	check(run.debt == 0 and run.choices.is_empty(), "new run has zero debt and no upgrades")
	var base_nodes: int = scene.find_children("*", "", true, false).size()
	await fixture()
	var clock_before: float = incident.elapsed
	await frames(180)
	check(paused and incident.elapsed == clock_before and not is_instance_valid(incident.active_enemy), "choice suspends clock and spawns")
	player.camera_rig.set_capture(true)
	check(paused and not player.camera_rig.controls_active, "background capture cannot bypass choice")
	incident.choose_upgrade(-1)
	check(run.choices.is_empty() and incident.upgrade_pending, "invalid choice does nothing")
	await key(KEY_1)
	incident.choose_upgrade(0)
	check(run.choices.size() == 1 and run.debt == 30, "duplicate selection cannot apply twice")
	check(is_equal_approx(run.outgoing(), 1.35), "ship adds 35 percent outgoing damage")
	player.position = Vector3(0, .05, 5)
	incident._enter(incident.Stage.ENCOUNTER_TWO)
	incident._spawn()
	incident._spawn()
	# The containment wave opens with a Blocker; measure the plain record behind it.
	var foe: CharacterBody3D = incident.alive[1]
	# Arithmetic fixture: an engaged foe, so no surprise-review bonus applies.
	foe.engage()
	foe.position = Vector3(0, .05, 3.4)
	foe.set_physics_process(false)
	await frames(5)
	var hp: int = foe.health
	await key(KEY_F)
	await frames(40)
	check(hp - foe.health == 34, "actual upgraded slash deals rounded 34 damage exactly once")
	check(player.combo[0].damage == 25, "shared attack profile stays unchanged")
	check(is_equal_approx(foe.move_speed, 3.57), "fragile next encounter pursues five percent faster")
	check(is_equal_approx(foe.melee.windup, .65) and is_equal_approx(foe.melee.recovery, .85), "debt preserves enemy tell and recovery")
	check("FRAGILE" in scene.get_node("OfficeAfterHours/Impossible").text, "office dashboard shows accumulated debt")
	check(scene.get_node("OfficeAfterHours/IncidentSpill").light_energy > 3.2, "debt raises incident spill without flashing")
	await fixture()
	await frames(3)
	var button: Button = incident.upgrade_ui.buttons[1]
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
	check(not incident.upgrade_pending and run.choices == [1], "real mouse click selects defensive card once")
	player.invulnerable_left = 0
	check(player.receive_damage(20, Vector3.ZERO) and player.health == 84, "tests reduce actual incoming damage to sixteen")
	check(not player.receive_damage(20, Vector3.ZERO) and player.health == 84, "damage invulnerability still rejects repeat damage")
	check(run.debt == 0, "defensive upgrade adds no debt")
	await fixture()
	await key(KEY_3)
	await frames(8)
	check(player.request_dodge(), "upgraded dodge can start")
	await frames(12)
	check(not player.dodge_is_invulnerable() and player.dodging, "upgrade does not extend dodge invulnerability")
	await frames(18)
	check(not player.dodging and is_equal_approx(player.dodge_recovery, .32), "dodge finishes by half second without mutating base recovery")
	check(run.debt == 15, "workaround adds moderate debt")
	for value in [0, 24, 25, 49, 50, 74, 75, 100]:
		run.debt = value
		incident._dashboard("TEST", "TEST")
		check(run.band() == mini(value / 25, 3) and run.pressure() <= 1.15, "debt boundary %d has bounded pressure" % value)
	check("CRITICAL" in scene.get_node("OfficeAfterHours/Impossible").text, "critical environment warning includes text")
	run.select(0)
	check(run.debt == 100, "debt clamps at maximum")
	await fixture()
	await key(KEY_1)
	incident._enter(incident.Stage.ENCOUNTER_TWO)
	incident._offer_upgrade(incident.Stage.BOSS)
	await key(KEY_1)
	check(run.debt == 60 and is_equal_approx(run.outgoing(), 1.7), "two shortcuts add linearly and reach unstable")
	incident._spawn()
	var boss: CharacterBody3D = incident.active_enemy
	check(is_equal_approx(boss.move_speed, 2.64), "unstable boss pursuit has bounded ten percent increase")
	boss.phase_time = 4.6
	await frames(2)
	check(boss.exposed, "upgraded run preserves boss OPEN window")
	boss.receive_damage(10000, player.position)
	check(incident.terminal() and "Ship It Friday" in incident.report and "60" in incident.report, "victory report records choices and debt")
	for index in range(3):
		await key(KEY_R)
		await frames(3)
		check(run.debt == 0 and run.choices.is_empty() and player.melee.damage_multiplier == 1 and player.incoming_damage_multiplier == 1 and player.dodge_recovery_multiplier == 1, "restart clears all run modifiers")
		check(scene.find_children("*", "", true, false).size() == base_nodes, "restart retains bounded nodes and modal")
		check(scene.get_node("OfficeAfterHours/Impossible").text == "TRANSACTIONS: CONSISTENT", "restart clears environmental corruption")
		await fixture()
		await key(KEY_3)
		player.invulnerable_left = 0
		player.receive_damage(10000, Vector3.ZERO)
		check(incident.stage == incident.Stage.FAILED and "Temporary Workaround" in incident.report, "defeat retains truthful run summary")
	await fixture()
	await key(KEY_R)
	check(not incident.upgrade_pending and not incident.upgrade_ui.panel.visible and run.choices.is_empty(), "R during choice closes modal and clears run")
	check(incident.upgrade_ui.selected.get_connections().size() == 1, "restarts do not duplicate selection subscription")
	scene.queue_free()
	paused = false
	await frames(3)
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	check(scene.get_node("Incident").run.debt == 0 and scene.get_node("Incident").run.choices.is_empty(), "fresh scene reload has no run upgrades")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
