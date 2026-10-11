extends SceneTree
## Independent street preview; does not modify the shared finale preview.
var scene: Node
var finale: Node
var shots: int = 0
var started: bool = false
const CHECKPOINTS: Array[float] = [.15, 1.3, 3.9, 7.0, 10.5]


func _initialize() -> void:
	_run.call_deferred()


func _process(delta: float) -> bool:
	paused = false
	if started and is_instance_valid(finale):
		finale.tick(delta)
		var elapsed: float = finale.clock - finale.beat_at
		if shots < CHECKPOINTS.size() and elapsed >= CHECKPOINTS[shots]:
			_capture(shots)
			shots += 1
		if finale.beat != "street":
			started = false
			finale.finish(false)
			quit()
	return false


func _capture(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = "res://logs/nightlife_motion_%d.png" % index
	root.get_texture().get_image().save_png(path)
	print("SHOT ", path)


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
	finale = story.all_hands
	finale._beat("receipts")
	finale._beat("grief")
	finale._beat("desk")
	finale._beat("street")
	started = true
