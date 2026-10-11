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
	story.demon.hide()
	incident.player.get_node("Visual/Character").overtime(true)
	if is_instance_valid(incident.boss):
		incident.boss.final_blow()
	if not incident.terminal():
		incident._enter(incident.Stage.RESOLVED)
	await process_frame
	story.set_process(false)
	var finale: Node = story.all_hands
	if "--promise" in OS.get_cmdline_user_args():
		# Review fixture only. Normal play records this through an actual chosen reply.
		preload("res://game/incidents/dialogues.gd").promises["talk_manager_"] = "After this, lunch is on me."
	# Replay begins after the final blow, when the normal death beat has reconciled these.
	for index in range(3):
		var ledger: Label3D = incident.room.get_node("LedgerText%d" % index)
		ledger.text = "SUCCESS"
		ledger.modulate = Color(.3, 1, .6)
	if "--play-ending" in OS.get_cmdline_user_args():
		finale._beat("receipts")
		story.set_process(true)
		while is_instance_valid(finale) and not finale.done:
			await process_frame
		quit()
		return
	finale._beat("receipts")
	if "--transition" not in OS.get_cmdline_user_args():
		finale._beat("memorial")
	if "--capture-promise" in OS.get_cmdline_user_args():
		story.voice.clear()
		finale.tick(finale.memorial_duration + .1)
		finale.tick(.7)
		await process_frame
		RenderingServer.force_draw()
		DirAccess.make_dir_recursive_absolute("res://builds")
		root.get_texture().get_image().save_png("res://builds/heart_promise.png")
		finale.finish(false)
		await process_frame
		quit()
		return
	if "--play-memorial" in OS.get_cmdline_user_args():
		story.set_process(true)
		while is_instance_valid(finale) and finale.beat in ["memorial", "grief"]:
			await process_frame
		if is_instance_valid(finale):
			finale.finish(false)
		await process_frame
		quit()
		return
	var samples: Array = [["grief", 5.5], ["desk", 2.0], ["desk", 5.5], ["exit", 3.0], ["exit", 5.0], ["exit", 8.0], ["exit", -0.75], ["door", 1.5], ["door", 3.8], ["door", 5.8], ["street", 3.0], ["street", 8.0], ["street", 11.5], ["window", 2.0]]
	if "--memorial" in OS.get_cmdline_user_args():
		samples = []
		for index in range(5):
			samples.append(["memorial", .8, index])
			samples.append(["memorial", 5.0, index])
	if "--transition" in OS.get_cmdline_user_args():
		story.voice.clear()
		finale.character.overtime(false)
		samples = [["casualties", 1.8], ["remember", 1.5], ["remember", 7.0], ["memorial", .8]]
	if "--departure" in OS.get_cmdline_user_args() or "--street" in OS.get_cmdline_user_args():
		story.voice.clear()
		finale.recollection.conceal()
		finale.character.overtime(false)
		finale._beat("grief")
		finale._beat("desk")
		samples = [["exit", 3.0], ["exit", -0.75], ["door", 1.5], ["door", 3.8], ["door", 5.8], ["street", 3.0], ["street", 8.0], ["street", 11.5], ["window", 2.0]]
	if "--street" in OS.get_cmdline_user_args():
		samples = [["street", 3.0], ["street", 8.0], ["street", 11.5], ["window", 2.0]]
	if "--closing" in OS.get_cmdline_user_args():
		finale._beat("grief")
		finale._beat("desk")
		finale._beat("card")
		finale._beat("monday")
		finale.meeting.step = finale.meeting.STEPS.size() - 2
		story.voice.clear()
		finale.meeting._next()
		samples = [["monday", 1.0], ["return_meeting", 1.6], ["return_floor", 1.6], ["return_desk", 4.0], ["return_desk", 6.0]]
	if "--door" in OS.get_cmdline_user_args():
		finale._beat("grief")
		finale._beat("desk")
		finale._beat("exit")
		samples = [["door", .5], ["door", 1.5], ["door", 3.8], ["door", 5.8]]
	for sample: Array in samples:
		if finale.beat != sample[0]:
			if "--transition" in OS.get_cmdline_user_args():
				story.voice.clear()
			finale._beat(sample[0])
		if sample.size() > 2 and sample[2] > finale.memorial_index:
			story.voice.clear()
			finale._recall_next()
		var elapsed: float = finale.clock - (finale.memorial_at if sample.size() > 2 else finale.beat_at)
		var target: float = float(sample[1]) if float(sample[1]) >= 0.0 else finale.exit_duration * -float(sample[1])
		while elapsed < target:
			finale.tick(1.0 / 60.0)
			elapsed += 1.0 / 60.0
			await physics_frame
		await RenderingServer.frame_post_draw
		var path: String = "res://logs/finale_%s_%s.png" % [sample[0], str(int(sample[1])) if float(sample[1]) >= 0.0 else "late"]
		if sample.size() > 2:
			path = "res://logs/finale_memory_%d_%d.png" % [sample[2], int(sample[1])]
		root.get_texture().get_image().save_png(path)
		print("SHOT ", path)
		if sample[0] in ["exit", "street"]:
			print("GAIT ", finale.character.animator.current_animation, " rate ", finale.character.animator.speed_scale, " clip time ", finale.character.animator.current_animation_position)
	finale.finish(false)
	await process_frame
	quit()
