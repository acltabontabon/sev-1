extends SceneTree
## The exit must open before the hero crosses it, with readable branding and real strides.
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	paused = false
	return false


func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1


func _run() -> void:
	var scene: Node3D = load("res://game/incidents/missing_transaction.tscn").instantiate()
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
	finale._beat("exit")
	var corridor: Node3D = finale.departure
	var character: Node = finale.character
	finale.tick(.8)
	await physics_frame
	await physics_frame
	check(character.story_walk_speed > 1.0 and character.animator.current_animation == "rig/walk" and character.animator.speed_scale > .6,
		"the departure uses ordinary strides at a travel-matched cadence")
	finale.clock = finale.beat_at + float(finale.memories[0].cue) + .5
	finale.tick(.001)
	await physics_frame
	var held_at: Vector3 = incident.player.global_position
	finale.tick(.5)
	await physics_frame
	check(incident.player.global_position.distance_to(held_at) > .4 and character.story_walk_speed > 1.0 and character.animator.current_animation == "rig/walk",
		"he keeps walking naturally while a remembered coworker speaks")
	var previous_end: float = 0.0
	var spaced: bool = true
	for memory: Dictionary in finale.memories:
		spaced = spaced and float(memory.cue) > previous_end
		previous_end = float(memory.cue) + float(memory.length)
	check(spaced and finale.exit_duration > previous_end, "complete remembered lines stay sequential through the continuous walk")
	var covered: bool = true
	for sample in range(101):
		var travel: Vector4 = corridor.travel(finale.exit_duration * float(sample) / 101.0)
		var point: Vector3 = Vector3(travel.x, travel.y, travel.z)
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(point + Vector3.UP, point - Vector3.UP)
		ray.exclude = [incident.player.get_rid()]
		covered = covered and not scene.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	check(covered, "the full voice-length corridor has a continuous physical floor")
	finale.clock = finale.beat_at + finale.exit_duration
	finale.tick(.001)
	check(finale.beat == "door", "the memory walk proceeds to a shown doorway crossing")
	var probe: SphereShape3D = SphereShape3D.new()
	probe.radius = .4
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.exclude = [incident.player.get_rid()]
	query.transform = Transform3D(Basis.IDENTITY, corridor.to_global(Vector3(corridor.THRESHOLD, 1.0, 0)))
	await physics_frame
	check(not scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "the closed door physically fills the doorway")
	finale.tick(1.5)
	await physics_frame
	check(corridor.door_open > .99 and scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
		and incident.player.global_position.x < corridor.global_position.x + corridor.THRESHOLD,
		"the door visibly and physically opens before he reaches its threshold")
	var word: Label3D = corridor.get_node("DepartureLogo/Wordmark")
	var camera: Camera3D = story.camera
	var rectangle: Rect2 = root.get_visible_rect().grow(-20)
	check(word.text == "SYNERGEX" and word.is_visible_in_tree() and not camera.is_position_behind(word.global_position)
		and rectangle.has_point(camera.unproject_position(word.global_position)), "the actual SYNERGEX mark is visible in the doorway shot")
	var clear_route: bool = true
	for frame in range(260):
		finale.tick(1.0 / 60.0)
		await physics_frame
		query.transform.origin = incident.player.global_position + Vector3.UP
		clear_route = clear_route and scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
	check(clear_route and incident.player.global_position.x > corridor.global_position.x + corridor.THRESHOLD + 1.0,
		"he walks fully through the opening without intersecting either door panel or the frame")
	story.set_process(true)
	story.skip()
	await process_frame
	await process_frame
	check(not is_instance_valid(corridor), "skipping the doorway removes its geometry, logo and door colliders")
	scene.reset_encounter()
	await process_frame
	check(character.story_walk_speed == 0.0 and character.weapon.visible, "retry restores the ordinary playable engineer")
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
