extends "res://tests/combat_tests.gd"
## Real controller sampling: whole-body motion, contact grip, freeze, cancellation,
## and a fresh checkout's CC0 fallback. Existing skill tests own damage outcomes.
var solved_hands: Dictionary = {}


func sample_hands(rig: Node3D) -> void:
	for side: String in ["R", "L"]:
		solved_hands[side] = rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("Fist." + side)).origin


func _run() -> void:
	for local_trial in [true, false]:
		scene = load("res://game/main.tscn").instantiate()
		var rig: Node3D = scene.get_node("Player/Visual/Character")
		rig.use_local_sword_trial = local_trial
		root.add_child(scene)
		current_scene = scene
		player = scene.get_node("Player")
		enemy = scene.get_node("Enemy")
		await setup_pair(Vector3(6, .05, 5))
		# Modifiers restore their input poses after skinning; sample their final output
		# during modification_processed, as required by SkeletonModifier3D.
		rig.left_ik.modification_processed.connect(sample_hands.bind(rig))
		var origin: Vector3 = player.global_position
		check(player.request_attack(), "sword motion accepts attack with local trial=" + str(local_trial))
		await frames(3)
		var expected: String = "sword_trial/kevin_2h" if local_trial and ResourceLoader.exists(rig.SWORD_TRIAL) else "rig/sword_a"
		check(rig.animator.current_animation == expected, "first cut uses installed motion or CC0 fallback")
		var torso: int = rig.skeleton.find_bone("Torso")
		var before: Quaternion = rig.skeleton.get_bone_pose_rotation(torso)
		var leg: int = rig.skeleton.find_bone("UpperLeg.R")
		var leg_before: Quaternion = rig.skeleton.get_bone_pose_rotation(leg)
		while not player.melee.is_active():
			await frames(1)
		await frames(2)
		check(before.angle_to(rig.skeleton.get_bone_pose_rotation(torso)) > .02, "torso follows the strike instead of holding locomotion")
		check(leg_before.angle_to(rig.skeleton.get_bone_pose_rotation(leg)) > .02, "the cut changes leg stance, not only procedural arms and torso")
		check(player.global_position.distance_to(origin) < .02, "source root motion cannot move the controller")
		for side: String in ["R", "L"]:
			var hand: Vector3 = solved_hands[side]
			var grip: Vector3 = rig.weapon.global_transform * (rig.RIGHT_GRIP if side == "R" else rig.LEFT_GRIP)
			check(hand.distance_to(grip) < .28, "two-handed " + side + " grip stays near the sword at contact (" + str(hand.distance_to(grip)) + " m)")
		player.hitstop_left = .08
		player.melee.freeze_left = .08
		var time: float = rig.animator.current_animation_position
		await frames(2)
		check(is_equal_approx(time, rig.animator.current_animation_position), "hit-stop freezes the sampled body motion")
		await frames(12)
		player.invulnerable_left = 0.0
		player.receive_damage(1, enemy.global_position)
		await frames(1)
		check(not player.melee.attacking and rig.animator.current_animation == "rig/hit", "hurt cancels the sword clip")
		await setup_pair(Vector3(6, .05, 5))
		check(player.specials.works_on_my_machine(), "counter opens after reset")
		await frames(8)
		check(rig.animator.current_animation == "rig/sword_block" and rig.shoulder_rest == 0.0, "counter holds a guard instead of the shoulder carry")
		check(rig.left_ik.active and rig.right_ik.active, "guard keeps both hands on the sword")
		scene.reset_encounter()
		await frames(12)
		check(rig.animator.current_animation == "rig/idle" and rig.shoulder_rest > .9, "retry restores the ordinary shoulder carry")
		scene.queue_free()
		await process_frame
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
