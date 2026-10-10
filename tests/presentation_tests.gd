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
	check(view.get_node("WeaponPivot/EscalationBlade") != null and view.animator.has_animation("rig/roll") and view.animator.has_animation("rig/death"), "rigged engineer loads the keyboard and the retargeted action clips")
	var tip: Vector3 = view.weapon.transform * Vector3(0, 0, -1.47)
	check(tip.y > .05, "resting keyboard stays above floor")
	var rest: Transform3D = view.weapon.transform
	player.request_attack()
	await frames(4)
	check(not view.weapon.transform.is_equal_approx(rest) and enemy.health == enemy.max_health, "anticipation moves weapon before any damage")
	await frames(7)
	check(enemy.health == enemy.max_health - 25, "visible strike uses existing damage event exactly once")
	check(_effects(view) > 0, "the strike releases its element as presentation")
	await frames(30)
	check(not player.melee.attacking and view.weapon.position.distance_to(view.carry_transform().origin) < .05, "recovery returns the keyboard to the fist")
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
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)


func _effects(view: Node) -> int:
	var count: int = 0
	for child in view.get_children():
		if child is ElementFx:
			count += 1
	return count
