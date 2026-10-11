extends "res://tests/incident_tests.gd"


func fixture() -> void:
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	incident._enter(incident.Stage.ENCOUNTER_ONE)
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	player.position = incident.CONSOLE_POSITION


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	fixture()
	player.position = incident.interactions.coffee.global_position
	await key(KEY_E)
	check(incident.coffee_cups == 1 and not incident.management_call.active, "the pending call preserves E for nearby pantry interactions")
	player.position = Vector3(0, .05, 5)
	var answered_at: Vector3 = player.position
	await frames(10)
	await key(KEY_E)
	var machine: Node3D = incident.management_call
	check(machine.active and player.narrative_hold and machine.camera.current and not scene.get_node("HUD").visible, "E answers from the fight location with no Operations backtracking")
	var count: int = get_nodes_in_group("enemies").size()
	await key(KEY_E)
	await key(KEY_1)
	await key(KEY_3)
	await key(KEY_F)
	check(machine.active and not incident.decision_pending and not player.melee.attacking and get_nodes_in_group("enemies").size() == count, "repeated E and old quiz keys cannot restart or bypass the cutscene; F cannot leak an attack")
	paused = true
	var clock: float = machine.clock
	await frames(120)
	check(machine.clock == clock, "pause freezes the cinematic clock")
	paused = false
	await key(KEY_TAB)
	check(machine.completed and not machine.active and incident.decision_pending and paused, "actual TAB input skips once into the management decision")
	check(player.global_position.distance_to(answered_at) < .1 and not player.narrative_hold and player.get_node("CameraRig/SpringArm3D/Camera3D").current and scene.get_node("HUD").visible, "skip restores the engineer, gameplay camera and HUD")
	incident.choose_corporate(1)
	check(incident.stage == incident.Stage.ENCOUNTER_TWO and not paused, "management still starts containment")
	fixture()
	incident.inspect_console()
	await frames(160)
	check(machine.reveal_spoken and "Source still active" in machine.connection.text, "the engineer reports the failure and gives containment its target")
	await frames(250)
	check(machine.beat == 2 and not machine.manager.is_empty() and "Commitment required" in machine.connection.text, "Management's voiced interruption leads to the commitment decision")
	await frames(450)
	check(machine.completed and incident.decision_pending and get_nodes_in_group("enemies").size() == count, "natural briefing ends directly at the consequential containment choice")
	check("CONTAINMENT REQUEST" in incident.upgrade_ui.eyebrow.text and "extra Blocker" in incident.upgrade_ui.summary(2), "the call explains its purpose and previews the next-fight consequence")
	fixture()
	incident.inspect_console()
	await frames(180)
	scene.reset_encounter()
	await frames(3)
	check(not machine.active and not machine.completed and not machine.overlay.visible and machine.manager.is_empty(), "restart releases Morgan and the call overlay")
	check(player.global_position.distance_to(Vector3(-2.5, .05, 10.8)) < 2, "restart keeps the normal Friday spawn instead of the staged Operations position")
	fixture()
	incident.inspect_console()
	incident.fail()
	await frames(200)
	check(not machine.active and not incident.decision_pending and not machine.overlay.visible, "death cancels the scene without later opening management")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
