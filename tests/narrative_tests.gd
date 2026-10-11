extends "res://tests/incident_tests.gd"

func clear_standing_space() -> bool:
	var body: CollisionShape3D = player.get_node("CollisionShape3D")
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = body.shape
	query.transform = body.global_transform
	query.transform.origin.y += .02
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_shape(query).is_empty()


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	var story: CanvasLayer = incident.presentation
	check("HEALTHY" in incident.room.get_node("Critical").text and story.monitors.size() > 0, "opening begins with healthy monitoring surfaces")
	player.camera_rig.set_capture(true)
	await frames(90)
	check(player.narrative_hold and story.camera.current and story.seen.has("doc_office"), "the cold open starts with the narrator over the office")
	check(not player.request_attack() and not player.request_dodge(), "staged pose cannot attack or dodge")
	player.camera_rig.set_capture(false)
	var before: float = incident.stage_time
	await frames(60)
	check(incident.stage_time == before and not story.panel.visible, "pause freezes opening and hides caption")
	player.camera_rig.set_capture(true)
	check(player.get_node("Visual/Character").sit > .9 and player.position.distance_to(story.SEAT) < .1, "opening seats the engineer at the desk")
	await key(KEY_TAB)
	check(incident.stage == incident.Stage.ALERT and player.narrative_hold, "first viewing ignores Tab until the opening was seen once")
	# Past the narrated cold open and the night-shift montage, to the desk.
	while incident.stage_time < 23.2:
		await frames(10)
	check(story.desk.chat.get_child_count() == 1 and story.seen.has("friday"), "Friday message lands on the desk monitor with its voiced line")
	story.skip_unlocked = true
	await key(KEY_TAB)
	check(incident.stage == incident.Stage.ENCOUNTER_ONE and not player.narrative_hold and not story.camera.current, "Tab restores gameplay camera and input")
	check(clear_standing_space(), "opening releases the capsule clear of solid furniture")
	check(not story.emerging.visible and not story.card.visible and not story.letterbox[0].visible and scene.get_node("HUD").visible, "skip clears cinematic frame and restores HUD")
	await frames(150)
	check(is_instance_valid(incident.active_enemy) and incident.alert_played, "skipped opening declares incident and spawns normally")
	var count: int = story.queue.size()
	story.say("enemy")
	story.say("enemy")
	check(story.queue.size() == count, "repeated narrative events cannot duplicate notifications")
	incident._offer_upgrade(incident.Stage.INVESTIGATION)
	await frames(2)
	check(not story.panel.visible and not story.title.visible, "choice modal suppresses narrative overlays")
	incident.choose_upgrade(0)
	check("Power-up active: More damage" in incident.message and "this run only" in incident.message and not story.seen.has("debt"), "paid upgrade confirms its effect and duration without redundant speech")
	incident.run.change_burnout(90, "test pressure")
	incident.run.change_burnout(-40, "test relief")
	check(incident.run.peak_burnout == 90 and incident.run.burnout == 50, "peak records pressure before relief")
	incident.fail()
	await frames(2)
	check("Peak Burnout: 90" in incident.report and "Enemies defeated: 0" in incident.report and "Not encountered" in incident.report, "failure report uses recorded statistics")
	await key(KEY_R)
	check(incident.run.peak_burnout == 0 and incident.enemies_defeated == 0 and story.seen.is_empty(), "restart clears run statistics and one-shot messages")
	check(story.short_opening and not player.narrative_hold, "seen opening shortens on retry")
	check(clear_standing_space(), "short retry starts clear of solid furniture")
	player.camera_rig.set_capture(true)
	await frames(320)
	check(is_instance_valid(incident.active_enemy), "repeat run reaches combat within six seconds")
	# Explicit stage fixture preserves existing boss mechanics and isolates arrival timing.
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	for next in [incident.Stage.ENCOUNTER_ONE, incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	await enter_vault()
	await frames(120)
	check(not is_instance_valid(incident.active_enemy) and story.title.visible and not player.narrative_hold, "boss arrival builds tension while player retains control")
	await key(KEY_TAB)
	check(is_instance_valid(incident.active_enemy) and incident.boss_encountered, "boss skip manifests exactly one live boss")
	var boss: CharacterBody3D = incident.active_enemy
	await key(KEY_TAB)
	check(incident.active_enemy == boss, "repeated boss skip never duplicates actor")
	boss.exposed = true
	boss.receive_damage(10000, player.position)
	await frames(2)
	check("Enemies defeated: 1" in incident.report and "Eliminated" in incident.report, "victory reports actual boss defeat")
	check(not story.panel.visible and not story.title.visible and not player.narrative_hold, "terminal state clears narrative presentation")
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	for next in [incident.Stage.ENCOUNTER_ONE, incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	check(story.boss_length == 1.5, "seen boss introduction shortens on retry")
	await enter_vault()
	await frames(120)
	check(is_instance_valid(incident.active_enemy), "short boss introduction automatically completes")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
