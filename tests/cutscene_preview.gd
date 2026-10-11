extends SceneTree
## Watch the cinematics in a window, in real time with sound: the narrated cold open, then
## the vault (the night shift's charge, the massacre and the hero entrance).
## sh tools/godot.sh --path . --script tests/cutscene_preview.gd [-- --vault | --finale]
## `--opening` stops after the cold open; combine with `--play` to explore the office.
## `--play` hands control to the player after the entrance and keeps the game open.
## `--vault` skips straight to the vault; `--finale` also skips the massacre, then lands
## the killing blow: the duel and the ending. Close the window or wait for it to end.
var scene: Node
var captures: Dictionary = {}
var playing: bool = false
var player: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	if playing:
		return false
	# A viewer, not a player: keep the incident running even without mouse capture.
	if paused:
		paused = false
	if player != null:
		player.camera_rig.controls_active = true
	return false


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var preferences: RefCounted = load("res://game/release/preferences.gd").new()
	preferences.apply(scene)
	var incident: Node = scene.get_node("Incident")
	player = scene.get_node("Player")
	if not "--play" in OS.get_cmdline_user_args():
		player.max_health = 1000000
		player.health = 1000000
	player.camera_rig.set_capture(false)
	if not ("--vault" in OS.get_cmdline_user_args() or "--finale" in OS.get_cmdline_user_args()):
		while incident.stage == incident.Stage.ALERT:
			await process_frame
		if "--opening" in OS.get_cmdline_user_args():
			if "--play" in OS.get_cmdline_user_args():
				playing = true
				player.camera_rig.set_capture(true)
			else:
				quit()
			return
		await create_timer(2.0).timeout
	else:
		incident.presentation.skip()
	await process_frame
	incident._cleanup()
	for next in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	# Down the corridor behind the night shift, then into the vault.
	player.global_position = Vector3(9, .05, -17.5)
	var walk: float = 0.0
	while not incident.boss_triggered:
		walk += 1.0 / 60.0
		player.global_position = Vector3(9, .05, lerpf(-17.5, -31.0, clampf((walk - 1.0) / 7.0, 0.0, 1.0)))
		player.visual.rotation.y = 0.0
		await physics_frame
	var fallen: int = 0
	var began: int = Time.get_ticks_msec()
	if "--finale" in OS.get_cmdline_user_args():
		await create_timer(1.0).timeout
		incident.presentation.skip()
		while not is_instance_valid(incident.boss):
			await process_frame
		await create_timer(2.5).timeout
		var boss: CharacterBody3D = incident.boss
		boss.phase_time = 5.0
		await create_timer(.2).timeout
		boss.receive_damage(boss.health + 10, player.global_position)
		var story: Node = incident.presentation
		while not story.all_hands_played or is_instance_valid(story.all_hands):
			await process_frame
		await create_timer(2.0).timeout
		quit()
		return
	while not is_instance_valid(incident.boss):
		if "--capture" in OS.get_cmdline_user_args():
			var story: Node = incident.presentation
			var elapsed: float = (Time.get_ticks_msec() - began) / 1000.0
			var shot: String = ""
			if story.hero_phase == "response":
				var phase_time: float = story.massacre_time - story.hero_phase_at
				shot = "rush" if phase_time < 2.8 else ("wide" if phase_time > 4 and phase_time < 6 else ("hose" if phase_time > 8 else ""))
			elif incident.coworkers.executing() and not incident.coworkers.victim().is_empty() and incident.coworkers.victim().wind > (1.75 if incident.coworkers.victim().fate == "pop" else .65):
				shot = "spell_%d" % incident.coworkers.cavalry_fallen()
			elif story.beat_shot == "casualty":
				shot = "casualty_%d" % incident.coworkers.cavalry_fallen()
			elif story.hero_phase == "walk":
				shot = "aftermath"
			if not shot.is_empty() and not captures.has(shot) and elapsed > 1.5:
				captures[shot] = true
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://logs/vault_%s.png" % shot)
		if incident.coworkers.cavalry_fallen() != fallen:
			fallen = incident.coworkers.cavalry_fallen()
			print("fell %d at %.1fs" % [fallen, (Time.get_ticks_msec() - began) / 1000.0])
		await process_frame
	print("the fight starts at %.1fs" % ((Time.get_ticks_msec() - began) / 1000.0))
	if "--play" in OS.get_cmdline_user_args():
		playing = true
		player.camera_rig.set_capture(true)
		return
	await create_timer(6.0).timeout
	quit()
