extends SceneTree
## Full duel/ending in the real application, ending on a usable main menu.
## sh tools/godot.sh --path . --script tests/ending_preview.gd
## -- --closing skips to Monday's final reply. --capture saves card/menu PNGs and quits.
## -- --duel-only watches the real application duel, then closes at the aftermath.
var app: Node
var viewing: bool = true
var captured: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	if viewing and is_instance_valid(app) and is_instance_valid(app.session):
		paused = false
		app.session.get_node("Player/CameraRig").controls_active = true
		if "--capture" in OS.get_cmdline_user_args() and not captured:
			var finale: Node = app.session.get_node("Incident").presentation.all_hands
			if is_instance_valid(finale) and finale.beat == "next" and finale.clock - finale.beat_at > 1.5:
				captured = true
				_capture_card.call_deferred()
	return false


func _capture_card() -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://logs/to_be_continued.png")


func _run() -> void:
	app = load("res://game/release/front_end.tscn").instantiate()
	if "--duel-only" in OS.get_cmdline_user_args():
		app.preferences.path = "user://duel_preview.cfg"
	root.add_child(app)
	current_scene = app
	await process_frame
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	var story: Node = incident.presentation
	player.max_health = 1000000
	player.health = player.max_health
	story.skip()
	incident._cleanup()
	for stage in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(stage)
	player.global_position = Vector3(9, .05, -31)
	await physics_frame
	if "--closing" in OS.get_cmdline_user_args():
		story.skip()
		incident._enter(incident.Stage.RESOLVED)
		while not is_instance_valid(story.all_hands):
			await process_frame
		var finale: Node = story.all_hands
		finale._beat("receipts")
		finale._beat("grief")
		finale._beat("desk")
		finale._beat("card")
		finale._beat("monday")
		finale.meeting.step = finale.meeting.STEPS.size() - 2
		story.voice.clear()
		finale.meeting._next()
	else:
		await create_timer(1.0).timeout
		story.skip()
		while not is_instance_valid(incident.boss):
			await process_frame
		await create_timer(2.5).timeout
		incident.boss.phase_time = 5.0
		await create_timer(.2).timeout
		incident.boss.receive_damage(incident.boss.health + 10, player.global_position)
		if "--duel-only" in OS.get_cmdline_user_args():
			while story.beat_shot != "all_hands":
				await process_frame
			await create_timer(1.5).timeout
			print("DUEL PREVIEW COMPLETE")
			quit()
			return
	while is_instance_valid(app.session):
		await process_frame
	viewing = false
	print("ENDING COMPLETE: main menu")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://logs/ending_main_menu.png")
		quit()
