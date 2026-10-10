extends SceneTree
## Outcomes: memories never resurrect casualties; gold waits for the buildup;
## skipping/restarting mid-transformation leaves a playable, clean state.
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


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
	var player: CharacterBody3D = scene.get_node("Player")
	var character: Node = player.get_node("Visual/Character")
	story.skip()
	incident._cleanup()
	incident.coworkers.cavalry_in_headless = true
	story.killcam_in_headless = true
	for stage in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(stage)
	incident.coworkers.fall_all_now()
	story.set_process(false)
	story.beat_shot = "massacre"
	story.massacre_time = 0.0
	story.boss_length = 120.0
	story._hero_phase("memory")
	story._massacre_shot(1.0)
	check(incident.coworkers.cavalry_fallen() == 5 and is_instance_valid(story.rage_memory) and not character.overtime_on,
		"memories show the living team without resurrecting the five casualties or starting the form")
	story._massacre_shot(8.0)
	await process_frame
	check(story.hero_phase == "charge" and story.rage_memory == null and not is_instance_valid(incident.boss),
		"the memory ends cleanly and the boss waits through the buildup")
	story._massacre_shot(2.8)
	check(not character.overtime_on and character.hair_material.emission_energy_multiplier > 0 and not incident.coworkers.blown_home,
		"partial gold appears before the locked form and knockback")
	check(character.overtime_hair.visible and character.overtime_hair.scale.y < 1.0 and story.powerup.stream != null,
		"the charge raises the spiked hair and supplies a dedicated wordless shout")
	check(story.powerup.stream.get_length() >= story.HERO_CHARGE,
		"the vowel shout lasts through the charge rather than leaving silence before the blast")
	story._massacre_shot(1.1)
	check(character.overtime_on and incident.coworkers.blown_home and story.hero_phase == "roar",
		"the roar completes the form and launches the boss")
	check(character.overtime_hair.visible and is_equal_approx(character.overtime_hair.scale.y, 1.0) and is_equal_approx(character.hair_material.albedo_color.a, 1.0),
		"the completed form has a raised spiked silhouette with a full opaque hair base")
	story._massacre_shot(story.roar_length + .3)
	story._massacre_shot(8.0)
	check(story.beat_shot.is_empty() and not player.narrative_hold and scene.get_node("HUD").visible and incident.spawn_delay == 0,
		"the cinematic releases controls, HUD and the boss spawn together")
	story._hero_phase("memory")
	story.beat_shot = "massacre"
	story.skip()
	await process_frame
	check(story.rage_memory == null and not story.crew_freeze.visible and not story.fade.visible and character.overtime_on and not player.narrative_hold,
		"skipping a memory clears its filter and actors and gives control in the completed form")
	story._hero_phase("charge")
	character.overtime_charge(.6)
	scene.reset_encounter()
	await process_frame
	check(character.overtime_strength == 0 and not character.overtime_on and not is_instance_valid(character.overtime_aura) and not story.roar.playing and not story.powerup.playing and not character.overtime_hair.visible and is_equal_approx(character.hair_material.albedo_color.a, 1.0),
		"restart during partial gold removes the aura and stops the roar")
	story._hero_phase("memory")
	story.rage_memory.tick(1.0)
	scene.reset_encounter()
	await process_frame
	check(story.rage_memory == null and not story.crew_freeze.visible and not story.fade.visible,
		"restart during a flashback removes remembered bodies, audio and the screen filter")
	scene.queue_free()
	incident.coworkers.cavalry_in_headless = false
	story.killcam_in_headless = false
	await process_frame
	quit(1 if failures > 0 else 0)
