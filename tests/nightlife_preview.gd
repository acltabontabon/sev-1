extends SceneTree
## Independent street preview; does not modify the shared finale preview.
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
	finale._beat("grief")
	finale._beat("desk")
	finale._beat("street")
	for frame in range(430):
		finale.tick(1.0 / 60.0)
		await physics_frame
		if frame in [30, 180, 410]:
			await RenderingServer.frame_post_draw
			var path: String = "res://logs/nightlife_%d.png" % frame
			root.get_texture().get_image().save_png(path)
			print("SHOT ", path)
	finale.finish(false)
	await process_frame
	quit()
