extends SceneTree
## Quick graphical checkpoint of the hero entrance, with sound and phase captures.
## sh tools/godot.sh --path . --script tests/rage_preview.gd
var player: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	paused = false
	if player != null:
		player.camera_rig.controls_active = true
	return false


func _run() -> void:
	var scene: Node = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	player.camera_rig.set_capture(false)
	var incident: Node = scene.get_node("Incident")
	var story: Node = incident.presentation
	story.skip()
	incident._cleanup()
	for stage in [incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(stage)
	player.position = Vector3(9, .05, -31)
	await process_frame
	incident.coworkers.fall_all_now()
	incident.coworkers.hush()
	story.voice.clear(true)
	story.beat_shot = "massacre"
	story.boss_length = 120.0
	player.position = Vector3(9, .05, -30.4)
	story._hero_phase("grief")
	var captured: Dictionary = {}
	var started: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 26000:
		await process_frame
		var time: float = story.massacre_time - story.hero_phase_at
		var key: String = story.hero_phase
		if key == "memory":
			key += str(mini(2, int(time / 2.8)))
			time = fmod(time, 2.8)
		if time > (2.8 if key == "charge" else .9) and not captured.has(key):
			captured[key] = true
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/sev1_rage_" + key + ".png")
		if is_instance_valid(incident.boss):
			await create_timer(1.0).timeout
			break
	quit()
