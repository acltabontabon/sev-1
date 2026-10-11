extends "res://tests/encounter_tests.gd"
## Real actors: skill damage must coincide with a strike, without incidental combo hits.
## --preview also captures the contact poses using the actual renderer.


func fixture(at: Vector3) -> CharacterBody3D:
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 5)
	player.camera_rig.rotation.y = 0.0
	await frames(4)
	# A rendered window can lose capture while macOS brings it forward on launch.
	player.camera_rig.set_capture(true)
	for settle in range(12):
		if player.is_on_floor() and not paused:
			break
		await frames(1)
	var foe: CharacterBody3D = spawn("record", at, true)
	foe.max_health = 1000
	foe.health = 1000
	foe.set_physics_process(false)
	return foe


func shot(label: String) -> void:
	if not "--preview" in OS.get_cmdline_user_args():
		return
	scene.get_node("HUD").hide()
	var camera: Camera3D = Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.position = player.global_position + Vector3(4, 2.6, 5)
	camera.look_at(player.global_position + Vector3(0, .9, -.7))
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds")
	check(root.get_texture().get_image().save_png("res://builds/skill_" + label + ".png") == OK, "rendered " + label + " contact captured")
	camera.queue_free()
	player.get_node("CameraRig/SpringArm3D/Camera3D").current = true
	scene.get_node("HUD").show()


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	var rig: Node3D = player.get_node("Visual/Character")
	var foe: CharacterBody3D = await fixture(Vector3(0, .05, 2))
	check(player.specials.reply_all(), "Reply All accepts grounded input")
	var waited: int = 0
	while foe.health == 1000 and waited < 15:
		await frames(1)
		waited += 1
	check(foe.health == 955 and waited <= 10, "Reply All connects at 3 m within ten physics frames")
	check(foe.hitstop_left > 0 and player.hitstop_left == 0, "projectile contact holds the victim without arresting movement")
	await shot("reply_all")

	foe = await fixture(Vector3(0, .05, 3.5))
	check(player.specials.blame_shift(), "Blame Shift accepts input")
	await frames(4)
	check(foe.health == 945 and player.melee.is_active(), "dash damage lands while the diagonal cut is active")
	check(player.hitstop_left == 0 and not player.dash_velocity.is_zero_approx(), "dash contact preserves travel through the victim")
	await shot("blame_shift")
	await frames(35)
	check(foe.health == 945, "dash follow-through adds no unrelated melee damage")

	foe = await fixture(Vector3(0, .05, 3.5))
	check(player.specials.circle_back(), "Circle Back accepts input")
	var contacts: int = 0
	var previous_health: int = foe.health
	for tick in range(110):
		await frames(1)
		if foe.health != previous_health:
			contacts += 1
			check(player.melee.is_active(), "whirlwind pulse " + str(contacts) + " coincides with the visible backhand")
			check(player.hitstop_left > 0 and foe.hitstop_left > 0, "whirlwind contact briefly holds both actors")
			check(rig.spin > .1 and rig.held == 0.0 and rig.shoulder_rest == 0.0, "contact holds the released rig pose, not the previous anticipation")
			previous_health = foe.health
			if contacts == 1:
				await shot("circle_back")
	check(contacts == 4 and foe.health == 928, "whirlwind delivers exactly four pulses without bonus combo hits")
	check(foe.stagger_left >= 1.2, "the fourth pulse parks survivors")

	foe = await fixture(Vector3(1.5, .05, 5))
	check(player.specials.works_on_my_machine(), "counter opens")
	if "--preview" in OS.get_cmdline_user_args():
		await frames(6)
		await shot("guard")
	check(not player.receive_damage(30, foe.global_position), "counter cancels incoming damage")
	check(foe.health == 940 and player.melee.is_active(), "counter damage coincides with an already released riposte")
	check(rig.spin > .1 and rig.right_ik.influence == 1.0, "counter's sword and grip snap to the contact before the hit pause")
	check((-player.visual.global_basis.z).dot(Vector3.RIGHT) > .99, "riposte faces its attacker even when camera faces elsewhere")
	await frames(1)
	await shot("counter")
	await frames(40)
	check(foe.health == 940, "riposte adds no delayed combo damage")

	foe = await fixture(Vector3(0, .05, 3.5))
	foe.protect(2.0)
	player.specials.circle_back()
	await frames(8)
	check(foe.health == 1000 and player.hitstop_left == 0 and player.specials.focus == 0, "shield rejection produces no landed-hit pause or FOCUS")

	foe = await fixture(Vector3(0, .05, 3.5))
	player.hitstop_enabled = false
	player.specials.circle_back()
	await frames(8)
	check(foe.health == 982 and player.hitstop_left == 0 and foe.hitstop_left == 0, "hit-stop preference also applies to special impacts")
	player.hitstop_enabled = true

	foe = await fixture(Vector3(0, .05, 3.5))
	player.specials.add_focus(100)
	check(player.specials.rollback(), "ultimate starts with full FOCUS")
	var wait_limit: int = 0
	while player.specials.omnislashing() and wait_limit < 150:
		await frames(1)
		wait_limit += 1
	check(player.specials.queued == "rollback" and not player.melee.is_active(), "return blink prepares the slam before applying its damage")
	var before_slam: int = foe.health
	while not player.specials.queued.is_empty() and wait_limit < 170:
		await frames(1)
		wait_limit += 1
	check(before_slam - foe.health == 110 and player.melee.is_active(), "ultimate slam damage lands on the overhead strike's active frame")
	await shot("rollback")
	scene.reset_encounter()
	check(not player.melee.presentation_only and player.specials.queued.is_empty(), "restart restores ordinary melee and clears pending skill strikes")
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)
