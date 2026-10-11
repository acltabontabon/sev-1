extends "res://tests/incident_tests.gd"
## Rendered clothing pose bounds and real NPC conversation/reset outcomes.


func skirt_points(body: Node3D) -> PackedVector3Array:
	var instance: MeshInstance3D = body.find_child("Body*", true, false)
	var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
	var result: PackedVector3Array = PackedVector3Array()
	for surface in range(instance.mesh.get_surface_count()):
		if instance.mesh.surface_get_material(surface).resource_name != "Skirt":
			continue
		var arrays: Array = instance.mesh.surface_get_arrays(surface)
		for vertex in range(arrays[Mesh.ARRAY_VERTEX].size()):
			var point: Vector3 = Vector3.ZERO
			for influence in range(8):
				var weight: float = arrays[Mesh.ARRAY_WEIGHTS][vertex * 8 + influence]
				if weight <= 0:
					continue
				var bind: int = arrays[Mesh.ARRAY_BONES][vertex * 8 + influence]
				var bone: int = skeleton.find_bone(instance.skin.get_bind_name(bind))
				var transform_: Transform3D = skeleton.get_bone_global_pose(bone) * instance.skin.get_bind_pose(bind)
				point += (transform_ * arrays[Mesh.ARRAY_VERTEX][vertex]) * weight
			result.append(skeleton.global_transform * point)
	return result


func skirt_bounds(points: PackedVector3Array) -> AABB:
	var bounds: AABB = AABB(points[0], Vector3.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds


func moved(before: PackedVector3Array, after: PackedVector3Array) -> bool:
	for index in range(before.size()):
		if before[index].distance_to(after[index]) > .025:
			return true
	return false


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
	for entry: Array in [["SRE", "ual/sitting_talking"], ["Director", "CharacterArmature|Walk"]]:
		var person: Dictionary = crew.person(entry[0])
		var body: Node3D = person.body
		var animator: AnimationPlayer = person.animator
		var start: Transform3D = body.transform
		animator.play("CharacterArmature|Idle", 0.0)
		animator.seek(.5, true)
		animator.pause()
		await frames(2)
		var idle: PackedVector3Array = skirt_points(body)
		check(not idle.is_empty(), "%s wears a rendered skirt on the original rig" % entry[0])
		var bounds: AABB = skirt_bounds(idle)
		check(bounds.size.x > .3 and bounds.size.x < 1.0 and bounds.size.y > .15 and bounds.size.y < .8,
			"%s skirt stays fitted to the body at world scale: %s" % [entry[0], bounds.size])
		animator.play(entry[1], 0.0)
		animator.seek(.7, true)
		animator.pause()
		await frames(2)
		var posed: PackedVector3Array = skirt_points(body)
		check(moved(idle, posed), "%s skirt follows the sitting/walking animation" % entry[0])
		check(skirt_bounds(posed).size.length() < 1.8 and body.transform.is_equal_approx(start),
			"%s clothing stays bounded and leaves the gameplay root planted" % entry[0])
		player.position = body.position + Vector3(0, .05, 1.6)
		player.set_physics_process(false)
		var target: Dictionary = incident.talk_target()
		check(target.get("name", "") == entry[0], "%s original conversation remains reachable" % entry[0])
		incident.talk(target)
		await frames(2)
		check(incident.dialogue.is_open(), "%s can talk in the updated outfit" % entry[0])
		incident.dialogue.close()
		await frames(2)
	var nadia: Node3D = crew.person("SRE").body
	var count: int = nadia.find_children("*", "", true, false).size()
	scene.reset_encounter()
	incident.presentation.skip()
	await frames(3)
	check(crew.person("SRE").body == nadia and nadia.find_children("*", "", true, false).size() == count,
		"retry preserves clothing without accumulating outfit nodes")
	print("RESULT: ", failures, " failure(s)")
	for sound in scene.find_children("*", "AudioStreamPlayer", true, false) + scene.find_children("*", "AudioStreamPlayer3D", true, false):
		sound.stop()
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)
