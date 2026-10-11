extends "res://tests/combat_tests.gd"

var incident: Node3D


## Clear every wave of the current stage: each live enemy, then the breather.
func defeat_wave() -> void:
	var original_stage: int = incident.stage
	# Short beats: a crowd left alive would land hits and change Burnout under test.
	for index in range(40):
		if incident.stage != original_stage or incident.modal_pending():
			break
		await frames(40)
		for foe: CharacterBody3D in incident.alive.duplicate():
			if is_instance_valid(foe):
				foe.drop_shield()
				foe.receive_damage(10000, player.position)
		await frames(2)


## Lifecycle fixtures skip the presentation through the same entry as TAB.
func clear_operations() -> void:
	incident.presentation.skip()
	await frames(2)


## The Variance waits in the server vault; staged runs walk in by teleport.
func enter_vault() -> void:
	player.position = Vector3(9, .05, -31.5)
	await frames(3)


func key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	check(paused and incident.stage == incident.Stage.ALERT, "episode starts at Friday paused")
	var base_count: int = scene.find_children("*", "", true, false).size()
	player.camera_rig.set_capture(true)
	player.max_health = 10000
	player.health = 10000
	incident._enter(incident.Stage.BOSS)
	check(incident.stage == incident.Stage.ALERT, "out-of-order transitions are rejected")
	await frames(1800)
	check(incident.alert_played and incident.presentation.desk.alarm_panel.visible and player.narrative_hold, "pager fires on the desk monitor mid-opening while control stays held")
	await frames(1450)
	check(incident.stage == incident.Stage.ENCOUNTER_ONE and is_instance_valid(incident.active_enemy), "first combat starts within fifty-four active seconds")
	check(not player.narrative_hold and player.camera_rig.get_node("SpringArm3D/Camera3D").current and scene.get_node("HUD").visible, "unskipped opening hands camera, input and HUD to the player")
	check(not incident.presentation.emerging.visible and incident.room.get_node("CeilingPool0").light_energy > 1.0, "opening leaves no staged monster and restores combat lighting")
	check(get_nodes_in_group("enemies").size() == 2 + incident.bugs.size() and incident.alive.size() == 2, "lab opponent is disabled and the first wave arrives as a pair")
	check(incident.bugs.size() == 3, "a swarm of three one-hit bugs rushes in beside the first wave")
	var first: CharacterBody3D = incident.active_enemy
	var first_speed: float = first.move_speed
	check(first.position.distance_to(player.position) > 3, "arrival is outside immediate striking distance")
	await defeat_wave()
	check(incident.upgrade_pending and paused, "first wave safely pauses for upgrade")
	await key(KEY_2)
	check(incident.run.choices.size() == 1 and not paused, "keyboard upgrade resumes exactly once")
	check(incident.stage == incident.Stage.INVESTIGATION, "defeating first records opens investigation")
	# Defeated actors are freed after a short corpse beat; a stale signal must be ignored.
	if is_instance_valid(first):
		incident._on_record_died(first)
	check(incident.stage == incident.Stage.INVESTIGATION, "duplicate death cannot advance incident")
	check(not incident.inspected, "the incoming call waits for the engineer to answer")
	player.position = incident.CONSOLE_POSITION
	await frames(5)
	await key(KEY_E)
	check(incident.inspected, "E answers Management near Operations")
	await key(KEY_1)
	await key(KEY_3)
	check(incident.stage == incident.Stage.INVESTIGATION and not incident.decision_pending and incident.mistakes == 0, "number keys cannot solve or bypass Operations")
	await clear_operations()
	check(incident.decision_pending and paused and incident.management_call.completed, "skipping Operations opens management without a system choice")
	await key(KEY_2)
	check(incident.stage == incident.Stage.ENCOUNTER_TWO, "realistic estimate starts containment")
	await frames(150)
	var record: CharacterBody3D = incident.alive.filter(func(foe: CharacterBody3D) -> bool: return foe.speed_scale == 1.0)[0]
	check(record.move_speed > first_speed, "second encounter escalates pursuit only")
	await defeat_wave()
	check(incident.upgrade_pending and paused, "second wave opens second upgrade")
	incident.upgrade_ui.buttons[0].pressed.emit()
	check(incident.run.debt == 0 and incident.run.choices.size() == 2, "button upgrade persists both run decisions")
	check(incident.stage == incident.Stage.BOSS, "second wave completion starts boss")
	await frames(120)
	check(not is_instance_valid(incident.active_enemy) and incident.room.get_node("VaultGate").collision_layer == 0, "boss stage opens the gate and waits for the engineer")
	await enter_vault()
	await frames(400)
	var boss: CharacterBody3D = incident.active_enemy
	check(boss.max_health == incident.boss_health, "boss health is configured separately")
	boss.phase_time = 0
	await frames(2)
	var before: int = boss.health
	check(not boss.receive_damage(100, player.position) and boss.health == before, "shielded boss rejects damage")
	boss.phase_time = 4.6
	await frames(2)
	check(boss.exposed and "OPEN" in boss.marker.text, "vulnerability window has explicit visible cue")
	player.position = Vector3(0, .05, 5)
	boss.position = Vector3(0, .05, 3.4)
	boss.set_physics_process(false)
	player.camera_rig.reset_view()
	before = boss.health
	await key(KEY_F)
	await frames(17)
	check(boss.health < before, "real F melee strike damages the exposed boss")
	boss.set_physics_process(true)
	check(boss.receive_damage(360, player.position), "open original accepts meaningful damage")
	check(incident.copies.all(func(copy: Node3D) -> bool: return not copy.is_in_group("enemies")), "false projections cannot absorb real damage")
	check(incident.copies.size() == 2, "half health produces two bounded false copies")
	incident._make_copies()
	check(incident.copies.size() == 2, "repeated clone request cannot duplicate copies")
	check("◆" in boss.marker.text, "original keeps learnable solid-shape tell")
	boss.receive_damage(10000, player.position)
	await frames(2)
	check(incident.stage == incident.Stage.RESOLVED and paused, "boss defeat resolves and pauses incident")
	check(incident.copies.is_empty(), "victory removes all false copies")
	check("engineering contributors: 1" in incident.report, "victory uses handcrafted report")
	await frames(180)
	check(scene.get_node("OfficeAfterHours/IncidentSpill").light_energy < 1, "recovery subsides incident lighting")
	player.camera_rig.set_capture(true)
	check(paused, "click cannot resume combat after report")
	await key(KEY_R)
	await frames(3)
	check(incident.stage == incident.Stage.ALERT and incident.elapsed == 0, "R restarts from terminal while paused")
	check(scene.find_children("*", "", true, false).size() == base_count, "reset frees spawned actors and clones")
	check(incident.mistakes == 0 and not incident.inspected, "investigation state resets")
	check(is_equal_approx(scene.get_node("OfficeAfterHours/IncidentSpill").light_energy, .6), "environment resets exactly")
	player.camera_rig.set_capture(true)
	await frames(580)
	player.invulnerable_left = 0
	player.receive_damage(100000, Vector3.ZERO)
	await frames(2)
	check(incident.stage == incident.Stage.FAILED and paused, "player death enters failure and pauses")
	check("Due date: Yesterday" in incident.report, "death report assigns satirical corrective action")
	check(not incident.active_enemy.melee.attacking, "death cancels active hostile attack")
	for index in range(5):
		scene.reset_encounter()
		await frames(2)
		player.camera_rig.set_capture(true)
		await frames(580)
		check(get_nodes_in_group("enemies").filter(func(node: Node) -> bool: return node.health > 0 and not incident.bugs.has(node)).size() == 2, "restart creates exactly the first wave")
		scene.reset_encounter()
		player.camera_rig.set_capture(false)
		await frames(2)
	check(scene.find_children("*", "", true, false).size() == base_count, "repeated mid-fight resets retain stable node count")
	check(player.died.get_connections().size() == 1, "restarts do not add death subscriptions")
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	for next in [incident.Stage.ENCOUNTER_ONE, incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	incident._spawn()
	incident.active_enemy.exposed = true
	incident.active_enemy.receive_damage(360, player.position)
	check(incident.copies.size() == 2, "death fixture includes active copies")
	player.invulnerable_left = 0
	player.receive_damage(100000, Vector3.ZERO)
	await frames(2)
	check(incident.stage == incident.Stage.FAILED and incident.copies.is_empty(), "death during false positives removes projections")
	scene.queue_free()
	paused = false
	await frames(3)
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(3)
	check(scene.get_node("Incident").stage == 0 and get_nodes_in_group("enemies").is_empty(), "fresh scene load has no stale encounter state")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
