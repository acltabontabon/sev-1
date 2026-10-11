extends SceneTree
## The response reaches real stations, leaves persistent casualties, and survives skip/retry.
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _run() -> void:
	var scene: Node = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var incident: Node = scene.get_node("Incident")
	var story: Node = incident.presentation
	var crew: Node = incident.coworkers
	var player: CharacterBody3D = scene.get_node("Player")
	player.camera_rig.set_capture(true)
	var character: Node = player.get_node("Visual/Character")
	story.skip()
	incident._cleanup()
	crew.cavalry_in_headless = true
	story.killcam_in_headless = true
	for stage in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(stage)
	await frames(4)
	check(crew.cavalry_standing() == 5 and not crew.response_started and crew.cavalry_fallen() == 0,
		"the crew waits for the engineer to witness the response")
	player.position = Vector3(9, .05, -31)
	await frames(10)
	check(story.hero_phase == "response" and player.narrative_hold and not is_instance_valid(incident.boss),
		"the response holds combat while the engineer follows the crew")
	story.set_process(false)
	var previous: Dictionary = {}
	var facing_forward: bool = true
	for frame in range(400):
		for worker: Dictionary in crew.people:
			if not worker.charging:
				continue
			var body: Node3D = worker.body
			if previous.has(worker.entry.name):
				var step: Vector3 = body.position - previous[worker.entry.name]
				# Allow turns to settle; inspect the long, straight doorway approach.
				if step.length() > .02 and body.position.z > -30 and frame > 30:
					facing_forward = facing_forward and body.basis.z.normalized().dot(step.normalized()) > .7
			previous[worker.entry.name] = body.position
		await frames(1)
	check(facing_forward, "running crew face their travel direction through the doorway")
	var stationed: bool = true
	for entry: Array in crew.CAVALRY:
		var worker: Dictionary = crew.person(entry[0])
		stationed = stationed and worker.body.position.distance_to(crew.STAGE[entry[0]].spot) < .3
	check(stationed and crew.cavalry_fallen() == 0, "all five reach separate response stations before anyone is killed")
	var response: Node3D = crew.response
	check(response.water[0].visible and (response.hose.back().global_position + response.hose.back().global_basis.y * .5).distance_to(response.equipment.SRE.tool.to_global(Vector3(0, 0, .08))) < .02,
		"the responding SRE has a connected hose and visible water stream")
	story.skip()
	await frames(4)
	check(crew.cavalry_fallen() == 5 and is_instance_valid(incident.boss) and not player.narrative_hold and character.story_walk_speed == 0.0,
		"skipping the fire response starts one playable boss fight and clears the walking override")
	var boss: Node = incident.boss
	boss.set_physics_process(false)
	player.max_health = 1000000
	player.health = 1000000
	await frames(900)
	var remains: bool = response.pools.size() == 5 and response.settled and not response.water[0].visible
	for entry: Array in crew.CAVALRY:
		var worker: Dictionary = crew.person(entry[0])
		remains = remains and worker.dead and worker.body.visible and response.equipment[entry[0]].dropped
	for pool: Decal in response.pools:
		remains = remains and pool.visible and pool.modulate.a > .9
	check(remains and incident.boss == boss, "five remains, pools and dropped tools persist beyond ordinary blood expiry without respawning the boss")
	var response_ref: WeakRef = weakref(response)
	story.set_process(true)
	scene.reset_encounter()
	await frames(5)
	check(response_ref.get_ref() == null and crew.response == null and crew.cavalry_fallen() == 0 and character.story_walk_speed == 0.0,
		"restart removes the whole response and restores living crew and normal locomotion")
	crew.cavalry_in_headless = false
	story.killcam_in_headless = false
	scene.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
