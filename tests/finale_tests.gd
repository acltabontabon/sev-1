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
	dialogue.remembered_lines.clear()
	var fallback: Dictionary = dialogue.memory("Manager")
	check(fallback.clip == "talk_manager_after_hours" and "bereavement" in fallback.text,
		"unvisited crew supply an authored late-night recollection with matching speech")
	var heard: Dictionary = dialogue.line(dialogue.tree("Intern"), "good_days")
	check(dialogue.memory("Intern") == heard, "the ending recalls the actual conversation heard, with the matching voice clip")
	var intern_talk: Dictionary = dialogue.tree("Intern")
	var expected_takes: int = intern_talk.nodes.good_days.text_variants.size() + 1
	var takes: Array[String] = [heard.clip]
	for take in range(expected_takes - 1):
		var another: Dictionary = dialogue.line(intern_talk, "good_days")
		if not takes.has(another.clip):
			takes.append(another.clip)
	check(takes.size() == expected_takes, "ordinary memories exhaust their varied recorded takes before repeating")
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
	story.voice._process(.1)
	check(story.voice.current_line == "doc_battle_over", "the aftermath first establishes that the battle is over")
	finale.tick(5.6)
	check(finale.beat == "receipts", "the fading form shot waits for the conclusion narration")
	story.voice.clear()
	finale.tick(.01)
	check(finale.beat == "cent", "the conclusion leads into the recovered cent")
	story.voice.clear()
	finale.tick(2.1)
	check(finale.beat == "casualties" and not is_instance_valid(finale.recollection),
		"the casualties are introduced in the vault before any memory appears")
	var before_check: Vector3 = incident.player.global_position
	finale.tick(1.6)
	check(incident.player.global_position.distance_to(before_check) > .1 and character.story_walk_speed > 0,
		"the engineer deliberately approaches Morgan to check on her")
	story.voice._process(.1)
	check(story.voice.current_line == "doc_fallen", "the narrator names the fallen crew during the approach")
	finale.clock = finale.beat_at + finale.bridge_seconds
	finale.tick(.01)
	check(finale.beat == "casualties", "the casualty shot gives its narrator time to finish")
	story.voice.clear()
	finale.tick(.01)
	check(finale.beat == "remember" and character.preview_clip == "fixing" and not character.weapon.visible,
		"he begins an unarmed kneeling check before reminiscing")
	await physics_frame
	await physics_frame
	check(character.animator.current_animation == "rig/fixing", "the existing kneeling performance is actually applied to the engineer")
	story.voice._process(.1)
	check(story.voice.current_line == "doc_remember", "the narrator explains why the moment becomes a memory")
	finale.clock = finale.beat_at + finale.bridge_seconds
	finale.tick(.01)
	check(finale.beat == "remember" and not is_instance_valid(finale.recollection), "the memory cannot interrupt the transition's last words")
	story.voice.clear()
	finale.tick(.01)
	check(finale.beat == "memorial" and character.preview_clip.is_empty() and not finale.fade.visible,
		"the bridge releases the kneeling pose and fades into the first sketch")
	var recalled: Array[String] = []
	var living_set: Node = finale.recollection
	var memory_images: Array[Texture2D] = []
	var memory_canvas: Control = finale.recollection.canvas
	for index in range(5):
		await process_frame
		finale.tick(.2)
		check(finale.recollection.visible and finale.recollection.canvas.visible and not finale.memorial_name.visible and finale.recollection.artwork.texture != null,
			"each memory displays its authored living illustration before the casualty shot")
		memory_images.append(finale.recollection.artwork.texture)
		check(finale.recollection.artwork.material == finale.recollection.memory_material and not story.crew_freeze.visible,
			"memory grading affects the drawing while leaving captions sharp")
		var framing_from: Vector2 = finale.recollection.artwork.size
		finale.tick(.5)
		check(finale.recollection.artwork.size.distance_to(framing_from) > .01,
			"gentle framing drift gives the remembered moment its own motion")
		recalled.append(finale.MEMORIAL[finale.memorial_index][0])
		story.voice._process(.1)
		check(story.voice.current_line == ["doc_morgan", "doc_nadia", "doc_jun", "doc_jo", "doc_val"][index] and not story.voice.subtitle.is_empty(),
			"each teammate has synchronized narrator speech and subtitles")
		finale.clock = finale.memorial_at + finale.memorial_duration + 1.0
		finale.tick(.001)
		check(finale.recollection.visible, "a delayed voice keeps the living shot until its last word")
		story.voice.clear()
		finale.tick(.001)
		check(not finale.recollection.visible and finale.memorial_name.visible and not story.panel.visible,
			"narrated memory cuts to a silent named casualty shot")
		check(not story.crew_freeze.visible and not finale.recollection.canvas.visible,
			"the present-day casualty restores the clear picture and original screen effect")
		finale.clock = finale.memorial_loss_at + finale.MEMORIAL_EACH
		finale.tick(.01)
	var distinct_images: bool = true
	for first in range(memory_images.size()):
		for second in range(first):
			distinct_images = distinct_images and memory_images[first].get_rid() != memory_images[second].get_rid()
	check(distinct_images, "each fallen teammate receives a different illustrated moment")
	check(recalled == ["Manager", "SRE", "Designer", "Intern", "Director"],
		"all five teammates receive their own memory before grief")
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
	finale.tick(2.5)
	check(finale.memory_caption.visible and "remembered" in finale.memory_caption.text,
		"remembered speech has matching accessible captions")
	story.voice.subtitles_enabled = false
	finale.tick(.1)
	check(not finale.memory_caption.visible, "memory captions respect the subtitle preference")
	story.voice.subtitles_enabled = true
	finale.clock = finale.beat_at + .4
	for frame in range(50):
		finale.tick(1.0 / 60.0)
		await physics_frame
	var walk_at: float = character.animator.current_animation_position
	for frame in range(20):
		finale.tick(1.0 / 60.0)
		await physics_frame
	check(character.story_walk_speed > 8.1 / (finale.exit_duration - .6) and character.animator.current_animation == "rig/walk" and character.animator.current_animation_position != walk_at,
		"the office exit advances its walk cycle with a pace matched to travel")
	character.story_walk_speed = .2
	character._physics_process(1.0 / 60.0)
	check(character.animator.current_animation == "rig/walk", "even slower cinematic travel keeps walking below the gameplay idle threshold")
	var corridor: Node = finale.departure
	var clear_route: bool = true
	var probe: SphereShape3D = SphereShape3D.new()
	probe.radius = .45
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.exclude = [incident.player.get_rid()]
	for sample in range(101):
		finale.clock = finale.beat_at + finale.exit_duration * float(sample) / 101.0
		finale.tick(.001)
		query.transform = Transform3D(Basis.IDENTITY, incident.player.global_position + Vector3.UP * .95)
		clear_route = clear_route and scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
		query.transform.origin = story.camera.global_position
		clear_route = clear_route and scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
	check(clear_route and corridor.is_visible_in_tree(), "the full departure keeps the hero and both camera tracks clear of solid furniture and architecture")
	var grounded: bool = true
	for sample in range(11):
		var at: Vector3 = finale.EXIT_PATH[0].lerp(finale.EXIT_PATH[1], float(sample) / 10.0)
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(at + Vector3.UP, at - Vector3.UP)
		ray.exclude = [incident.player.get_rid()]
		grounded = grounded and not scene.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	check(grounded, "the departure route has a continuous physical floor beneath it")
	finale._beat("street")
	check(not corridor.visible, "the lift corridor disappears at the rainy street cut")
	finale.tick(2.0)
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
	var standing: AABB = finale.sword_bounds()
	var monitor: MeshInstance3D = incident.room.get_node("YourWorkstation/Monitor")
	var top: MeshInstance3D = incident.room.get_node("YourWorkstation/Top/Mesh")
	check(absf(standing.position.y - .02) < .01 and standing.size.y > 2.0,
		"the actual sword tip rests on the floor with the blade standing upright")
	check(not standing.intersects(monitor.global_transform * monitor.get_aabb()) and not standing.intersects(top.global_transform * top.get_aabb()),
		"the parked sword stays entirely clear of the tabletop and monitor")
	story.set_process(true)
	story.skip()
	await process_frame
	await process_frame
	check(not is_instance_valid(living_set) and not is_instance_valid(memory_canvas) and not is_instance_valid(corridor) and not is_instance_valid(tear_attachment) and not is_instance_valid(carry_attachment) and not is_instance_valid(box) and not is_instance_valid(sword) and character.weapon.visible,
		"TAB removes the tear, carried props and memory audio and restores the weapon")
	scene.reset_encounter()
	await process_frame
	check(dialogue.remembered_lines.is_empty() and character.sit == 0 and character.weapon.visible and character.story_walk_speed == 0.0 and character.story_hand_targets.is_empty(),
		"retry clears run memories and restores the playable engineer")
	story.skip()
	incident._cleanup()
	for stage in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(stage)
	story.reset_story()
	incident.player.camera_rig.controls_active = true
	story.set_process(true)
	incident._enter(incident.Stage.RESOLVED)
	await process_frame
	story.set_process(false)
	var closing: Node = story.all_hands
	check(is_instance_valid(closing), "retry can stage a fresh closing scene")
	if not is_instance_valid(closing):
		quit(1)
		return
	closing._beat("receipts")
	closing._beat("grief")
	closing._beat("desk")
	closing._beat("card")
	closing._beat("monday")
	closing.meeting.step = closing.meeting.STEPS.size() - 1
	story.voice.clear()
	closing.tick(2.0)
	check(closing.beat == "return_meeting", "the final postmortem reply leads into returning to work")
	closing.tick(3.3)
	closing.tick(3.3)
	check(closing.beat == "return_desk", "the engineer returns across the office to his workstation")
	closing.tick(4.0)
	await physics_frame
	check(character.story_pose == character.Pose.TYPING and character.story_sit_progress > 0 and character.story_sit_progress < 1,
		"the return plays a gradual sit-down before starting the day")
	closing.tick(4.1)
	check(closing.beat == "next" and closing.titles.text == "TO BE CONTINUED",
		"the episode closes at his desk with TO BE CONTINUED")
	var obsolete_lines: Array[String] = ["victory_thanks", "victory"]
	story.say_sequence(obsolete_lines)
	story.say("victory_thanks")
	closing.tick(3.6)
	await process_frame
	await process_frame
	check(story.voice.current_line.is_empty() and story.voice.queue.is_empty() and story.sequence.is_empty() and story.finale_completed, "the ending clears stale speech instead of replaying teamwork congratulations")
	story.set_process(true)
	scene.reset_encounter()
	await process_frame
	check(character.story_sit_progress == -1.0 and not story.finale_completed, "retry clears the closing sit-down and completion flag")
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
