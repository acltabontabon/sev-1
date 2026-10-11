extends "res://tests/combat_tests.gd"
## Observe rendered-pose contracts alongside real combat outcomes.

func _run() -> void:
	scene = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	enemy = scene.get_node("Enemy")
	player.hitstop_enabled = false
	await setup_pair()
	var view: Node3D = player.presentation
	check(view.get_node("WeaponPivot/EscalationBlade") != null and view.animator.has_animation("rig/roll") and view.animator.has_animation("rig/death"), "rigged engineer loads the greatsword and the retargeted action clips")
	var sword: MeshInstance3D = view.weapon.get_node("EscalationBlade/HeavyGreatsword")
	var bounds: AABB = sword.transform * sword.get_aabb()
	check(absf(bounds.position.z + 2.32) < .01 and absf(bounds.end.z - .03) < .01, "imported blade matches the grip and trail envelope")
	check(bounds.position.x < 0 and bounds.end.x > 0 and bounds.size.x < .5, "imported sword is centered across the grip without an oversized guard")
	var tip: Vector3 = view.weapon.transform * Vector3(0, 0, -1.47)
	check(tip.y > .05, "resting keyboard stays above floor")
	var rest: Transform3D = view.weapon.transform
	player.request_attack()
	await frames(4)
	check(not view.weapon.transform.is_equal_approx(rest) and enemy.health == enemy.max_health, "anticipation moves weapon before any damage")
	await frames(7)
	check(enemy.health == enemy.max_health - 25, "visible strike uses existing damage event exactly once")
	check(_effects(view) > 0, "the strike releases its element as presentation")
	await frames(50)
	check(not player.melee.attacking and view.weapon.position.distance_to(view.shoulder_transform().origin) < .05, "recovery puts the broadsword back on the shoulder")
	await setup_pair()
	player.request_attack()
	await frames(3)
	player.receive_damage(5, enemy.position)
	await frames(30)
	check(enemy.health == enemy.max_health and not player.melee.attacking, "interrupted anticipation cannot leave a damaging presentation")
	await setup_pair()
	player.request_dodge()
	await frames(6)
	check(view.crouch > .1 and player.visual.scale == Vector3.ONE, "dodge crouches without scaling damage origin")
	check(view.animator.current_animation == "rig/roll", "dodge plays the roll clip")
	check(player.dodge_aura.visible == player.dodge_is_invulnerable(), "dodge aura follows actual invulnerability")
	await frames(40)
	check(view.crouch < .01 and not player.dodge_aura.visible, "dodge recovery restores stance and clears aura")
	await setup_pair()
	player.request_attack()
	await frames(3)
	player.hitstop_left = .15
	player.melee.freeze_left = .15
	var frozen: Transform3D = view.weapon.transform
	await frames(4)
	check(view.weapon.transform.is_equal_approx(frozen), "presentation freezes with actor-local hit-stop")
	await setup_pair()
	enemy.receive_damage(enemy.health, player.position)
	check(enemy.visual.status_material.emission_energy_multiplier == 0, "defeated record extinguishes its status light")
	check(enemy.collision_layer == 0 and not enemy.melee.attacking, "defeat pose does not preserve damage or body collision")
	await frames(4)
	check(enemy.rig.animator.current_animation == enemy.rig.clips.death, "defeated rig plays its death clip")
	enemy.reset_enemy()
	check(enemy.visual.position == Vector3.ZERO and enemy.visual.details.rotation == Vector3.ZERO, "reset clears collapsed record pose")
	await setup_pair()
	enemy.melee.start()
	await frames(3)
	check(enemy.rig.animator.current_animation == enemy.rig.clips.attack, "enemy rig plays its attack during the telegraph")
	enemy.melee.cancel()
	var count: int = scene.get_child_count(true)
	for index in range(5):
		scene.reset_encounter()
		await frames(2)
	check(scene.get_child_count(true) == count, "presentation reset does not accumulate scene children")
	check(not player.get_node("DodgeSound").playing and not enemy.get_node("DefeatSound").playing, "reset stops presentation sounds")
	player.receive_damage(player.health, enemy.position)
	check(view.crouch > .4 and not player.melee.attacking, "player settles into defeat pose before terminal pause")
	scene.reset_encounter()
	check(view.crouch == 0 and view.animator.current_animation != "rig/death", "retry clears death pose")
	check(_effects(view) == 0, "retry clears element effects")
	await _desk_contacts()
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)


func _desk_contacts() -> void:
	var backdrop: Node3D = load("res://game/release/menu_backdrop.tscn").instantiate()
	root.add_child(backdrop)
	backdrop.set_process(false)
	var rig: Node3D = backdrop.character
	var desk: Node3D = backdrop.room.get_node("YourWorkstation")
	var solved: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
	rig.left_ik.modification_processed.connect(func() -> void:
		for side: int in range(2):
			var bone: int = rig.skeleton.find_bone("Fist." + ("L" if side == 0 else "R"))
			solved[side] = desk.to_local(rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(bone).origin)
	)
	await frames(120)
	check(not rig.blade_art.is_visible_in_tree(), "title desk hides the sword")
	var mug: Node3D = desk.get_node("Mug")
	var body: MeshInstance3D = mug.get_node("Body")
	var cup_bounds: AABB = desk.global_transform.affine_inverse() * body.global_transform * body.get_aabb()
	check(absf(cup_bounds.position.y - .8225) < .002 and mug.get_node("Handle").visible and mug.get_node("Coffee").visible,
		"detailed coffee mug has a handle and coffee and rests on the tabletop")
	for pose: int in [rig.Pose.GLANCE, rig.Pose.SLUMP, rig.Pose.TYPING, rig.Pose.SIP, rig.Pose.RELAX, rig.Pose.TYPING]:
		rig.story_pose = pose
		var clear: bool = true
		for sample in range(90):
			await frames(1)
			for fist: Vector3 in solved:
				# Observe the solved bones, including each transition; allow hand thickness.
				if absf(fist.x) < 1.125 and absf(fist.z) < .475:
					clear = clear and fist.y >= .875
		check(clear, "seated pose %d and its transition keep both hands above the tabletop" % pose)
		check(not rig.blade_art.is_visible_in_tree(), "desk reactions keep the sword hidden")
	rig.story_pose = rig.Pose.TYPING
	await frames(60)
	await _coffee_cycle(backdrop)
	rig.story_pose = rig.Pose.ARMED
	await frames(2)
	check(rig.blade_art.is_visible_in_tree(), "arming for the incident restores the sword")
	rig.weapon.hide()
	await frames(2)
	check(not rig.blade_art.is_visible_in_tree(), "staging respects a separately hidden weapon pivot")
	backdrop.queue_free()
	await frames(2)


func _coffee_cycle(backdrop: Node3D) -> void:
	var rig: Node3D = backdrop.character
	var mug: Node3D = rig.coffee_mug
	var rest: Transform3D = mug.global_transform
	for cycle: int in range(2):
		rig.begin_coffee()
		var grip_error: float = 0.0
		var travel: float = 0.0
		var jump: float = 0.0
		var previous: Vector3 = mug.global_position
		var lifted: bool = false
		var sipped: bool = false
		var above_desk: bool = true
		for sample in range(330):
			await frames(1)
			jump = maxf(jump, previous.distance_to(mug.global_position))
			previous = mug.global_position
			travel = maxf(travel, rest.origin.distance_to(mug.global_position))
			var cup: MeshInstance3D = mug.get_node("Body")
			var box: AABB = cup.global_transform * cup.get_aabb()
			above_desk = above_desk and box.position.y >= .821
			if rig.coffee_time > .85 and rig.coffee_time < 4.2:
				grip_error = maxf(grip_error, rig.solved_coffee_hand.distance_to(rig.coffee_grip))
			if rig.coffee_time > 2.3 and rig.coffee_time < 2.8:
				lifted = lifted or box.position.y > 1.15
				sipped = sipped or (rig.coffee_lip.distance_to(rig.coffee_mouth) < .015 and mug.global_basis.y.dot(Vector3.UP) < .97)
				backdrop.next_notice = 0.0
				backdrop._process(0.0)
		check(travel > .45 and lifted and sipped, "coffee cycle %d lifts and tilts the actual mug to his mouth" % cycle)
		check(grip_error < .035, "coffee cycle %d keeps the solved hand on the handle (%.3f m)" % [cycle, grip_error])
		check(jump < .045 and above_desk, "pickup and return stay smooth and clear of the tabletop")
		check(not rig.coffee_active and mug.global_transform.is_equal_approx(rest) and rig.story_pose == rig.Pose.TYPING,
			"notifications do not interrupt the sip; the mug returns exactly and typing resumes")


func _effects(view: Node) -> int:
	var count: int = 0
	for child in view.get_children():
		if child is ElementFx:
			count += 1
	return count
