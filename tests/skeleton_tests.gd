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
	# Keep one living record so individual death/reset probes cannot end the wave
	# and open a paused upgrade choice during the second strike check.
	var spare: CharacterBody3D = spawn("record", Vector3(-9, .05, -12), false)
	spare.set_physics_process(false)
	var seen: Array[String] = []
	for index in range(2):
		var foe: CharacterBody3D = spawn("record", Vector3(-2 + index * 4, .05, 4), true)
		seen.append(foe.rig_kind)
		check(foe.bark_kind == "record", "skeleton retains Corrupted Record voice")
		var rig: MonsterRig = foe.rig
		var skeleton: Skeleton3D = rig.model.find_child("Skeleton3D", true, false)
		check(skeleton != null and skeleton.get_bone_count() > 20, "record wears the imported KayKit skeleton")
		for role: String in ["idle", "walk", "run", "attack", "hit", "death"]:
			check(not rig.clips[role].is_empty(), "skeleton resolves " + role + " motion")
		for bone: String in rig.spec.slice.upper + rig.spec.slice.lower + [rig.spec.slice.center]:
			check(skeleton.find_bone(bone) >= 0, "waist cut resolves " + bone)
		var skin: StandardMaterial3D = rig.meshes[0].get_surface_override_material(0) as StandardMaterial3D
		check(skin != null and skin.albedo_texture is Texture2D, "original cartoon atlas survives runtime dressing")
		check(skin.next_pass is ShaderMaterial and skin.next_pass.shader == MonsterRig.OVERLAY, "cartoon materials retain combat telegraph and hit overlay")
		foe.set_physics_process(false)
		foe.rig.set_physics_process(false)
		foe.visual.set_physics_process(false)
		var arm: int = skeleton.find_bone("upperarm.r")
		rig.animator.play(rig.clips.idle)
		rig.animator.seek(.2, true)
		var before: Quaternion = skeleton.get_bone_pose_rotation(arm)
		rig.animator.play(rig.clips.attack)
		rig.animator.seek(rig.animator.current_animation_length * rig.spec.impact, true)
		check(before.angle_to(skeleton.get_bone_pose_rotation(arm)) > .2, "attack changes the striking arm pose")
		rig.animator.play(rig.clips.idle, 0.0)
		rig.animator.seek(.2, true)
		foe.melee.start()
		foe.melee.set_physics_process(false)
		foe.melee.elapsed = foe.melee.windup
		for frame in range(8):
			rig._physics_process(1.0 / 60.0)
			await frames(1)
		check(rig.animator.current_animation == rig.clips.attack and before.angle_to(skeleton.get_bone_pose_rotation(arm)) > .2,
			"real melee clock drives the skeleton to its punch contact pose")
		foe.melee.cancel()
		foe.melee.set_physics_process(true)
		check(foe.max_health == 180 and foe.melee.damage == 20 and is_equal_approx(foe.melee.reach, 1.85) and is_equal_approx(foe.melee.windup, .65),
			"skeleton preserves record health, damage, reach and windup")
		player.set_physics_process(false)
		# Both strike probes use the same clear central aisle.
		foe.position = Vector3(0, .05, 6)
		foe.visual.rotation.y = 0.0
		player.position = foe.position + Vector3(0, 0, -1.2)
		player.invulnerable_left = 0.0
		var health_before: int = player.health
		foe.melee.start()
		await frames(30)
		check(player.health == health_before, "skeleton windup does not deal early damage")
		await frames(60)
		check(player.health < health_before and foe.melee.hit_targets.size() == 1, "existing active strike damages the engineer once")
		player.position = foe.position + Vector3(0, 0, -3.0)
		player.invulnerable_left = 0.0
		health_before = player.health
		foe.melee.start()
		await frames(90)
		check(player.health == health_before, "skeleton strike still misses outside the existing reach")
		player.set_physics_process(true)
		check(foe.receive_damage(10, player.position) and foe.health == foe.max_health - 10, "skeleton preserves damage rules")
		foe.receive_damage(10000, player.position)
		rig._die(.02)
		check(rig.death_style == "slice" and rig.pieces.size() == 1, "hard kill produces physical waist-slice death")
		foe.reset_enemy()
		check(foe.health == foe.max_health and rig.death_style.is_empty() and rig.collapsed.is_empty(), "retry restores health and full rig")
		check(rig.model.get_parent() == rig and rig.pieces.is_empty(), "retry removes detached corpse pieces")
	check(seen == ["record", "record"], "consecutive records use the skeleton instead of realistic demons")
	MonsterRig.gore_in_headless = false
	scene.reset_encounter()
	await fresh_stage(incident.Stage.INVESTIGATION)
	var retried: CharacterBody3D = spawn("record", Vector3(0, .05, 4), true)
	check(retried.rig_kind == "record" and retried.health == retried.max_health, "full incident retry respawns a healthy skeleton")
	scene.queue_free()
	await frames(3)
	print("RESULT: ", failures, " skeleton body failure(s)")
	quit(0 if failures == 0 else 1)
