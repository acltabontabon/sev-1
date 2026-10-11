extends SceneTree
## Outcome checks: ending-only life, clear walk, window/skip cleanup, safe replay.
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	paused = false
	return false


func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1


func _run() -> void:
	var scene: Node = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var incident: Node = scene.get_node("Incident")
	var story: Node = incident.presentation
	check(incident.get_node_or_null("NightlifeStreet") == null, "nightlife adds no actors or lights during ordinary office play")
	story.skip()
	incident._cleanup()
	incident.coworkers.cavalry_in_headless = true
	story.killcam_in_headless = true
	for stage in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(stage)
	incident.coworkers.fall_all_now()
	incident.hold_ending = true
	incident._enter(incident.Stage.RESOLVED)
	await process_frame
	story.set_process(false)
	var finale: Node = story.all_hands
	finale._beat("receipts")
	finale._beat("grief")
	finale._beat("desk")
	finale._beat("street")
	var nightlife: Node3D = finale.nightlife
	check(nightlife.is_visible_in_tree() and nightlife.patrons.size() == 9, "the actual street cut adds animated nightlife patrons and pedestrians")
	check("STRIP CLUB" in nightlife.get_node("ClubType").text and nightlife.get_node("FoodSign").text == "MIDNIGHT NOODLES", "the club frontage and late-night food counter have readable identities")
	var clear: bool = true
	var first: Vector3 = nightlife.walkers[0].body.global_position
	for sample in range(75):
		finale.clock = finale.beat_at + float(sample) / 10.0
		finale.tick(.001)
		for patron: Node3D in nightlife.patrons:
			var offset: Vector3 = patron.global_position - incident.player.global_position
			offset.y = 0
			clear = clear and offset.length() > .8
	check(clear, "every street actor stays clear of the engineer throughout the walk")
	check(nightlife.walkers[0].body.global_position.distance_to(first) > 4.5, "pedestrians travel visibly during cinematic time")
	for frame in range(4):
		await physics_frame
	var animated: bool = true
	for patron: Node3D in nightlife.patrons:
		var animator: AnimationPlayer = patron.find_child("AnimationPlayer", true, false)
		animated = animated and animator.is_playing()
	check(animated, "all nine street characters have playing rigged animations")
	finale._beat("window")
	check(not nightlife.is_visible_in_tree(), "the nightlife hides for the five silhouettes in the memorial window")
	finale.finish(false)
	await process_frame
	await process_frame
	check(not is_instance_valid(nightlife), "skipping removes the complete nightlife scene, including its lights and characters")
	scene.reset_encounter()
	await process_frame
	check(incident.get_node_or_null("NightlifeStreet") == null, "retry leaves no street props in the playable office")
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
