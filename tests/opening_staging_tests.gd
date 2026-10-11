extends "res://tests/hero_outfit_tests.gd"
## Observe the skinned clothing on the real cushion, camera sightlines and handoff.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	var incident: Node = scene.get_node("Incident")
	var story: Node = incident.presentation
	var rig: Node3D = player.presentation
	var chair: Node3D = incident.room.get_node("YourWorkstation/Chair")
	player.camera_rig.set_capture(true)
	# Keep the real controller, physics and presentation running at startup. A frozen
	# pose cannot catch collision recovery pushing the capsule out of the chair.
	check(player.narrative_hold, "full opening locks physics before its first rendered frame")
	# A slow graphical startup may run several controller ticks before _process.
	for tick in range(8):
		player._physics_process(1.0 / 60.0)
	await frames(90)
	check(player.position.distance_to(story.SEAT) < .001,
		"live startup keeps the seated player on the chair anchor (%s)" % player.position)
	incident.set_process(false)
	story.set_process(false)
	rig.set_physics_process(false)
	for pose: int in [rig.Pose.TYPING, rig.Pose.RELAX, rig.Pose.ALERT]:
		rig.story_pose = pose
		for tick in range(120):
			rig._physics_process(1.0 / 60.0)
		var bottom: float = INF
		var rear: float = -INF
		for point: Vector3 in surface_points(rig, "Pants"):
			var local: Vector3 = chair.to_local(point)
			# The buttocks/thighs over the cushion, excluding the hanging calves.
			if local.z > -.08:
				bottom = minf(bottom, local.y)
				rear = maxf(rear, local.z)
		check(absf(bottom - chair.get_node("SeatReference").position.y) < .025,
			"pose %d: visible hips rest on the cushion (%.3f m)" % [pose, bottom])
		check(rear > .1 and rear < .27, "pose %d: hips sit within the rear of the cushion" % pose)
		# Check the actual upper back, not a guessed head/hip anchor.
		var back: float = -INF
		for point: Vector3 in surface_points(rig, "Hoodie"):
			var local: Vector3 = chair.to_local(point)
			if absf(local.x) < .18 and local.y > .85 and local.y < 1.0:
				back = maxf(back, local.z)
		check(back > .19 and back < .37, "pose %d: upper back stays beside the backrest (%.3f m)" % [pose, back])
	# Sample moving shots, including both sides of every cut, against the real head.
	for mark: float in [22.6, 24.0, 25.49, 25.5, 28.49, 28.5, 29.09, 29.1, 29.79, 30.8, 33.2, 35.59, 35.6, 37.19, 43.6, 44.3]:
		incident.stage_time = mark
		story._opening(mark, 1.0 / 60.0)
		for tick in range(90):
			rig._physics_process(1.0 / 60.0)
		var head: Vector3 = rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("Head")).origin + Vector3.UP * .23
		check(story.camera.global_position.distance_to(head) > .65, "%.2fs: camera stays outside the head" % mark)
		if mark < 25.5 or (mark >= 28.5 and mark < 29.8):
			var nearest: Vector3 = Geometry3D.get_closest_point_to_segment(head, story.camera.global_position, story.MONITOR)
			check(nearest.distance_to(head) > .43, "%.2fs: head cannot cover the screen insert" % mark)
		else:
			var uv: Vector2 = story.camera.unproject_position(head) / root.get_visible_rect().size
			check(uv.x > .15 and uv.x < .85 and uv.y > .15 and uv.y < .85, "%.2fs: face stays inside the cinematic frame (%s)" % [mark, uv])
	story.reset_story()
	var monster_skeleton: Skeleton3D = story.demon.model.find_child("Skeleton3D", true, false)
	var separation: float = INF
	var physical_gap: float = INF
	for tick in range(69):
		var mark: float = 43.6 + tick / 60.0
		incident.stage_time = mark
		story._opening(mark, 1.0 / 60.0)
		rig._physics_process(1.0 / 60.0)
		var hero_head: Vector3 = rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("Head")).origin + Vector3.UP * .23
		var monster_head: Vector3 = monster_skeleton.global_transform * monster_skeleton.get_bone_global_pose(monster_skeleton.find_bone("Head")).origin
		var hero_screen: Vector2 = story.camera.unproject_position(hero_head)
		var monster_screen: Vector2 = story.camera.unproject_position(monster_head)
		separation = minf(separation, absf(hero_screen.x - monster_screen.x) / root.get_visible_rect().size.x)
		physical_gap = minf(physical_gap, player.global_position.distance_to(story.demon.global_position))
	check(physical_gap > 2.0, "the apparition stays physically behind the chair through its attack")
	check(separation > .11, "the two heads retain separate screen silhouettes (%.3f frame widths)" % separation)
	check(not story.opening_eyes.is_empty() and story.opening_eyes[0].get_shader_parameter("emission_strength") < .2
		and is_equal_approx(MonsterRig.skins["Eye_White"].get_shader_parameter("emission_strength"), 1.4),
		"the opening apparition uses dim eyes without changing shared monster materials")
	# Natural exit reaches the playable location before camera ownership changes.
	for mark: float in [45.95, 47.0, 47.3, 48.0, 48.6, 49.5]:
		incident.stage_time = mark
		story._opening(mark, 1.0 / 60.0)
		for tick in range(60):
			rig._physics_process(1.0 / 60.0)
	var before: Vector3 = player.position
	story.skip()
	check(is_equal_approx(story.opening_eyes[0].get_shader_parameter("emission_strength"), 1.4), "opening cleanup restores the ordinary boss eye lighting")
	check(player.position.distance_to(before) < .001, "natural handoff does not teleport the engineer")
	check(not player.narrative_hold and rig.story_walk_speed == 0.0, "handoff restores gameplay and stops authored travel")
	story.opening_seen = false
	incident.reset_incident()
	check(chair.position.is_equal_approx(story.CHAIR_AT), "replay returns the chair beneath the seated engineer")
	story.skip()
	await frames(3)
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var capsule: CollisionShape3D = player.get_node("CollisionShape3D")
	query.shape = capsule.shape
	query.transform = capsule.global_transform
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	check(player.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "skipping releases the capsule clear of furniture")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
