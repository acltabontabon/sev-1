extends "res://tests/incident_tests.gd"
## Restored original Drew: visible poses, dialogue, furniture clearance and retry.


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
	check(body.scene_file_path == "res://assets/characters/quaternius/suit_male.fbx" and crew.people.size() == crew.CAST.size(),
		"Drew uses the original suit body in the preserved coworker cast")
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
	var idle: Array[Transform3D] = pose(skeleton)
	animator.play("ual/talking", 0.0)
	animator.seek(.8, true)
	animator.pause()
	await frames(2)
	check(pose_changed(idle, pose(skeleton)), "original Drew visibly changes pose while talking")
	check(body.transform.is_equal_approx(start), "conversation gesture leaves the gameplay root planted")
	animator.play("CharacterArmature|Defeat", 0.0)
	animator.seek(.7, true)
	animator.pause()
	await frames(2)
	check(pose_changed(idle, pose(skeleton)), "original Drew has a visible battle-cowering pose")
	player.position = body.position + Vector3(0, .05, 1.5)
	player.set_physics_process(false)
	var target: Dictionary = incident.talk_target()
	check(target.get("name", "") == "Recruiter" and target.tree.who == "DREW",
		"the original recruiter identity and dialogue remain reachable")
	incident.talk(target)
	await frames(3)
	check(incident.dialogue.is_open() and incident.talking == body, "ordinary talk opens on restored Drew")
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
		"retry preserves the original model and restores its authored position")
	check(body.find_children("*", "", true, false).size() == count and crew.get_child_count() == cast_count,
		"retry does not accumulate imported models or animation players")
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)


func pose(skeleton: Skeleton3D) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for index in range(skeleton.get_bone_count()):
		result.append(skeleton.get_bone_global_pose(index))
	return result


func pose_changed(before: Array[Transform3D], after: Array[Transform3D]) -> bool:
	for index in range(before.size()):
		if not before[index].is_equal_approx(after[index]):
			return true
	return false
