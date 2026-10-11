extends "res://tests/incident_tests.gd"
## Outcome checks on the real trial coworker: gestures, dialogue and restart.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	incident.presentation.skip()
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	player.camera_rig.set_capture(true)
	paused = false
	var crew: Node3D = incident.coworkers
	crew.set_process(false)
	var person: Dictionary = crew.person("Recruiter")
	var body: Node3D = person.body
	var animator: AnimationPlayer = person.animator
	var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
	var trials: int = 0
	for someone: Dictionary in crew.people:
		if (someone.body as Node3D).scene_file_path.ends_with("makehuman_recruiter.tscn"):
			trials += 1
	check(trials == 1 and crew.people.size() == crew.CAST.size(), "one MakeHuman recruiter joins the unchanged coworker cast")
	var reference: Node3D = load("res://assets/characters/quaternius/suit_male.fbx").instantiate()
	root.add_child(reference)
	reference.scale = Vector3.ONE * .62
	check(absf(_height(body) - _height(reference)) < .02,
		"the new coworker's rendered model height matches the existing office cast")
	reference.free()
	var clearance: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var volume: CapsuleShape3D = CapsuleShape3D.new()
	volume.radius = .3
	volume.height = 1.7
	clearance.shape = volume
	clearance.transform = Transform3D(Basis(), body.global_position + Vector3.UP * .95)
	clearance.collision_mask = 1
	check(body.get_world_3d().direct_space_state.intersect_shape(clearance).is_empty(),
		"the full-size coworker stands clear of the table, chairs and walls")
	var start: Transform3D = body.transform
	animator.play("CharacterArmature|Idle", 0.0)
	animator.seek(.5, true)
	animator.pause()
	await frames(2)
	var idle_head: Vector3 = _bone(skeleton, "Head")
	var idle_hand: Vector3 = _bone(skeleton, "Hand.L")
	var torso: Vector3 = _bone(skeleton, "Torso")
	check(idle_head.y - body.global_position.y > 1.4 and idle_head.y - body.global_position.y < 1.9,
		"the imported coworker fits human scale above the conference floor")
	check(idle_hand.y < torso.y and idle_hand.distance_to(torso) > .2,
		"idle leaves the hands below and outside the jacket torso")
	animator.play("ual/talking", 0.0)
	animator.seek(.8, true)
	animator.pause()
	await frames(2)
	var talking_hand: Vector3 = _bone(skeleton, "Hand.L")
	check(talking_hand.distance_to(idle_hand) > .15 and talking_hand.y > idle_hand.y,
		"the retargeted conversation gesture visibly lifts the hand")
	check(body.transform.is_equal_approx(start), "gesture animation leaves the gameplay root planted")
	animator.play("CharacterArmature|Defeat", 0.0)
	animator.seek(.7, true)
	animator.pause()
	await frames(2)
	check(_bone(skeleton, "Head").y < idle_head.y - .1, "battle cowering visibly lowers the head")
	player.position = body.position + Vector3(0, .05, 1.5)
	player.set_physics_process(false)
	var target: Dictionary = incident.talk_target()
	check(target.get("name", "") == "Recruiter" and target.tree.who == "DREW",
		"the original recruiter identity and dialogue remain reachable")
	incident.talk(target)
	await frames(3)
	check(incident.dialogue.is_open() and incident.talking == body, "ordinary talk opens on the new body")
	incident.dialogue.close()
	await frames(2)
	check(not incident.dialogue.is_open() and incident.talking == null, "closing talk restores ordinary play")
	var count: int = body.find_children("*", "", true, false).size()
	var cast_count: int = crew.get_child_count()
	for index in range(3):
		scene.reset_encounter()
		incident.presentation.skip()
		await frames(3)
	check(crew.person("Recruiter").body == body and body.position.is_equal_approx(person.entry.at),
		"retry preserves the trial model and restores its authored position")
	check(body.find_children("*", "", true, false).size() == count and crew.get_child_count() == cast_count,
		"retry does not accumulate imported models or animation players")
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)


func _bone(skeleton: Skeleton3D, bone: String) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin


func _height(body: Node3D) -> float:
	var bounds: AABB
	var first: bool = true
	for node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds.size.y
