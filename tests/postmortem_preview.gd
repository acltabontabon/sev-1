extends SceneTree
## Watch only Monday's postmortem, in real time with sound.
## sh tools/godot.sh --path . --script tests/postmortem_preview.gd
## -- --capture also saves a wall-screen checkpoint in logs/.
var scene: Node
var captured: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	paused = false
	return false


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var incident: Node = scene.get_node("Incident")
	var story: Node = incident.presentation
	var preferences: RefCounted = load("res://game/release/preferences.gd").new()
	preferences.apply(scene)
	story.skip()
	incident._cleanup()
	story.killcam_in_headless = true
	for stage in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(stage)
	incident.hold_ending = true
	incident._enter(incident.Stage.RESOLVED)
	while not is_instance_valid(story.all_hands):
		await process_frame
	var finale: Node = story.all_hands
	# Build the carried belongings before Monday's cleanup hides them.
	finale._beat("grief")
	finale._beat("desk")
	finale._beat("card")
	finale.character.sit = 0.0
	finale.character.story_pose = 0
	finale._beat("monday")
	while is_instance_valid(story.all_hands):
		if "--capture" in OS.get_cmdline_user_args() and not captured and is_instance_valid(finale.meeting):
			var meeting: Node = finale.meeting
			if meeting.agents_joined == 5 and meeting.STEPS[meeting.step][0] == "pm_backfill":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://logs/postmortem_room.png")
				meeting.screen.get_texture().get_image().save_png("res://logs/postmortem_call.png")
				captured = true
		await process_frame
	await create_timer(1.0).timeout
	quit()
