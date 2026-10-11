extends SceneTree
## Render the expanded arena, or start a playable boss retry with --play.
var scene: Node3D
var player: CharacterBody3D

func _initialize() -> void:
	_run.call_deferred()

func _process(_delta: float) -> bool:
	if not "--play" in OS.get_cmdline_user_args():
		paused = false
		if player != null:
			player.camera_rig.controls_active = true
	return false

func shot(camera: Camera3D, at: Vector3, target: Vector3, label: String) -> void:
	camera.position = at
	camera.look_at(target)
	for i in range(40):
		await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://logs/arena_%s.png" % label)

func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	player.camera_rig.set_capture(true)
	var incident: Node = scene.get_node("Incident")
	incident.presentation.skip()
	await process_frame
	incident._cleanup()
	for next in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	player.position = Vector3(9,.05,-32)
	await create_timer(.3).timeout
	incident.presentation.skip()
	while not is_instance_valid(incident.boss):
		await process_frame
	if "--play" in OS.get_cmdline_user_args():
		return
	incident.boss.set_physics_process(false)
	for canvas: Node in scene.find_children("*", "CanvasLayer", true, false):
		canvas.hide()
	Engine.time_scale = 1.0
	player.max_health = 1000000
	player.health = 1000000
	player.camera_rig.set_process_unhandled_input(false)
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.fov = 76
	camera.make_current()
	if "--destruction" in OS.get_cmdline_user_args():
		await destruction_preview(incident, camera)
		quit()
		return
	await shot(camera, Vector3(9,5.0,-32.5),Vector3(9,2,-42),"wide")
	await shot(camera, Vector3(8,3.5,-35),Vector3(-.4,2,-38),"service")
	await shot(camera, Vector3(2.5,2.5,-38.2),Vector3(-.8,1.8,-38.75),"power")
	await shot(camera, Vector3(10,2.5,-43),Vector3(9,3,-50),"ledger")
	var prop: Node3D = incident.room.get_node("VaultBreakable0")
	prop.receive_damage(100,prop.global_position+Vector3(1,0,1))
	await create_timer(1.5).timeout
	await shot(camera,Vector3(5,2.8,-32.8),prop.global_position+Vector3.UP*.4,"debris")
	incident.boss.set_physics_process(true)
	camera.position = Vector3(9,4,-32.5)
	camera.look_at(Vector3(9,1.4,-39))
	var samples: Array[float] = []
	var start: int = Time.get_ticks_usec()
	var previous: int = start
	while Time.get_ticks_usec()-start < 15000000:
		await process_frame
		var now: int = Time.get_ticks_usec()
		if now-start > 5000000:
			samples.append((now-previous)/1000.0)
		previous = now
	samples.sort()
	print("ARENA PERFORMANCE ",JSON.stringify({"resolution":str(root.size),"samples":samples.size(),"median_ms":samples[samples.size()/2],"p95_ms":samples[int(samples.size()*.95)],"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"scenario":"stationary wide camera, active boss, 10 seconds after 5 second warmup"}))
	quit()


## A controlled real-time ring release against the actual six authored arena props.
func destruction_preview(incident: Node, camera: Camera3D) -> void:
	var boss: CharacterBody3D = incident.boss
	boss.position = Vector3(9,.05,-40)
	boss.moves.cancel()
	player.position = Vector3(9,.05,-32)
	player.invulnerable_left = 100
	call_group("breakables", "reset_prop")
	await shot(camera, Vector3(12,3.8,-31.8), Vector3(8,1,-41), "boss_before")
	boss.moves.turn = boss.moves.ORDER.find("decommission")
	boss.moves.start(player)
	await create_timer(2.12).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://logs/arena_boss_ring.png")
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://logs/arena_boss_after.png")
	print("Rendered boss ring destruction; remaining intact props: ", get_nodes_in_group("breakables").filter(func(prop: Node) -> bool: return prop.health > 0).size())
