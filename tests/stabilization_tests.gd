extends "res://tests/incident_tests.gd"
## Bounded simulated runs use real melee/timers, staged positioning and elevated health.
## This is lifecycle coverage, not a balance, navigation, duration or fun playtest.


func boss_fixture() -> CharacterBody3D:
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	for next in [incident.Stage.ENCOUNTER_ONE, incident.Stage.INVESTIGATION, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	incident._spawn()
	return incident.active_enemy


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	var boss: CharacterBody3D = boss_fixture()
	boss.phase_time = 7.98
	boss.exposed = true
	boss.apply_hitstop(.12)
	await frames(4)
	check(boss.receive_damage(25, player.position), "original still takes damage when impact freezes the end of OPEN")
	await frames(12)
	check(not boss.receive_damage(25, player.position), "shield resumes after hit-stop and remaining OPEN expire")
	if "--boss-regression" not in OS.get_cmdline_user_args():
		await verify_ui()
		await simulated_runs()
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)


func verify_ui() -> void:
	scene.reset_encounter()
	player.camera_rig.set_capture(false)
	var hud: CanvasLayer = scene.get_node("HUD")
	await frames(3)
	var shake: CheckButton = hud.comfort.get_node("Shake")
	var flash: CheckButton = hud.comfort.get_node("Flash")
	await click_control(shake)
	await click_control(flash)
	check(paused and not player.camera_rig.controls_active and not shake.button_pressed and not flash.button_pressed, "pointer comfort changes do not resume combat")
	player.camera_rig.set_capture(true)
	player.camera_rig.add_impulse(1)
	player.receive_damage(20, Vector3.ZERO)
	await frames(2)
	check(player.camera_rig.get_node("SpringArm3D/Camera3D").rotation.is_zero_approx(), "disabled camera shake keeps the rendered camera steady after impact")
	check(hud.get_node("DamageFlash").color.a == 0, "disabled damage flash remains invisible after damage")
	scene.reset_encounter()
	check(not shake.button_pressed and not flash.button_pressed and player.camera_rig.impulse_degrees == 0, "comfort preferences survive run restart")
	shake.button_pressed = true
	flash.button_pressed = true
	player.camera_rig.set_capture(true)
	player.camera_rig.add_impulse(1)
	player.receive_damage(20, Vector3.ZERO)
	await frames(2)
	check(not player.camera_rig.get_node("SpringArm3D/Camera3D").rotation.is_zero_approx() and hud.get_node("DamageFlash").color.a > 0, "comfort options restore impact feedback")
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	incident._enter(incident.Stage.ENCOUNTER_ONE)
	incident._offer_upgrade(incident.Stage.INVESTIGATION)
	await frames(3)
	check(incident.upgrade_ui.buttons[0].has_focus(), "upgrade begins with a visible keyboard selection")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	check(incident.run.choices == [1] and not paused and not player.melee.attacking, "Down and Enter select the next upgrade without leaking combat input")
	player.position = incident.CONSOLE_POSITION
	incident.inspect_console()
	incident.run.change_burnout(29, "Preview fixture")
	incident.choose_system(3)
	await frames(3)
	check("29 → 64 / PRESSURED" in incident.upgrade_ui.summary(0) and "Taken 90%" in incident.upgrade_ui.summary(0), "management preview includes the immediate burnout band and combined defense")
	for button in incident.upgrade_ui.buttons:
		check(root.get_visible_rect().encloses(button.get_global_rect()), "management card fits inside the development viewport")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	check(incident.corporate_choice == 1 and not paused, "management arrow navigation resumes the correct path")
	await frames(3)
	check("6 threats remaining" in hud.status.text and "arrival" in hud.status.text, "HUD explains encounter count and the scheduled arrival")
	check(incident.run.modifier_summary() in hud.find_child("Burnout", true, false).text, "HUD shows combined active modifiers")
	await key(KEY_R)
	await frames(3)
	player.camera_rig.set_capture(false)
	check(hud.prompt.visible and not hud.get_node("Margin").visible and not hud.get_node("Controls").visible, "pause text has no overlapping gameplay HUD")
	incident.fail()
	await frames(3)
	check(not hud.comfort.visible and hud.prompt.visible, "terminal report has no overlapping settings")
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	incident._enter(incident.Stage.ENCOUNTER_ONE)
	incident._spawn()
	var old_enemy: CharacterBody3D = incident.active_enemy
	scene.reset_encounter()
	check(old_enemy.collision_layer == 0 and old_enemy.is_queued_for_deletion(), "restart disables old enemy collision before deferred deletion")
	await frames(3)


func click_control(control: Control) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	for pressed in [true, false]:
		var click: InputEventMouseButton = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = point
		click.pressed = pressed
		root.push_input(click, true)
		await frames(2)


func simulated_runs() -> void:
	for path in range(3):
		scene.reset_encounter()
		player.max_health = 10000
		player.health = 10000
		player.camera_rig.set_capture(true)
		var base_nodes: int = scene.find_children("*", "", true, false).size()
		var saw_copies: bool = false
		var second_choice: bool = false
		# At 60 Hz this allows four simulated minutes, with an explicit failure bound.
		for tick in range(14400):
			if incident.terminal():
				break
			if incident.upgrade_pending:
				if incident.run.choices.size() == 1:
					second_choice = true
				await key([KEY_1, KEY_2, KEY_3][path])
			elif incident.decision_pending:
				await key([KEY_1, KEY_2, KEY_3][path])
			elif incident.stage == incident.Stage.INVESTIGATION:
				player.position = incident.CONSOLE_POSITION
				await key(KEY_E)
				await key(KEY_3)
			elif incident.stage == incident.Stage.BOSS and not incident.boss_triggered:
				await enter_vault()
			elif is_instance_valid(incident.active_enemy):
				var foe: CharacterBody3D = incident.active_enemy
				# Keep real AI/melee active, but stage both fighters in the clear lane.
				if not player.melee.attacking and not player.dodging:
					player.position = Vector3(0, .05, 5)
					foe.position = Vector3(0, .05, 3.4)
					player.camera_rig.reset_view()
				if not player.melee.attacking or player.melee.remaining_time() < .18:
					await key(KEY_F)
				saw_copies = saw_copies or not incident.copies.is_empty()
			await frames(1)
		check(incident.stage == incident.Stage.RESOLVED and paused, "real-melee simulated path %d completes alert through victory within bound" % path)
		check(incident.run.choices == [path, path] and second_choice and incident.corporate_choice == path, "simulated path %d traverses both upgrades and its management response" % path)
		check(saw_copies and incident.copies.is_empty(), "simulated path %d creates then cleans the boss copies" % path)
		check(incident.challenge_result == ("Met — bonus recovery" if path == 0 else "Not requested"), "simulated path %d records the intended commitment result" % path)
		await key(KEY_R)
		await frames(3)
		check(scene.find_children("*", "", true, false).size() == base_nodes and incident.run.choices.is_empty() and incident.run.burnout == 0 and incident.run.debt == 0, "simulated path %d restarts with stable nodes and neutral modifiers" % path)
	player.max_health = 100
	scene.reset_encounter()
