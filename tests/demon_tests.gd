extends "res://tests/encounter_tests.gd"
## Outcome checks on spawned wave members: texture, motion, cut death and retry.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	await fresh_stage(incident.Stage.INVESTIGATION)
	MonsterRig.gore_in_headless = true
	var seen: Array[String] = []
	for index in range(2):
		var foe: CharacterBody3D = spawn("record", Vector3(-2 + index * 4, .05, 4), true)
		seen.append(foe.rig_kind)
		check(foe.bark_kind == "record", "body variant retains Corrupted Record voice")
		var rig: MonsterRig = foe.rig
		var skeleton: Skeleton3D = rig.model.find_child("Skeleton3D", true, false)
		check(skeleton != null and skeleton.get_bone_count() > 20, "demon has an imported skin skeleton")
		for role: String in ["idle", "walk", "run", "attack", "hit", "death"]:
			check(not rig.clips[role].is_empty(), "demon resolves " + role + " motion")
		for bone: String in rig.spec.slice.upper + rig.spec.slice.lower + [rig.spec.slice.center]:
			check(skeleton.find_bone(bone) >= 0, "waist cut resolves " + bone)
		var skin: ShaderMaterial = rig.meshes[0].get_surface_override_material(0)
		check(skin.get_shader_parameter("source_albedo") is Texture2D, "original skin texture survives runtime dressing")
		foe.set_physics_process(false)
		foe.rig.set_physics_process(false)
		foe.visual.set_physics_process(false)
		var arm: int = skeleton.find_bone("ORG-upper_arm.R" if index == 0 else "Arm.R")
		rig.animator.play(rig.clips.idle)
		rig.animator.seek(.2, true)
		var before: Quaternion = skeleton.get_bone_pose_rotation(arm)
		rig.animator.play(rig.clips.attack)
		rig.animator.seek(.5, true)
		check(before.angle_to(skeleton.get_bone_pose_rotation(arm)) > .2, "attack changes the striking arm pose")
		check(foe.receive_damage(10, player.position) and foe.health == foe.max_health - 10, "body variation preserves damage rules")
		foe.receive_damage(10000, player.position)
		rig._die(.02)
		check(rig.death_style == "slice" and rig.pieces.size() == 1, "hard kill produces physical waist-slice death")
		foe.reset_enemy()
		check(foe.health == foe.max_health and rig.death_style.is_empty() and rig.collapsed.is_empty(), "retry restores health and full rig")
		check(rig.model.get_parent() == rig and rig.pieces.is_empty(), "retry removes detached corpse pieces")
	check(seen == ["night_demon", "chained_demon"], "consecutive record spawns use both body variants")
	MonsterRig.gore_in_headless = false
	scene.reset_encounter()
	check(incident.record_body_index == 0, "full incident retry restarts deterministic body variation")
	scene.queue_free()
	await frames(3)
	print("RESULT: ", failures, " demon body failure(s)")
	quit(0 if failures == 0 else 1)
