extends SceneTree
## Actual office lighting; isolated wardrobe poses, then the existing seated placement.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var scene: Node3D = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var incident: Node3D = scene.get_node("Incident")
	incident.presentation.skip()
	incident._cleanup()
	incident.set_process(false)
	incident.presentation.set_process(false)
	incident.presentation.feed.hide()
	scene.get_node("HUD").hide()
	var player: CharacterBody3D = scene.get_node("Player")
	player.set_physics_process(false)
	player.position = Vector3(22, .05, 6)
	var crew: Node3D = incident.coworkers
	crew.set_process(false)
	var nadia: Dictionary = crew.person("SRE")
	var marie: Dictionary = crew.person("Director")
	var saved: Transform3D = nadia.body.transform
	var camera: Camera3D = Camera3D.new()
	scene.add_child(camera)
	camera.fov = 40
	camera.current = true
	paused = false
	DirAccess.make_dir_recursive_absolute("res://builds")
	for entry: Array in [[nadia, "nadia", "CharacterArmature|Idle", .5], [marie, "marie", "CharacterArmature|Idle", .5], [marie, "marie_walk", "CharacterArmature|Walk", .7]]:
		var person: Dictionary = entry[0]
		person.body.position = Vector3(-1, 0, 3)
		person.body.rotation.y = .1
		person.animator.play(entry[2], 0.0)
		person.animator.seek(entry[3], true)
		person.animator.pause()
		camera.position = Vector3(.4, 1.25, 6.2)
		camera.look_at(Vector3(-1, 1.05, 3))
		await _grab(camera, entry[1])
		person.body.position = person.entry.at
	marie.body.rotation.y = marie.entry.facing
	nadia.body.transform = saved
	nadia.animator.play("CharacterArmature|SitDown", 0.0)
	nadia.animator.seek(nadia.animator.current_animation_length, true)
	nadia.animator.pause()
	camera.position = Vector3(-4.3, 1.5, 2.5)
	camera.look_at(nadia.body.position + Vector3.UP * .8)
	await _grab(camera, "nadia_seated")
	scene.queue_free()
	paused = false
	await process_frame
	quit()


func _grab(camera: Camera3D, name_: String) -> void:
	camera.make_current()
	for index in range(60):
		await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png("res://builds/outfit_" + name_ + ".png")
	assert(error == OK)
