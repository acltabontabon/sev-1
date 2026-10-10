extends "res://tests/incident_tests.gd"
## The real reveal must leave coworkers supported by their furniture.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	var crew: Node3D = incident.coworkers
	var story: Node = incident.presentation
	crew.process_mode = Node.PROCESS_MODE_DISABLED
	var before: Array[Dictionary] = []
	for someone: Dictionary in crew.people:
		var body: Node3D = someone.body
		var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
		var bones: Dictionary = {}
		for index in range(skeleton.get_bone_count()):
			bones[index] = skeleton.get_bone_global_pose(index)
		before.append({"root": body.global_transform, "bones": bones})
	story._fire([39.6, "heads", ""])
	for index in range(crew.people.size()):
		var someone: Dictionary = crew.people[index]
		var body: Node3D = someone.body
		var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
		check(body.global_transform.is_equal_approx(before[index].root), someone.entry.name + " stays anchored during the reveal")
		for bone: String in ["Abdomen", "UpperLeg.L", "UpperLeg.R", "LowerLeg.L", "LowerLeg.R", "Foot.L", "Foot.R"]:
			var id: int = skeleton.find_bone(bone)
			check(id >= 0 and skeleton.get_bone_global_pose(id).is_equal_approx(before[index].bones[id]), someone.entry.name + " keeps " + bone + " in its supported pose")
		var head: int = skeleton.find_bone("Head")
		check(not skeleton.get_bone_global_pose(head).basis.is_equal_approx(before[index].bones[head].basis), someone.entry.name + " visibly turns their head")
	# Skip and natural completion share the same cleanup.
	story._end_opening()
	for index in range(crew.people.size()):
		var skeleton: Skeleton3D = (crew.people[index].body as Node3D).find_child("Skeleton3D", true, false)
		var head: int = skeleton.find_bone("Head")
		check(skeleton.get_bone_global_pose(head).is_equal_approx(before[index].bones[head]), crew.people[index].entry.name + " recovers its original head pose")
	check(crew.stare_poses.is_empty() and crew.process_mode == Node.PROCESS_MODE_PAUSABLE, "opening cleanup restores crew processing")
	story._fire([39.6, "heads", ""])
	crew.reset()
	check(crew.stare_poses.is_empty(), "restart clears every reveal pose")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
