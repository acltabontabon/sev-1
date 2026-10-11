extends SceneTree
## Rendered checkpoints for grief, desk pickup and remembered conversations.
## sh tools/godot.sh --path . --script tests/finale_preview.gd [-- --closing]
## --departure captures just the corridor and street; negative sample times are walk fractions.
var scene: Node


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
	var samples: Array = [["grief", 5.5], ["desk", 2.0], ["desk", 5.5], ["exit", 3.0], ["exit", 5.0], ["exit", 8.0], ["exit", -0.75], ["street", 3.0]]
	if "--departure" in OS.get_cmdline_user_args():
		finale._beat("grief")
		finale._beat("desk")
		samples = [["exit", 3.0], ["exit", -0.75], ["street", 3.0]]
	if "--closing" in OS.get_cmdline_user_args():
		finale._beat("grief")
		finale._beat("desk")
		finale._beat("card")
		finale._beat("monday")
		finale.meeting.step = finale.meeting.STEPS.size() - 2
		story.voice.clear()
		finale.meeting._next()
		samples = [["monday", 1.0], ["return_meeting", 1.6], ["return_floor", 1.6], ["return_desk", 4.0], ["return_desk", 6.0]]
	for sample: Array in samples:
		if finale.beat != sample[0]:
			finale._beat(sample[0])
		var elapsed: float = finale.clock - finale.beat_at
		var target: float = float(sample[1]) if float(sample[1]) >= 0.0 else finale.exit_duration * -float(sample[1])
		while elapsed < target:
			finale.tick(1.0 / 60.0)
			elapsed += 1.0 / 60.0
			await physics_frame
		await RenderingServer.frame_post_draw
		var path: String = "res://logs/finale_%s_%s.png" % [sample[0], str(int(sample[1])) if float(sample[1]) >= 0.0 else "late"]
		root.get_texture().get_image().save_png(path)
		print("SHOT ", path)
		if sample[0] in ["exit", "street"]:
			print("GAIT ", finale.character.animator.current_animation, " rate ", finale.character.animator.speed_scale, " clip time ", finale.character.animator.current_animation_position)
	finale.finish(false)
	await process_frame
	quit()
