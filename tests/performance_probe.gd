extends SceneTree
## Frame-time probe over a scripted run of the current Incident 001: walking the office,
## the first outbreak cutscene, melee with specials and kill cams, the dense second
## encounter, the omnislash ultimate, the vault arrival and the boss. Rendered (not
## headless), High quality preferences, VSync off so the cost per frame shows.
## sh tools/godot.sh --path . --resolution 1920x1080 --script tests/performance_probe.gd
## Writes builds/performance_probe.json. It measures smoothness; it does not judge fun.
const HITCH_MS: float = 33.3
const BUDGET_MS: float = 16.667

var scene: Node
var incident: Node
var player: CharacterBody3D
var phase: String = ""
var frames: Array[Dictionary] = []
var events: Array[String] = []
var viewport_rid: RID
var compiled: int = 0
var last_state: Dictionary = {}
var last_nodes: int = 0


## What is on screen this frame, so a hitch can be tied to what just appeared.
func _state() -> Dictionary:
	var hud: Node = scene.get_node("HUD")
	var story: Node = incident.presentation
	return {"beat": story.beat_shot, "lower_third": story.lower_third.visible, "cut_in": hud.cut_in.visible,
		"streak": hud.streak.visible, "notice": hud.notice.visible, "banner": hud.banner.visible,
		"dialogue": incident.dialogue.is_open(), "hud": hud.visible}


func _initialize() -> void:
	_run.call_deferred()
	create_timer(400, true).timeout.connect(func() -> void: print("PROBE TIMEOUT"); quit(1))


func _process(_delta: float) -> bool:
	# Focus loss releases capture and pauses; the probe plays on regardless.
	if paused:
		paused = false
	if player != null:
		player.camera_rig.controls_active = true
	return false


func note(event: String) -> void:
	events.append(event)


## Play `seconds` of real time under `label`, calling `act` each frame, sampling frame cost.
func play(label: String, seconds: float, act: Callable = Callable()) -> void:
	phase = label
	var start: int = Time.get_ticks_usec()
	var previous: int = start
	while Time.get_ticks_usec() - start < int(seconds * 1000000.0):
		if act.is_valid():
			act.call()
		await process_frame
		var now: int = Time.get_ticks_usec()
		var total_compiled: int = 0
		for monitor in [Performance.PIPELINE_COMPILATIONS_CANVAS, Performance.PIPELINE_COMPILATIONS_MESH, Performance.PIPELINE_COMPILATIONS_SURFACE, Performance.PIPELINE_COMPILATIONS_DRAW, Performance.PIPELINE_COMPILATIONS_SPECIALIZATION]:
			total_compiled += int(Performance.get_monitor(monitor))
		var pipelines: int = total_compiled - compiled
		compiled = total_compiled
		var state: Dictionary = _state()
		for key in state:
			if last_state.has(key) and state[key] != last_state[key]:
				note("%s→%s" % [key, state[key]])
		last_state = state
		var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		if last_nodes > 0 and absi(nodes - last_nodes) > 20:
			note("nodes %+d" % (nodes - last_nodes))
		last_nodes = nodes
		frames.append({"pipelines": pipelines,
			"phase": label, "ms": float(now - previous) / 1000.0,
			"cpu_process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"cpu_physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			"gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid),
			"render_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"events": ", ".join(events)})
		events.clear()
		previous = now


func nearest_enemy() -> CharacterBody3D:
	var best: CharacterBody3D = null
	for node in get_nodes_in_group("enemies"):
		var enemy: CharacterBody3D = node as CharacterBody3D
		if enemy != null and enemy.health > 0 and enemy.visible and (best == null or enemy.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position)):
			best = enemy
	return best


## Fight like a player who mashes: close in, combo, and fire specials off cooldown.
func brawl() -> void:
	var foe: CharacterBody3D = nearest_enemy()
	if foe == null:
		return
	var offset: Vector3 = player.global_position - foe.global_position
	offset.y = 0
	if offset.length() > 2.2:
		player.global_position = foe.global_position + (offset.normalized() if offset.length() > .1 else Vector3.BACK) * 1.6
	player.camera_rig.rotation.y = atan2(offset.x, offset.z)
	var specials: Node = player.specials
	if specials.wave_cooldown <= 0 and specials.reply_all():
		note("reply_all")
	elif specials.spin_cooldown <= 0 and specials.circle_back():
		note("circle_back")
	elif specials.dash_cooldown <= 0 and specials.blame_shift():
		note("blame_shift")
	elif not player.melee.attacking or player.melee.remaining_time() < .18:
		player.request_attack()


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	incident = scene.get_node("Incident")
	player = scene.get_node("Player")
	var preferences: RefCounted = load("res://game/release/preferences.gd").new()
	preferences.apply(scene)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	viewport_rid = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport_rid, true)
	player.max_health = 1000000
	player.health = 1000000
	player.camera_rig.set_capture(true)
	await play("startup", 2.0)
	incident.presentation.skip()
	await play("explore", 7.0, func() -> void:
		Input.action_press("move_forward")
		player.camera_rig.rotation.y += .012)
	Input.action_release("move_forward")
	# The first wave: set one off the way a player would, by talking (no hit).
	while incident.hosts.is_empty():
		await process_frame
	player.global_position = incident._on_floor(incident.hosts[0].global_position + Vector3(0, 0, 2.0))
	await play("walk_to_wave", 1.0)
	note("outbreak")
	incident._break_out(incident.hosts[0], "timeout")
	await play("outbreak_cutscene", 5.0)
	await play("fight_wave_1", 14.0, brawl)
	# The second encounter: the dense waves (Blocker shields, meeting zones, Scope Creep).
	incident._cleanup()
	for next in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO]:
		incident._enter(next)
	while incident.hosts.is_empty():
		await process_frame
	await play("encounter_2_setup", 2.0)
	incident._break_out(incident.hosts[0], "hit")
	note("encounter_2_breakout")
	await play("fight_encounter_2", 14.0, brawl)
	# The ultimate among whatever is left (spawn a crowd for it if the floor is clear).
	if nearest_enemy() == null or get_nodes_in_group("enemies").size() < 3:
		for at: Vector3 in [Vector3(-2, .05, 2), Vector3(2, .05, 2), Vector3(0, .05, -1)]:
			var foe: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
			foe.position = at
			foe.reveal()
		player.global_position = Vector3(0, .05, 4)
		await play("ultimate_setup", 1.0)
	player.specials.focus = 100.0
	note("force_rollback")
	player.specials.rollback()
	await play("ultimate_omnislash", 6.0)
	# The vault: the gate, the arrival, then the boss.
	incident._cleanup()
	incident._enter(incident.Stage.BOSS)
	await play("gate_opens", 2.0)
	player.global_position = Vector3(9, .05, -31.5)
	note("vault_entered")
	await play("boss_arrival", 7.0)
	await play("boss_fight", 12.0, brawl)
	_report()
	quit()


func _report() -> void:
	var phases: Array[String] = []
	for frame in frames:
		if not phases.has(frame.phase):
			phases.append(frame.phase)
	var report: Dictionary = {"resolution": str(root.size), "renderer": "Forward+ / Metal, High quality (SSAO, glow, MSAA 2x), VSync off",
		"hardware": OS.get_processor_name(), "gpu": RenderingServer.get_video_adapter_name(), "phases": {}, "hitches": []}
	var everything: Array[float] = []
	for name in phases:
		var times: Array[float] = []
		var gpu: Array[float] = []
		var cpu: Array[float] = []
		var draws: float = 0
		for frame in frames:
			if frame.phase == name:
				times.append(frame.ms)
				gpu.append(frame.gpu_ms)
				cpu.append(frame.cpu_process_ms)
				draws = maxf(draws, frame.draw_calls)
		if name != "startup":
			everything.append_array(times)
		report.phases[name] = _stats(times).merged({"gpu_p50_ms": _pct(gpu, .5), "gpu_p95_ms": _pct(gpu, .95), "process_p95_ms": _pct(cpu, .95), "max_draw_calls": draws})
	report["overall_excluding_startup"] = _stats(everything)
	for frame in frames:
		if frame.ms > HITCH_MS and frame.phase != "startup":
			report.hitches.append(frame)
	var output: FileAccess = FileAccess.open("res://builds/performance_probe.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	print("PERF ", JSON.stringify(report.overall_excluding_startup))
	for name in report.phases:
		var entry: Dictionary = report.phases[name]
		print("PHASE %-20s fps %6.1f  p50 %5.2f  p95 %5.2f  p99 %6.2f  max %6.2f ms  >16.7: %3d  >33: %2d  gpu p95 %5.2f  proc p95 %5.2f  draws %d" % [name, entry.mean_fps, entry.p50_ms, entry.p95_ms, entry.p99_ms, entry.max_ms, entry.over_budget, entry.hitches, entry.gpu_p95_ms, entry.process_p95_ms, entry.max_draw_calls])
	for hitch: Dictionary in report.hitches:
		print("HITCH %-20s %6.1f ms  process %5.1f  physics %5.1f  render_cpu %5.1f  pipelines compiled %d  [%s]" % [hitch.phase, hitch.ms, hitch.cpu_process_ms, hitch.cpu_physics_ms, hitch.render_cpu_ms, hitch.pipelines, hitch.events])
	var compiled_by_phase: Dictionary = {}
	for frame in frames:
		compiled_by_phase[frame.phase] = compiled_by_phase.get(frame.phase, 0) + frame.pipelines
	print("PIPELINES ", compiled_by_phase)


func _pct(values: Array[float], at: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	return sorted[mini(sorted.size() - 1, int(sorted.size() * at))]


func _stats(times: Array[float]) -> Dictionary:
	var total: float = 0.0
	var over: int = 0
	var hitches: int = 0
	for value in times:
		total += value
		over += 1 if value > BUDGET_MS else 0
		hitches += 1 if value > HITCH_MS else 0
	return {"frames": times.size(), "mean_fps": 1000.0 / (total / maxf(1, times.size())), "p50_ms": _pct(times, .5), "p95_ms": _pct(times, .95),
		"p99_ms": _pct(times, .99), "max_ms": _pct(times, 1.0), "over_budget": over, "hitches": hitches}
