extends "res://tests/combat_tests.gd"
## The developer outfit on the real player: clothing covers the legs, worn gear rides
## its bones through a real swing, the back print hides in the chair, battle lights up.


func surface_points(rig: Node3D, surface_name: String) -> PackedVector3Array:
	var instance: MeshInstance3D = rig.skeleton.find_child("Body*", false, false)
	var result: PackedVector3Array = PackedVector3Array()
	for surface in range(instance.mesh.get_surface_count()):
		if instance.mesh.surface_get_material(surface).resource_name != surface_name:
			continue
		var arrays: Array = instance.mesh.surface_get_arrays(surface)
		for vertex in range(arrays[Mesh.ARRAY_VERTEX].size()):
			var point: Vector3 = Vector3.ZERO
			for influence in range(8):
				var weight: float = arrays[Mesh.ARRAY_WEIGHTS][vertex * 8 + influence]
				if weight <= 0:
					continue
				var bind: int = arrays[Mesh.ARRAY_BONES][vertex * 8 + influence]
				var bone: int = rig.skeleton.find_bone(instance.skin.get_bind_name(bind))
				point += (rig.skeleton.get_bone_global_pose(bone) * instance.skin.get_bind_pose(bind) * arrays[Mesh.ARRAY_VERTEX][vertex]) * weight
			result.append(rig.skeleton.global_transform * point)
	return result


func lowest(points: PackedVector3Array) -> float:
	var height: float = INF
	for point in points:
		height = minf(height, point.y)
	return height


func _run() -> void:
	scene = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	enemy = scene.get_node("Enemy")
	await setup_pair(Vector3(6, .05, 5))
	var rig: Node3D = scene.get_node("Player/Visual/Character")
	var body: MeshInstance3D = rig.skeleton.find_child("Body*", false, false)
	check(body.mesh == rig.OUTFIT and body.skin != null, "the player wears the developer outfit on the original skin")
	var names: Array[String] = []
	for surface in range(body.mesh.get_surface_count()):
		names.append(body.mesh.surface_get_material(surface).resource_name)
	for surface_name: String in ["Hoodie", "Glove", "Pants", "Shoe", "Sole", "Streak", "Face", "Hair"]:
		check(surface_name in names, "outfit keeps a %s surface" % surface_name)
	var ground: float = player.global_position.y
	# The long chibi arms hang the bare fingers low; anything else low must be clothed.
	var bare_legs: int = 0
	for point in surface_points(rig, "Skin"):
		var near_hand: bool = false
		for side: String in ["L", "R"]:
			var fist: Vector3 = rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("Fist." + side)).origin
			near_hand = near_hand or point.distance_to(fist) < .3
		if point.y - ground < .6 and not near_hand:
			bare_legs += 1
	check(bare_legs == 0, "joggers and sneakers cover the legs (%d bare points)" % bare_legs)
	check(lowest(surface_points(rig, "Sole")) - ground < .08, "sneaker soles reach the floor")
	var lens: Node3D = rig.skeleton.find_child("Glasses", true, false).get_child(0)
	var cup: Node3D = rig.skeleton.find_child("Headphones", true, false).get_child(-1)
	var head_bone: int = rig.skeleton.find_bone("Head")
	var head: Vector3 = rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(head_bone).origin
	var lens_offset: float = lens.global_position.distance_to(head)
	var cup_offset: float = cup.global_position.distance_to(head)
	check(lens_offset < .6 and cup_offset < .6, "glasses and headphones sit on the head (%.2f m, %.2f m)" % [lens_offset, cup_offset])
	check(player.request_attack(), "outfit check swings the sword")
	while not player.melee.is_active():
		await frames(1)
	await frames(2)
	head = rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(head_bone).origin
	check(absf(lens.global_position.distance_to(head) - lens_offset) < .03, "glasses stay on the face mid-swing")
	check(absf(cup.global_position.distance_to(head) - cup_offset) < .03, "headphones stay on the head mid-swing")
	await setup_pair(Vector3(6, .05, 5))
	var calm: Array[float] = []
	for entry: Array in rig.gear_glow:
		calm.append((entry[0] as StandardMaterial3D).emission_energy_multiplier)
	rig.battle = 1.0
	await frames(2)
	var brighter: bool = true
	for index in range(rig.gear_glow.size()):
		var material: StandardMaterial3D = rig.gear_glow[index][0]
		if material != rig.watch_screen and material.emission_energy_multiplier <= calm[index]:
			brighter = false
	check(brighter, "battle mode lights the headphones, lenses and soles")
	rig.battle = 0.0
	check(rig.back_kit.visible, "back print shows while standing")
	rig.story_pose = rig.Pose.TYPING
	await frames(2)
	check(not rig.back_kit.visible, "back print hides inside the desk chair")
	rig.story_pose = rig.Pose.NONE
	await frames(2)
	check(rig.back_kit.visible, "back print returns when he stands")
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
