extends SceneTree
## The aftermath must remember living conversations and leave no props on retry.
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
	var dialogue: GDScript = load("res://game/incidents/dialogues.gd")
	var heard: Dictionary = dialogue.line(dialogue.tree("Intern"), "good_days")
	check(dialogue.memory("Intern") == heard, "the ending recalls the actual conversation heard, with the matching voice clip")
	var scene: Node = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var incident: Node = scene.get_node("Incident")
	var story: Node = incident.presentation
	var character: Node = incident.player.get_node("Visual/Character")
	story.skip()
	incident._cleanup()
	incident.coworkers.cavalry_in_headless = true
	story.killcam_in_headless = true
	for stage in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(stage)
	incident.coworkers.fall_all_now()
	incident.hold_ending = true
	incident.player.camera_rig.controls_active = true
	incident._enter(incident.Stage.RESOLVED)
	await process_frame
	story.set_process(false)
	var finale: Node = story.all_hands
	finale._beat("receipts")
	finale._beat("memorial")
	finale.tick(finale.MEMORIAL_EACH * 5 + .1)
	check(finale.beat == "grief" and incident.coworkers.cavalry_fallen() == 5 and not character.weapon.visible,
		"the memorial reaches grief while all five casualties remain fallen")
	await physics_frame
	finale.tick(5.0)
	check(finale.tear.is_visible_in_tree() and finale.tear.position.y < .21 and incident.player.narrative_hold,
		"a bone-attached tear travels down the cheek during the held grief shot")
	finale.tick(2.1)
	check(finale.beat == "desk" and is_instance_valid(finale.belongings), "grief proceeds to personal effects at the desk")
	finale.tick(5.5)
	check(finale.belongings.global_position.distance_to(finale.belongings_from) > .1 and character.sit == 0,
		"the engineer stands and takes his belongings off the desk")
	finale.tick(.6)
	check(finale.beat == "exit" and finale.memories.size() == 5, "the desk pickup proceeds to the walk past five memories")
	var previous_end: float = 0.0
	var spaced: bool = true
	for memory: Dictionary in finale.memories:
		spaced = spaced and memory.cue >= previous_end
		previous_end = memory.cue + memory.length
	check(spaced and finale.exit_duration > previous_end, "the walk gives every recorded line time to finish without overlapping another memory")
	finale.tick(1.0)
	check(finale.memory_caption.visible and "remembered" in finale.memory_caption.text,
		"remembered speech has matching accessible captions")
	story.voice.subtitles_enabled = false
	finale.tick(.1)
	check(not finale.memory_caption.visible, "memory captions respect the subtitle preference")
	story.voice.subtitles_enabled = true
	for frame in range(50):
		finale.tick(1.0 / 60.0)
		await physics_frame
	var walk_at: float = character.animator.current_animation_position
	for frame in range(20):
		finale.tick(1.0 / 60.0)
		await physics_frame
	check(character.story_walk_speed < .35 and character.animator.current_animation == "rig/walk" and character.animator.current_animation_position != walk_at,
		"the slow office exit advances a walk cycle instead of sliding in idle or freezing in jump")
	finale._beat("street")
	for frame in range(40):
		finale.tick(1.0 / 60.0)
		await physics_frame
	check(character.animator.current_animation == "rig/walk",
		"staged street travel keeps walking without a physics floor update")
	var tear_attachment: Node = finale.tear_anchor.get_parent()
	var carry_attachment: Node = finale.carry_anchor.get_parent().get_parent()
	var box: Node = finale.belongings
	var sword: Node = finale.parked_sword
	check(sword.visible and sword.global_position.distance_to(finale.sword_rest.origin) < .01 and not character.weapon.visible,
		"his sword stays at the workstation while he walks away unarmed")
	story.set_process(true)
	story.skip()
	await process_frame
	await process_frame
	check(not is_instance_valid(tear_attachment) and not is_instance_valid(carry_attachment) and not is_instance_valid(box) and not is_instance_valid(sword) and character.weapon.visible,
		"TAB removes the tear, carried props and memory audio and restores the weapon")
	scene.reset_encounter()
	await process_frame
	check(dialogue.remembered_lines.is_empty() and character.sit == 0 and character.weapon.visible and character.story_walk_speed == 0.0 and character.story_hand_targets.is_empty(),
		"retry clears run memories and restores the playable engineer")
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
