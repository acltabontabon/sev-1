extends SceneTree
func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	if paused:
		paused = false
	return false


func _run() -> void:
	var scene: Node = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var preferences: RefCounted = load("res://game/release/preferences.gd").new()
	preferences.apply(scene)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var player: CharacterBody3D = scene.get_node("Player")
	player.camera_rig.set_capture(true)
	var incident: Node = scene.get_node("Incident")
	var previous: int = Time.get_ticks_usec()
	var start: int = previous
	var slow: Array = []
	var fly: Array[float] = []
	var rest: Array[float] = []
	while Time.get_ticks_usec() - start < 52000000:
		player.camera_rig.controls_active = true
		await process_frame
		var now: int = Time.get_ticks_usec()
		var ms: float = (now - previous) / 1000.0
		previous = now
		if now - start < 400000:
			continue
		if incident.stage == 0 and incident.stage_time < 8.6:
			fly.append(ms)
		else:
			rest.append(ms)
		if ms > 25.0:
			slow.append("%.1f ms at stage %d %.2fs" % [ms, incident.stage, incident.stage_time])
	fly.sort()
	rest.sort()
	print("FLY frames %d median %.2f p95 %.2f p99 %.2f max %.2f" % [fly.size(), fly[fly.size() / 2], fly[int(fly.size() * .95)], fly[int(fly.size() * .99)], fly.back()])
	print("REST frames %d median %.2f p95 %.2f p99 %.2f max %.2f" % [rest.size(), rest[rest.size() / 2], rest[int(rest.size() * .95)], rest[int(rest.size() * .99)], rest.back()])
	print("SLOW ", slow)
	quit()
