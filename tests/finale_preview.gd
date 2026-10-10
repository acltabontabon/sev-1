extends SceneTree
## Rendered checkpoints for grief, desk pickup and remembered conversations.
## sh tools/godot.sh --path . --script tests/finale_preview.gd
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
	finale._beat("memorial")
	for sample: Array in [["grief", 5.5], ["desk", 2.0], ["desk", 5.5], ["exit", 3.0], ["exit", 5.0], ["exit", 8.0], ["street", 3.0]]:
		if finale.beat != sample[0]:
			finale._beat(sample[0])
		var elapsed: float = finale.clock - finale.beat_at
		while elapsed < float(sample[1]):
			finale.tick(1.0 / 60.0)
			elapsed += 1.0 / 60.0
			await physics_frame
		await RenderingServer.frame_post_draw
		var path: String = "res://logs/finale_%s_%d.png" % [sample[0], int(sample[1])]
		root.get_texture().get_image().save_png(path)
		print("SHOT ", path)
		if sample[0] in ["exit", "street"]:
			print("GAIT ", finale.character.animator.current_animation, " rate ", finale.character.animator.speed_scale, " clip time ", finale.character.animator.current_animation_position)
	finale.finish(false)
	await process_frame
	quit()
