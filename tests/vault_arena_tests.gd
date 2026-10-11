extends "res://tests/vault_response_tests.gd"
## Real melee/skill contacts, intact collisions, bounded debris and repeatable reset.
var credited: int = 0

func _run() -> void:
	var scene: Node = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	var incident: Node = scene.get_node("Incident")
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	incident._cleanup()
	incident.set_process(false)
	await frames(5)
	var props: Array[Node] = get_nodes_in_group("breakables")
	check(props.size() == 6, "six finite breakable equipment props populate the arena")
	var prop: Node3D = props[0]
	player.position = prop.global_position + Vector3(0,.05,1.7)
	player.camera_rig.rotation.y = 0
	player.melee.hit_landed.connect(func(_target: Node3D) -> void: credited += 1)
	await frames(4)
	player.request_attack()
	await frames(40)
	check(prop.health > 0 and prop.health < 32 and prop.collision_layer == 1, "first real sword hit dents the prop while its collision stays solid")
	player.request_attack()
	await frames(50)
	check(prop.health == 0 and prop.shape.disabled and prop.collision_layer == 0 and prop.debris.size() == 6, "second strike breaks the prop into six pieces and clears its collision")
	check(credited == 0 and player.specials.focus == 0, "breaking equipment produces no enemy hit credit or ultimate charge")
	var bounded: bool = true
	await frames(240)
	for piece: RigidBody3D in prop.debris:
		bounded = bounded and piece.global_position.distance_to(prop.global_position) < 4 and piece.collision_layer == 128
	check(bounded, "debris settles nearby on a layer that cannot obstruct the player")
	prop.reset_prop()
	await frames(3)
	player.specials.reset()
	player.position = prop.global_position + Vector3(0,.05,1.7)
	await frames(3)
	check(player.specials.circle_back(), "Circle Back accepts input beside intact equipment")
	await frames(120)
	check(prop.health == 0 and prop.debris.size() == 6, "actual whirlwind pulses smash equipment without duplicate debris")
	prop.reset_prop()
	await frames(3)
	player.specials.reset()
	player.position = prop.global_position + Vector3(0,.05,3)
	await frames(3)
	check(player.specials.reply_all(), "Reply All accepts input toward equipment")
	await frames(45)
	check(prop.health == 0, "the traveling slash connects with the prop's solid envelope")
	prop.reset_prop()
	await frames(3)
	player.specials.reset()
	player.position = prop.global_position + Vector3(0,.05,2.5)
	player.camera_rig.rotation.y = 0
	await frames(3)
	check(player.specials.blame_shift(), "Blame Shift accepts input toward equipment")
	await frames(45)
	check(prop.health == 0, "the dash slash breaks equipment on contact")
	# An actual wall between the sword and prop must still reject a melee contact.
	prop.reset_prop()
	player.specials.reset()
	player.position = prop.global_position + Vector3(0,.05,1.7)
	var wall: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2,3,.2)
	shape.shape = box
	wall.add_child(shape)
	scene.add_child(wall)
	wall.position = prop.global_position + Vector3(0,1.5,.85)
	await frames(3)
	player.request_attack()
	await frames(45)
	check(prop.health == 32, "a wall still prevents melee damage to equipment behind it")
	wall.queue_free()
	for candidate: Node in props:
		candidate.receive_damage(1000,player.position)
	scene.reset_encounter()
	await frames(5)
	var restored: bool = true
	for candidate: Node in props:
		restored = restored and candidate.health == 32 and candidate.intact.visible and candidate.debris.is_empty() and not candidate.shape.disabled
	check(restored, "encounter retry restores all equipment and removes every old debris body")
	var map: RID = player.get_world_3d().navigation_map
	for spot: Vector3 in [Vector3(3.6,0,-47),Vector3(14.4,0,-47),Vector3(9,0,-48)]:
		var path: PackedVector3Array = NavigationServer3D.map_get_path(map,Vector3(9,0,-32),spot,true)
		check(not path.is_empty() and path[path.size()-1].distance_to(spot)<.8,"expanded arena has a reachable dodge lane at %s" % spot)
	scene.queue_free()
	paused = false
	await frames(3)
	quit(1 if failures else 0)
