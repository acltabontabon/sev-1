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
	incident.choose_system(3)
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
	incident.choose_system(3)
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
	var lineup: Array = [["record", -5.0], ["blocker", -2.6], ["invite", 2.6], ["scope", 5.0]]
	for entry: Array in lineup:
		var actor: CharacterBody3D = incident._spawn_entry([entry[0], "A1"], incident.alive)
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
