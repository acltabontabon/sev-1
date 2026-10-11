extends SceneTree
## Milestone 12 graphical probe: menu, opening shots. Captures for human visual review;
## it does not establish fun, comedy or audio quality.
## sh tools/godot.sh --path . --script tests/m12_preview.gd -- [--1080] [--only=menu]
var app: Node
var prefix: String = "m12_720"
var only: String = ""
var samples: Array[float] = []
var last: int = 0


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int = 10) -> void:
	for index in range(count):
		await process_frame


func sample() -> void:
	var now: int = Time.get_ticks_usec()
	if last > 0:
		samples.append((now - last) / 1000.0)
	last = now


func report(label: String) -> void:
	samples.sort()
	if samples.is_empty():
		return
	var total: float = 0.0
	for value in samples:
		total += value
	print("PERF %s: frames %d avg %.2f ms (%.1f fps) p95 %.2f ms max %.2f ms draw calls %d" % [label, samples.size(), total / samples.size(), 1000.0 * samples.size() / total, samples[int(samples.size() * .95)], samples[-1], RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	samples.clear()
	last = 0


func shot(title: String) -> void:
	await frames(2)
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://builds/" + prefix + "_" + title + ".png")
	print("CAPTURE ", title)


func clear_operations(incident: Node3D, _player: CharacterBody3D) -> void:
	incident.presentation.skip()
	await frames(2)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds")
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--1080":
			root.size = Vector2i(1920, 1080)
			prefix = "m12_1080"
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	DirAccess.remove_absolute("user://m12_preview_nonexistent.cfg")
	app = load("res://game/release/front_end.tscn").instantiate()
	app.preferences.path = "user://m12_preview_nonexistent.cfg"
	root.add_child(app)
	current_scene = app
	await frames(30)
	await shot("menu")
	for index in range(150):
		await process_frame
		sample()
	report("menu")
	await shot("menu_notice")
	app.open_controls()
	await frames(8)
	await shot("page_controls")
	app.go_back()
	app.open_logoff()
	await frames(8)
	await shot("page_logoff")
	app.go_back()
	app.open_settings()
	await frames(8)
	await shot("page_settings")
	app.go_back()
	if only == "menu":
		quit()
		return
	if only == "cast":
		await cast()
		quit()
		return
	if only == "finale":
		await finale()
		quit()
		return
	if only == "ui":
		await ui_pass()
		quit()
		return
	if only == "enemies":
		await roster()
		quit()
		return
	if only == "omnislash":
		await omnislash()
		quit()
		return
	if only == "lineup":
		await lineup()
		quit()
		return
	if only == "finishers":
		await finishers()
		quit()
		return
	if only == "specials":
		await specials()
		quit()
		return
	if only == "talk":
		await talk()
		quit()
		return
	if only == "outbreak":
		await outbreak()
		quit()
		return
	if only == "battle":
		await battle()
		quit()
		return
	if only == "attacks":
		await attacks()
		quit()
		return
	if only == "office":
		await office_life()
		quit()
		return
	if only == "areas":
		await tour()
		quit()
		return
	app.start_incident()
	var story: CanvasLayer = app.session.get_node("Incident").presentation
	var incident: Node = app.session.get_node("Incident")
	var marks: Array = [[1.5, "op_wide"], [6.2, "op_monitor"], [9.8, "op_relax"], [12.6, "op_logoff"], [14.4, "op_alarm"], [17.8, "op_face"], [19.8, "op_eta"], [25.0, "op_tangina"], [27.3, "op_flicker"], [29.6, "op_emerge"], [31.6, "op_armed"], [33.8, "op_title"], [37.0, "op_handover"]]
	for mark: Array in marks:
		while incident.stage == incident.Stage.ALERT and incident.stage_time < mark[0]:
			app.session.get_node("Player/CameraRig").controls_active = true
			# Losing window focus opens the pause page; the probe keeps the clock running.
			if not app.page.is_empty():
				app.resume_incident()
			await process_frame
			sample()
		await shot(mark[1])
		last = 0
	report("opening")
	app.main_menu()
	await frames(5)
	app.queue_free()
	await frames(3)
	quit()


## Free camera tour of the authored areas, with the run in its exploration stage.
func tour() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	incident.presentation.skip()
	await frames(10)
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	var camera: Camera3D = Camera3D.new()
	app.session.add_child(camera)
	camera.make_current()
	var stops: Array = [
		["area_a_desks", Vector3(-3.2, 2.6, 13.5), Vector3(-7.5, 1.0, 2.0)],
		["area_a_stories", Vector3(-4.2, 1.8, 2.6), Vector3(-6.5, 1.2, -.5)],
		["area_d_operations", Vector3(1.5, 2.4, -5.0), Vector3(-1.7, 2.0, -15.5)],
		["area_b_corridor", Vector3(16.3, 2.0, 14.0), Vector3(16.3, 2.2, -6.0)],
		["area_b_quick_sync", Vector3(19.4, 2.6, -2.8), Vector3(24.5, 1.0, -11.0)],
		["area_c_pantry", Vector3(19.4, 2.4, 11.8), Vector3(25.5, 1.0, 5.5)],
		["area_e_gate", Vector3(12.8, 2.0, -11.6), Vector3(9.0, 2.0, -16.0)],
	]
	for stop: Array in stops:
		camera.position = stop[1]
		camera.look_at(stop[2])
		await frames(8)
		await shot(stop[0])
	for next in [incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	app.session.get_node("Player").position = Vector3(9, .05, -24.5)
	for stop: Array in [["area_e_corridor", Vector3(9.0, 2.2, -17.5), Vector3(8.0, 1.6, -28.0)], ["area_e_deploy", Vector3(10.6, 1.8, -21.0), Vector3(5.6, 1.9, -23.3)], ["area_e_vault", Vector3(9.0, 3.4, -31.0), Vector3(9.0, 1.8, -44.0)]]:
		camera.position = stop[1]
		camera.look_at(stop[2])
		await frames(30)
		await shot(stop[0])
	# Gameplay camera measurements in the heaviest views.
	camera.queue_free()
	var player: Node3D = app.session.get_node("Player")
	for spot: Array in [["perf_office", Vector3(0, .05, 8), 0.0], ["perf_wing", Vector3(16.3, .05, 12), 0.0], ["perf_corridor", Vector3(9, .05, -18), 0.0], ["perf_vault", Vector3(9, .05, -33), 0.0]]:
		player.position = spot[1]
		player.camera_rig.reset_view()
		for index in range(20):
			await process_frame
		last = 0
		for index in range(240):
			app.session.get_node("Player/CameraRig").controls_active = true
			await process_frame
			sample()
		report(spot[0])
	app.main_menu()
	await frames(5)


## Containment-style lineup for visual review of silhouettes, tells and feedback.
func roster() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	await frames(10)
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	player.max_health = 10000
	player.health = 10000
	player.position = Vector3(0, .05, 2)
	player.camera_rig.reset_view()
	var lineup: Array = [["record", Vector3(-1.6, .05, -1.5)], ["blocker", Vector3(.2, .05, -3.2)], ["record", Vector3(1.8, .05, -1.8)], ["invite", Vector3(-3.5, .05, -6.5)], ["scope", Vector3(3.2, .05, -4.5)]]
	var actors: Array = []
	for entry: Array in lineup:
		var actor: CharacterBody3D = incident._spawn_entry([entry[0], "A1"], incident.alive)
		actor.position = entry[1]
		actors.append(actor)
	await frames(90)
	await shot("enemies_intro")
	actors[1].cast_cooldown = 0
	actors[4].grow()
	actors[4].grow()
	await frames(40)
	await shot("enemies_cast")
	await frames(60)
	actors[0].receive_damage(10, player.position)
	await frames(3)
	await shot("enemies_blocked")
	actors[3].zone_cooldown = 0
	await frames(50)
	await shot("enemies_zone")
	last = 0
	for index in range(300):
		app.session.get_node("Player/CameraRig").controls_active = true
		await process_frame
		sample()
	report("combat_five_enemies")
	app.main_menu()
	await frames(5)


## Battle mode: onset grade, the elemental combo on a live wave, enemy spells, a perf sample.
func battle() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	await live(2.5)
	# Waves wait to be set off now; the probe lets the first one snap on its own.
	if incident.armed:
		incident._break_out(incident.hosts[0], "timeout")
	while incident.presentation.beat_shot == "outbreak":
		await live(.1)
	await live(.6)
	var to_site: Vector3 = incident.wave_site - player.global_position
	player.camera_rig.rotation.y = atan2(-to_site.x, -to_site.z)
	player.camera_rig.focus = Vector3.INF
	await live(.3)
	await shot("roam_beacon")
	player.max_health = 10000
	player.health = 10000
	incident.presentation.feed.modulate.a = 0.0
	var foe: CharacterBody3D = incident.alive[0]
	player.global_position = foe.global_position + Vector3(0, 0, 2.0)
	player.visual.rotation.y = 0.0
	player.camera_rig.reset_view()
	for actor: CharacterBody3D in incident.alive:
		actor.engage(player.global_position, false)
	await live(.12)
	await shot("battle_onset")
	await live(1.4)
	await shot("battle_engaged")
	for step in range(3):
		var offset: Vector3 = foe.global_position - player.global_position
		player.visual.rotation.y = atan2(-offset.x, -offset.z)
		player.request_attack()
		while player.melee.attacking and player.melee.elapsed < player.melee.windup + player.melee.active_time * .6:
			app.session.get_node("Player/CameraRig").controls_active = true
			await process_frame
		await shot("battle_element_%d" % step)
		while player.melee.attacking:
			await process_frame
	await live(.8)
	await shot("battle_spells")
	last = 0
	for index in range(300):
		app.session.get_node("Player/CameraRig").controls_active = true
		if index % 40 == 0 and not player.melee.attacking:
			player.request_attack()
		await process_frame
		sample()
	report("battle_mode_combat")
	app.main_menu()
	await frames(5)


## Force Rollback, omnislash style: blinks, cuts, the return, the slam's hero shot.
func omnislash() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	await live(.5)
	player.max_health = 10000
	player.health = 10000
	incident.presentation.feed.modulate.a = 0.0
	player.global_position = Vector3(0, .05, 5)
	player.camera_rig.rotation.y = 0.0
	player.camera_rig.reset_view()
	var spare: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
	spare.position = Vector3(-9, .05, -12)
	spare.reveal()
	spare.set_physics_process(false)
	for index in range(4):
		var foe: CharacterBody3D = incident._spawn_entry([["record", "scope", "blocker", "record"][index], "A1"], incident.alive)
		foe.position = Vector3(0, .05, 5) + Vector3(cos(index * 1.7), 0, sin(index * 1.7)) * 3.5
		foe.reveal()
		foe.max_health = 400
		foe.health = 400
		foe.set_physics_process(false)
	await live(1.0)
	player.specials.add_focus(100)
	player.specials.rollback()
	await live(.15)
	await shot("omni_call")
	var taken: Dictionary = {}
	while player.specials.omnislashing():
		var step: int = player.specials.omni_index
		if step in [1, 3, 5] and not taken.has(step):
			taken[step] = true
			await live(.06)
			await shot("omni_cut_%d" % step)
		await process_frame
	await live(.3)
	await shot("omni_slam")
	await live(.9)
	await shot("omni_hero")
	app.main_menu()
	await frames(5)


## The monster lineup under plain light, close up: one of each kind, then hurt.
func lineup() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	await live(.4)
	player.global_position = Vector3(-6, .05, 12)
	var monsters: Array[CharacterBody3D] = []
	var kinds: Array = ["record", "blocker", "invite", "scope", "bug"]
	for index in range(kinds.size()):
		var foe: CharacterBody3D = incident._spawn_entry([kinds[index], "A1"], incident.alive)
		foe.position = Vector3(-2.0 + index * 2.4, .05, 3.0)
		foe.reveal()
		foe.set_physics_process(false)
		foe.visual.rotation.y = 0.0
		monsters.append(foe)
	var boss: CharacterBody3D = incident.RECORD.instantiate()
	boss.set_script(incident.VARIANCE)
	boss.position = Vector3(10.5, .05, 2.0)
	incident.add_child(boss)
	incident.actors.append(boss)
	boss.set_physics_process(false)
	boss.visual.rotation.y = 0.0
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1, .97, .92)
	light.light_energy = 3.0
	light.omni_range = 14.0
	light.position = Vector3(4, 4, 7)
	incident.add_child(light)
	var cam: Camera3D = incident.presentation.camera
	app.session.get_node("HUD").visible = false
	for view: Array in [["lineup_wide", Vector3(4.5, 1.6, 9.5), Vector3(4.5, 1.0, 3.0), 55.0], ["lineup_close", Vector3(-.8, 1.3, 5.6), Vector3(.2, 1.0, 3.0), 45.0], ["lineup_boss", Vector3(10.5, 2.4, 7.5), Vector3(10.5, 1.8, 2.0), 45.0]]:
		cam.global_position = view[1]
		cam.look_at(view[2])
		cam.fov = view[3]
		for frame in range(20):
			cam.make_current()
			await process_frame
		await shot(view[0])
	cam.global_position = Vector3(-1.2, 1.9, 7.5)
	cam.look_at(Vector3(-2.0, 1.8, 3.0))
	cam.fov = 50.0
	monsters[0].next_bark_ms = 0
	monsters[0].bark("spot")
	for frame in range(18):
		cam.make_current()
		await process_frame
	await shot("lineup_bark")
	for foe: CharacterBody3D in monsters:
		foe.health = roundi(foe.max_health * .3)
	cam.global_position = Vector3(4.5, 1.6, 9.5)
	cam.look_at(Vector3(4.5, 1.0, 3.0))
	for frame in range(20):
		cam.make_current()
		await process_frame
	await shot("lineup_hurt")
	app.main_menu()
	await frames(5)


## Finishers: a Reply All that slices a line (kill cam), the aftermath, and the
## rollback slam's own kill cam.
func finishers() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	await live(.5)
	player.max_health = 10000
	player.health = 10000
	incident.presentation.feed.modulate.a = 0.0
	player.global_position = Vector3(0, .05, 6)
	player.camera_rig.rotation.y = 0.0
	player.camera_rig.reset_view()
	var spare: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
	spare.position = Vector3(-9, .05, -12)
	spare.reveal()
	spare.set_physics_process(false)
	for at: Vector3 in [Vector3(-.4, .05, 2.5), Vector3(.5, .05, .5), Vector3(-.2, .05, -1.5)]:
		var foe: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
		foe.position = at
		foe.reveal()
		foe.max_health = 40
		foe.health = 40
		foe.set_physics_process(false)
	await live(1.0)
	player.visual.rotation.y = 0.0
	player.specials.reply_all()
	while incident.presentation.beat_shot != "killcam":
		await live(.01)
	for mark: Array in [[.08, "finisher_killcam_impact"], [.7, "finisher_killcam"], [1.35, "finisher_killcam_hero"]]:
		while incident.presentation.beat_shot == "killcam" and (Time.get_ticks_msec() - incident.presentation.killcam_start) / 1000.0 < mark[0]:
			await process_frame
		await shot(mark[1])
	while incident.presentation.beat_shot == "killcam":
		await live(.02)
	await live(.05)
	await shot("finisher_streak")
	await live(.5)
	await shot("finisher_aftermath")
	# One clean cut, up close, from the gameplay camera.
	incident.presentation.killcam_ready = Time.get_ticks_msec() + 60000
	var cut: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
	cut.position = player.global_position + Vector3(0, 0, -3.2)
	cut.reveal()
	cut.set_physics_process(false)
	await live(.6)
	var side_cam: Camera3D = incident.presentation.camera
	side_cam.global_position = cut.global_position + Vector3(4.2, 1.4, .6)
	side_cam.look_at(cut.global_position + Vector3.UP * .9)
	side_cam.fov = 50.0
	side_cam.make_current()
	app.session.get_node("HUD").visible = false
	cut.set_meta("kill_style", "slice")
	cut.receive_damage(1000, player.global_position)
	for mark: Array in [[.12, "finisher_slice_cut"], [.35, "finisher_slice_close"], [.9, "finisher_slice_landed"]]:
		var until: int = Time.get_ticks_msec() + int(mark[0] * 1000)
		while Time.get_ticks_msec() < until:
			side_cam.make_current()
			await process_frame
		await shot(mark[1])
	app.session.get_node("HUD").visible = true
	incident.presentation.killcam_ready = 0
	for index in range(4):
		var foe: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
		foe.position = player.global_position + Vector3(cos(index * 1.6), 0, sin(index * 1.6)) * 2.5
		foe.reveal()
		foe.set_physics_process(false)
	await live(.5)
	player.specials.add_focus(100)
	player.specials.rollback()
	while incident.presentation.beat_shot != "killcam":
		await live(.01)
	await live(.15)
	await shot("finisher_rollback_cam")
	await live(1.2)
	await shot("finisher_rollback_after")
	app.main_menu()
	await frames(5)


## The special moves: Reply All mid-flight, then Force Rollback's leap and slam.
func specials() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	await live(.5)
	player.max_health = 10000
	player.health = 10000
	incident.presentation.feed.modulate.a = 0.0
	player.global_position = Vector3(0, .05, 6)
	player.camera_rig.rotation.y = 0.0
	player.camera_rig.reset_view()
	var foes: Array[CharacterBody3D] = []
	for at: Vector3 in [Vector3(-.6, .05, 1.5), Vector3(.7, .05, -2.0), Vector3(0, .05, -5.0)]:
		var foe: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
		foe.position = at
		foe.reveal()
		foes.append(foe)
	await live(1.2)
	for foe: CharacterBody3D in foes:
		foe.set_physics_process(false)
	player.visual.rotation.y = 0.0
	player.specials.reply_all()
	await live(.08)
	await shot("special_wave_cutin")
	while player.specials.blades.is_empty():
		await live(.01)
	await live(.12)
	await shot("special_wave_launch")
	await live(.2)
	await shot("special_wave_cut")
	await live(1.0)
	for at: Vector3 in [Vector3(2.5, .05, 4.0), Vector3(-2.8, .05, 7.0), Vector3(1.5, .05, 9.0)]:
		var foe: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
		foe.position = at
		foe.reveal()
		foe.set_physics_process(false)
	player.specials.add_focus(100)
	await live(.6)
	await shot("special_focus_ready")
	player.specials.rollback()
	await live(.15)
	await shot("special_rollback_cutin")
	await live(.1)
	await shot("special_rollback_leap")
	while player.specials.queued != "":
		await live(.01)
	await live(.08)
	await shot("special_rollback_slam")
	await live(.5)
	await shot("special_rollback_after")
	# Blame Shift through a fresh line, then Circle Back among a ring.
	player.global_position = Vector3(0, .05, 7)
	player.camera_rig.rotation.y = 0.0
	player.camera_rig.reset_view()
	for at: Vector3 in [Vector3(0, .05, 3.5), Vector3(.8, .05, 1.5), Vector3(-.6, .05, -.5)]:
		var foe: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
		foe.position = at
		foe.reveal()
		foe.set_physics_process(false)
	await live(.8)
	player.specials.blame_shift()
	await live(.1)
	await shot("special_dash_through")
	while player.specials.dash_left > 0:
		await live(.01)
	await live(.02)
	await shot("special_dash_arrive")
	await live(.15)
	await shot("special_dash_cut")
	await live(1.0)
	player.global_position = Vector3(3, .05, 4)
	for index in range(4):
		var foe: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
		foe.position = Vector3(3, .05, 4) + Vector3(cos(index * 1.6), 0, sin(index * 1.6)) * 2.2
		foe.reveal()
	await live(.3)
	player.specials.circle_back()
	await live(.5)
	await shot("special_spin")
	# Works On My Machine: the stance, then a hit answered.
	await live(2.0)
	player.global_position = Vector3(-3, .05, 2)
	var heckler: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
	heckler.position = Vector3(-3, .05, .4)
	heckler.reveal()
	heckler.set_physics_process(false)
	player.camera_rig.rotation.y = 0.0
	player.camera_rig.reset_view()
	player.specials.counter_cooldown = 0.0
	player.invulnerable_left = 0.0
	await live(.4)
	player.specials.works_on_my_machine()
	await live(.15)
	await shot("special_counter_stance")
	player.receive_damage(20, heckler.global_position)
	await live(.12)
	await shot("special_counter_hit")
	app.main_menu()
	await frames(5)


## Talking to the night shift: the prompt, a conversation, a reply with an effect.
func talk() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	await live(2.5)
	incident.presentation.skip()
	await live(1.0)
	for entry: Array in [["Manager", "talk_manager"], ["Intern", "talk_intern"], ["Recruiter", "talk_recruiter"]]:
		var someone: Dictionary = incident.coworkers.person(entry[0])
		var body: Node3D = someone.body
		player.global_position = incident._on_floor(body.global_position + Vector3(1.4, 0, 1.0))
		player.camera_rig.rotation.y = atan2(1.4, 1.0)
		player.camera_rig.reset_view()
		await live(.4)
		if entry[0] == "Manager":
			await shot("talk_prompt")
		incident.talk(incident.talk_target())
		await frames(20)
		await shot(entry[1] + "_establish")
		incident.dialogue.shown = 999.0
		await live(1.7)
		await shot(entry[1])
		incident.dialogue.choose(0)
		await frames(20)
		await shot(entry[1] + "_you")
		incident.dialogue.advance()
		incident.dialogue.advance()
		incident.dialogue.shown = 999.0
		await frames(30)
		await shot(entry[1] + "_reply")
		incident.dialogue.close()
		await frames(3)
		if not app.page.is_empty():
			app.resume_incident()
	for view: Array in [["cards_pantry_hall", Vector3(15.2, .05, -2.0), PI], ["cards_wing", Vector3(16.2, .05, 6.0), 0.0]]:
		player.global_position = view[1]
		player.camera_rig.rotation.y = view[2]
		player.camera_rig.reset_view()
		await live(.6)
		await shot(view[0])
	app.main_menu()
	await frames(5)


## A wave breaking out of the overtime crew, the minimap, and the Quick Sync turning.
func outbreak() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	var story: CanvasLayer = incident.presentation
	story.skip()
	# A planted employee up close, before anything happens.
	await live(.3)
	var host: Node3D = incident.hosts[0]
	player.global_position = incident._on_floor(host.global_position + Vector3(1.6, 0, 1.6))
	player.camera_rig.rotation.y = atan2(1.6, 1.6)
	player.camera_rig.reset_view()
	await live(2.6)
	await shot("outbreak_hover")
	while story.beat_shot != "outbreak":
		await live(.05)
	for mark: Array in [[.7, "outbreak_ticket"], [1.9, "outbreak_turning"], [2.5, "outbreak_burst"], [3.3, "outbreak_monster"]]:
		while story.beat_shot == "outbreak" and story.beat_time < mark[0]:
			await live(.02)
		await shot(mark[1])
	while story.beat_shot == "outbreak":
		await live(.05)
	await live(1.5)
	await shot("minimap_wave")
	# Straight to the investigation: the Quick Sync is already in session.
	for actor: CharacterBody3D in incident.alive.duplicate():
		actor.receive_damage(100000, actor.global_position)
	incident.pending.clear()
	incident.wave_index = incident.waves().size()
	incident.upgrade_pending = false
	incident.stage = incident.Stage.ENCOUNTER_ONE
	incident._enter(incident.Stage.INVESTIGATION)
	await live(.5)
	player.global_position = Vector3(17.2, .05, -8.75)
	player.camera_rig.rotation.y = -PI * .5
	await live(.6)
	await shot("sync_planted")
	player.global_position = Vector3(19.4, .05, -8.75)
	while story.beat_shot != "outbreak":
		await live(.05)
	for mark: Array in [[1.0, "sync_ticket"], [2.7, "sync_burst"]]:
		while story.beat_shot == "outbreak" and story.beat_time < mark[0]:
			await live(.02)
		await shot(mark[1])
	app.main_menu()
	await frames(5)


## Each enemy's strike landing (slash crack, ground quake, splat, meeting drop, cataclysm).
func attacks() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	await live(.5)
	incident.presentation.feed.modulate.a = 0.0
	app.session.get_node("HUD").hide()
	var camera: Camera3D = Camera3D.new()
	app.session.add_child(camera)
	camera.fov = 55
	for kind: String in ["record", "blocker", "scope", "invite", "variance"]:
		incident._cleanup()
		incident._enter(incident.Stage.INVESTIGATION)
		player.max_health = 100000
		player.health = 100000
		player.global_position = Vector3(0, .05, 4)
		player.visual.rotation.y = 0.0
		var actor: CharacterBody3D
		if kind == "variance":
			actor = load("res://game/enemies/incident.tscn").instantiate()
			actor.set_script(load("res://game/incidents/variance.gd"))
			incident.add_child(actor)
			incident.actors.append(actor)
		else:
			actor = incident._spawn_entry([kind, "A1"], incident.alive)
		actor.global_position = Vector3(0, .05, 4 - (3.4 if kind == "variance" else 2.6))
		actor.home = actor.global_position
		actor.engage()
		camera.position = Vector3(5.5, 2.6, 4.2)
		camera.look_at(Vector3(0, .9, 2.4))
		camera.make_current()
		await live(.3)
		if kind == "invite":
			actor.zone_cooldown = 0.0
			await live(1.2)
		else:
			actor.melee.start()
			while actor.melee.attacking and actor.melee.elapsed < actor.melee.windup + .08:
				await process_frame
		await shot("attack_%s" % kind)
		await live(.25)
		await shot("attack_%s_after" % kind)
	incident._cleanup()
	app.main_menu()
	await frames(5)


## The night shift and the patrols: decor, neon, coworkers, sight cones from above.
func office_life() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	await live(6.0)
	incident.presentation.feed.modulate.a = 0.0
	app.session.get_node("HUD").hide()
	var camera: Camera3D = Camera3D.new()
	app.session.add_child(camera)
	camera.fov = 60
	camera.make_current()
	for view: Array in [["office_lounge", Vector3(3.5, 2.6, 6.0), Vector3(9.4, .9, 13.0)],
			["office_desks", Vector3(-2.5, 2.8, 11.0), Vector3(-10.5, 1.0, -1.0)],
			["office_north", Vector3(-1.0, 2.6, -5.0), Vector3(-8.8, 3.0, -15.7)],
			["office_wing", Vector3(16.2, 2.2, 10.0), Vector3(15.0, 1.6, -8.0)],
			["office_pantry_hall", Vector3(15.2, 1.9, -2.0), Vector3(19.0, .6, 9.0)],
			["office_pantry_hall_back", Vector3(17.5, 1.9, 13.0), Vector3(16.0, .6, 0.0)]]:
		if not app.page.is_empty():
			app.resume_incident()
		camera.position = view[1]
		camera.look_at(view[2])
		await live(.3)
		if not app.page.is_empty():
			app.resume_incident()
			await frames(3)
		await shot(view[0])
	var ceiling: Node3D = incident.room.get_node("Ceiling")
	ceiling.hide()
	camera.position = Vector3(2.0, 22.0, 6.0)
	camera.look_at(Vector3(2.0, 0, -1.0))
	camera.fov = 70
	await live(1.5)
	await shot("office_patrols")
	ceiling.show()
	app.main_menu()
	await frames(5)


## Gameplay interface surfaces: chat cards, HUD, change requests, the leadership DM, boss bar.
func ui_pass() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	for index in range(260):
		app.session.get_node("Player/CameraRig").controls_active = true
		await process_frame
	await shot("ui_combat_cards")
	incident.run.change_burnout(45, "preview")
	app.resume_incident()
	incident._offer_upgrade(incident.Stage.INVESTIGATION)
	app.show_page("")
	await frames(10)
	await shot("ui_change_request")
	incident.choose_upgrade(0)
	player.position = incident.CONSOLE_POSITION
	incident.inspect_console()
	app.resume_incident()
	for index in range(20):
		app.session.get_node("Player/CameraRig").controls_active = true
		await process_frame
	await shot("ui_evidence")
	await clear_operations(incident, incident.player)
	app.show_page("")
	await frames(10)
	await shot("ui_leadership_dm")
	incident.choose_corporate(1)
	for next in [incident.Stage.BOSS]:
		incident._cleanup()
		incident._enter(next)
	app.resume_incident()
	player.position = Vector3(9, .05, -33)
	player.camera_rig.reset_view()
	incident.presentation.skip()
	for index in range(200):
		app.session.get_node("Player/CameraRig").controls_active = true
		await process_frame
	await shot("ui_boss")
	app.main_menu()
	await frames(5)


func live(seconds: float) -> void:
	var end: int = Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < end:
		if app.session != null and app.page.is_empty():
			app.session.get_node("Player/CameraRig").controls_active = true
		await process_frame


## Phase F beats: evidence push, vault arrival, both postmortems behind the ending shot.
func finale() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	player.max_health = 10000
	player.health = 10000
	incident.presentation.skip()
	await live(.3)
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	player.position = incident.CONSOLE_POSITION + Vector3(0, .05, 2.0)
	incident.inspect_console()
	await live(1.1)
	await shot("finale_evidence")
	await live(2.0)
	await clear_operations(incident, incident.player)
	incident.choose_corporate(1)
	app.resume_incident()
	incident._cleanup()
	incident._enter(incident.Stage.BOSS)
	player.position = Vector3(9, .05, -29.5)
	player.camera_rig.reset_view()
	await live(1.0)
	player.position = Vector3(9, .05, -31.2)
	await live(2.0)
	await shot("finale_vault_arrival")
	await live(4.5)
	await shot("finale_vault_manifest")
	incident.boss.exposed = true
	incident.boss.receive_damage(100000, player.position)
	await live(4.0)
	await shot("finale_postmortem_win")
	app.restart_incident()
	await live(1.0)
	player.invulnerable_left = 0
	player.receive_damage(100000, Vector3.ZERO)
	await live(4.0)
	await shot("finale_postmortem_loss")
	app.main_menu()
	await frames(5)


## Character lineup for art review: everyone engaged, idle, well lit, in a row.
func cast() -> void:
	app.start_incident()
	var incident: Node = app.session.get_node("Incident")
	var player: CharacterBody3D = app.session.get_node("Player")
	incident.presentation.skip()
	await live(.3)
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 4)
	player.visual.rotation.y = PI
	var lineup: Array = [["record", -5.0], ["blocker", -2.6], ["invite", 2.6], ["scope", 5.0], ["bug", 1.4]]
	var cast_actors: Array[CharacterBody3D] = []
	for entry: Array in lineup:
		var actor: CharacterBody3D = incident._spawn_entry([entry[0], "A1"], incident.alive)
		cast_actors.append(actor)
		actor.engage()
		actor.position = Vector3(entry[1], .05, 1.5)
		actor.set_physics_process(false)
		actor.visual.rotation.y = PI
		if entry[0] == "scope":
			actor.grow()
	var boss: CharacterBody3D = load("res://game/enemies/incident.tscn").instantiate()
	boss.set_script(load("res://game/incidents/variance.gd"))
	boss.position = Vector3(0, .05, -2.2)
	incident.add_child(boss)
	incident.actors.append(boss)
	boss.visual.rotation.y = PI
	incident.presentation.feed.modulate.a = 0.0
	var light: OmniLight3D = OmniLight3D.new()
	light.position = Vector3(0, 3.5, 7)
	light.omni_range = 16
	light.light_energy = 2.2
	app.session.add_child(light)
	var camera: Camera3D = Camera3D.new()
	app.session.add_child(camera)
	camera.position = Vector3(0, 2.0, 8.6)
	camera.look_at(Vector3(0, 1.5, 0))
	camera.fov = 58
	camera.make_current()
	app.session.get_node("HUD").hide()
	await live(1.5)
	await shot("cast_front")
	boss.position = Vector3(0, .05, -4.5)
	for index in range(lineup.size() + 1):
		var subject: CharacterBody3D = cast_actors[index] if index < lineup.size() else boss
		var tall: float = 1.9 if index < lineup.size() else 3.0
		camera.position = subject.global_position + Vector3(.9, tall * .75, 2.6 + tall * .6)
		camera.look_at(subject.global_position + Vector3(0, tall * .55, 0))
		camera.fov = 45
		await live(.25)
		await shot("cast_close_%s" % (lineup[index][0] if index < lineup.size() else "variance"))
	camera.fov = 58
	# The overtime crew: asleep at a desk, on another incident, on a call, fixing the vending machine.
	var crew: Node3D = incident.coworkers
	for pair: Array in [["coworkers_desks", Vector3(-4.6, 2.0, 3.6), Vector3(-8.0, .9, -1.5)], ["coworkers_manager", Vector3(3.0, 1.9, 9.5), crew.get_node("Manager").global_position + Vector3(0, 1.0, 0)], ["coworkers_pantry", Vector3(18.6, 1.9, 13.4), Vector3(21.6, 1.0, 10.4)]]:
		camera.position = pair[1]
		camera.look_at(pair[2])
		player.global_position = pair[2] + Vector3(1.5, -.95, 1.5)
		await live(.4)
		await shot(pair[0])
	camera.position = Vector3(1.1, 1.9, 1.6)
	camera.look_at(player.position + Vector3(0, 1.2, 0))
	camera.fov = 40
	player.visual.rotation.y = PI
	await live(.4)
	await shot("cast_engineer_back")
	camera.position = Vector3(-.9, 1.75, 6.4)
	camera.look_at(player.position + Vector3(0, 1.25, 0))
	player.visual.rotation.y = PI
	await live(.4)
	await shot("cast_engineer_front")
	app.main_menu()
	await frames(5)

