extends "res://tests/incident_tests.gd"
## Emergency assistance outcomes on the real crew and engineer, with forced rolls.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	incident.presentation.skip()
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	await frames(3)
	var crew: Node3D = incident.coworkers
	crew.set_process(false)
	player.set_physics_process(false)
	player.narrative_hold = false
	player.camera_rig.controls_active = true
	paused = false
	player.position = Vector3(0, .05, 5)
	for someone: Dictionary in crew.people:
		someone.body.position = Vector3(100, 0, 100)
	var helper: Dictionary = crew.person("Intern")
	helper.body.position = player.position + Vector3(2, 0, 0)
	crew.aid_chance = 1.0
	player.health = 26
	crew._emergency_aid(2.0, true)
	check(player.health == 26, "healthy engineer gets no emergency aid")
	player.health = 25
	crew._emergency_aid(2.0, false)
	check(player.health == 25, "idle proximity supplies no free healing")
	crew.aid_chance = 0.0
	crew._emergency_aid(2.0, true)
	check(player.health == 25, "failed random roll leaves health unchanged")
	crew.aid_chance = 1.0
	crew._emergency_aid(.1, true)
	check(player.health == 25, "random rolls wait for their interval instead of rerolling each frame")
	var blocker: StaticBody3D = StaticBody3D.new()
	var collider: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(.3, 3, 3)
	collider.shape = box
	blocker.add_child(collider)
	scene.add_child(blocker)
	blocker.position = player.position + Vector3(1, 1, 0)
	await frames(2)
	crew._emergency_aid(2.0, true)
	check(player.health == 25, "coworkers cannot heal through office geometry")
	blocker.queue_free()
	await frames(2)
	helper.dead = true
	crew._emergency_aid(2.0, true)
	check(player.health == 25, "fallen coworkers cannot assist")
	helper.dead = false
	helper.charging = true
	crew._emergency_aid(2.0, true)
	check(player.health == 25, "cavalry cannot heal during its scripted charge")
	helper.charging = false
	player.narrative_hold = true
	crew._emergency_aid(2.0, true)
	check(player.health == 25, "story holds suppress aid")
	player.narrative_hold = false
	paused = true
	crew._emergency_aid(2.0, true)
	check(player.health == 25, "pause cannot supply emergency aid")
	paused = false
	var sleeper: Dictionary = crew.person("Sleeper")
	helper.body.position = player.position + Vector3(9, 0, 0)
	sleeper.body.position = player.position + Vector3(2, 0, 0)
	crew._emergency_aid(2.0, true)
	check(player.health == 25, "sleeping coworker cannot assist")
	sleeper.body.position = Vector3(100, 0, 100)
	helper.body.position = player.position + Vector3(2, 0, 0)
	crew._emergency_aid(2.0, true)
	check(player.health == 50 and helper.line_left > 0, "nearby awake coworker heals and acknowledges a critical engineer")
	player.health = 5
	crew._emergency_aid(2.0, true)
	check(player.health == 5, "shared cooldown prevents repeated emergency heals")
	crew._emergency_aid(45.0, true)
	check(player.health == 30, "aid becomes available after cooldown")
	crew.aid_cooldown = 0.0
	player.health = 0
	crew._emergency_aid(2.0, true)
	check(player.health == 0, "aid never resurrects the engineer")
	player.health = 25
	helper.body.position = player.position + Vector3(9, 0, 0)
	crew._emergency_aid(2.0, true)
	check(player.health == 25, "distant coworkers cannot assist")
	helper.body.position = player.position + Vector3(2, 0, 0)
	crew.aid_threshold = 1.0
	player.health = 95
	crew._emergency_aid(2.0, true)
	check(player.health == 100, "aid clamps restored health to the engineer's maximum")
	crew.reset()
	check(crew.aid_cooldown == 0 and crew.aid_check_left == 0 and helper.aid_hold == 0, "retry resets aid and helper gesture state")
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
