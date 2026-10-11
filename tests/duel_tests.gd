extends SceneTree
## Real rigs and lifecycle: connected contacts, reciprocal motion, safe skip/retry.
## --preview records the same timeline in a rendered vault with sound.
var failures: int = 0
var scene: Node
var incident: Node
var story: Node
var player: CharacterBody3D
var rig: Node3D
var hands: Dictionary = {}
var hero_hands: Dictionary = {}
var preview: bool = false
var measure: bool = false


func _initialize() -> void:
	preview = "--preview" in OS.get_cmdline_user_args()
	measure = "--measure" in OS.get_cmdline_user_args()
	_run.call_deferred()


func _process(_delta: float) -> bool:
	paused = false
	return false


func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1


func sample_boss(skeleton: Skeleton3D) -> void:
	for side: String in ["L", "R"]:
		hands[side] = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Middle1." + side)).origin


func sample_hero() -> void:
	for side: String in ["L", "R"]:
		hero_hands[side] = rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("Fist." + side)).origin


func begin_duel() -> Node:
	story.skip()
	incident._cleanup()
	for stage in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(stage)
	incident.boss_triggered = true
	story.skip()
	incident._spawn()
	incident.boss.moves.cancel()
	incident.boss.phase_time = 5.0
	story.killcam_in_headless = true
	incident.boss.exposed = true
	incident.boss.receive_damage(incident.boss.health + 10, player.global_position)
	story.set_process(false)
	incident.set_physics_process(false)
	var duel: Node = story.duel_scene
	duel.boss_iks[-1].modification_processed.connect(sample_boss.bind(duel.boss_skeleton))
	return duel


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	incident = scene.get_node("Incident")
	story = incident.presentation
	player = scene.get_node("Player")
	rig = player.get_node("Visual/Character")
	rig.left_ik.modification_processed.connect(sample_hero)
	var duel: Node = begin_duel()
	var boss: CharacterBody3D = incident.boss
	if preview or measure:
		rig.overtime(true)
	if measure:
		Engine.max_fps = 60
	var health: float = player.health
	var initial_nodes: int = duel.boss_skeleton.get_child_count() - 2
	var captures: Array[float] = [.5, 1.2, 2.5, 3.8, 6.2, 7.6, 8.9, 10.1, 11.7, 13.8]
	var captured: int = 0
	var checks_done: bool = false
	var max_contact_error: float = 0.0
	var max_grip_error: float = 0.0
	var max_weapon_error: float = 0.0
	var boss_start: Vector3 = duel.demon.global_position
	var boss_moved: bool = false
	var low_hero: bool = false
	var thrown_back: bool = false
	var frame_times: Array[float] = []
	var previous_frame: int = Time.get_ticks_usec()
	while is_instance_valid(duel) and not duel.done:
		var now: int = Time.get_ticks_usec()
		var elapsed: float = float(now - previous_frame) / 1000000.0
		if measure and duel.clock > 3.0:
			frame_times.append(elapsed * 1000.0)
		previous_frame = now
		duel.tick(maxf(elapsed, .001) * Engine.time_scale if measure else 1.0 / 60.0)
		await physics_frame
		await process_frame
		if not is_instance_valid(duel) or duel.done:
			break
		if duel.clock < duel.SHOUT_AT:
			boss_moved = boss_moved or duel.demon.global_position.distance_to(boss_start) > 1.0
			low_hero = low_hero or rig.position.y < -.35
			thrown_back = thrown_back or (duel.beat == "knockback" and player.global_position.z > -34)
		if duel.beat == "catch" and duel.clock > 3.7 and duel.clock < 4.7 or duel.beat == "block" and duel.clock > 8.85:
			max_weapon_error = maxf(max_weapon_error, duel.weapon_contact.distance_to(duel.contact))
			for index in 2:
				var side: String = "L" if index == 0 else "R"
				max_contact_error = maxf(max_contact_error, hands[side].distance_to(duel.boss_targets[index].global_position))
				var grip: Vector3 = rig.weapon.global_transform * (rig.LEFT_GRIP if index == 0 else rig.RIGHT_GRIP)
				max_grip_error = maxf(max_grip_error, hero_hands[side].distance_to(grip))
		if not checks_done and duel.clock > 12.0:
			checks_done = true
			check(max_contact_error < .3, "both boss hands support the trident during lock and heavy block (%.3f m)" % max_contact_error)
			check(max_weapon_error < .3, "sword meets the trident shaft at both held clashes (%.3f m)" % max_weapon_error)
			check(max_grip_error < .3, "both engineer hands remain on the sword grip (%.3f m)" % max_grip_error)
			check(duel.trident.is_visible_in_tree(), "the boss remains visibly armed throughout the exchange")
			check(boss_moved and low_hero and thrown_back, "both fighters advance, the engineer ducks and the boss throws him back")
			check(player.health == health and boss.health > 0 and not boss.visible and player.narrative_hold,
				"choreography holds the live fight without applying extra gameplay damage")
		if preview:
			if captured < captures.size() and duel.clock >= captures[captured]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://logs/duel_%d.png" % captured)
				captured += 1
	if measure:
		frame_times.sort()
		var total: float = 0.0
		for frame: float in frame_times:
			total += frame
		var report: Dictionary = {"resolution": str(root.size), "samples": frame_times.size(), "mean_fps": 1000.0 / (total / frame_times.size()), "median_ms": frame_times[frame_times.size() / 2], "p95_ms": frame_times[int(frame_times.size() * .95)], "max_ms": frame_times.back(), "settings": "Forward+/Metal, project defaults, 60 FPS cap", "scenario": "one scripted duel, first 3 seconds excluded, no captures"}
		print("DUEL PERFORMANCE ", JSON.stringify(report))
		var file: FileAccess = FileAccess.open("res://logs/duel_performance.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
	story.set_process(true)
	await process_frame
	await process_frame
	story.set_process(false)
	check(incident.stage == incident.Stage.RESOLVED and boss.health <= 0 and story.beat_shot == "all_hands", "full choreography lands the real killing blow and hands off to the finale")
	await process_frame
	check(not rig.duel_active and story.demon.model.find_child("Skeleton3D", true, false).get_child_count() == initial_nodes,
		"completion releases cinematic pose and removes temporary boss IK")
	story.skip()
	scene.reset_encounter()
	await process_frame
	duel = begin_duel()
	duel.tick(4.0)
	story.skip()
	story.set_process(true)
	await process_frame
	await process_frame
	story.set_process(false)
	check(incident.stage == incident.Stage.RESOLVED and not rig.duel_active and story.beat_shot == "all_hands", "TAB during the sword lock lands once and continues into the ending")
	story.skip()
	scene.reset_encounter()
	await process_frame
	duel = begin_duel()
	duel.tick(9.8)
	scene.reset_encounter()
	await process_frame
	check(not rig.duel_active and not is_instance_valid(story.duel_scene) and not player.narrative_hold and story.duel_pieces.is_empty(),
		"retry during knockback restores the player and removes duel actors and gore")
	story.killcam_in_headless = false
	scene.queue_free()
	await process_frame
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
