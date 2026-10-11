extends "res://tests/incident_tests.gd"
## The pantry birthday: the wider room, planted guests, the skippable scene, the cake
## ambush, its reward and retry. Outcome checks on real actors; they establish wiring,
## not comedy, sound, readability or fun.


func fresh_stage(next: int) -> void:
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	player.max_health = 10000
	player.health = 10000
	incident.presentation.skip()
	await frames(3)
	incident._cleanup()
	for stage_step in range(incident.Stage.INVESTIGATION, next + 1):
		incident._enter(stage_step)
	await frames(2)


func join_party() -> void:
	player.position = incident.room.get_node("SpawnPoints/PartyJoin").position
	player.velocity = Vector3.ZERO
	await frames(2)
	await key(KEY_E)


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	incident._cleanup()
	await frames(3)
	var room: Node3D = incident.room
	var map: RID = player.get_world_3d().navigation_map
	for entry: Array in [["the party table", room.get_node("SpawnPoints/PartyJoin").position], ["the moved coffee machine", room.get_node("SpawnPoints/CoffeeMachine").position], ["the annex behind the party", Vector3(29.5, .05, 14.6)]]:
		var route: PackedVector3Array = NavigationServer3D.map_get_path(map, Vector3(16.3, 0, 8.5), entry[1], true)
		check(not route.is_empty() and route[route.size() - 1].distance_to(entry[1]) < 1.0, "navigation reaches %s through the pantry doorway" % entry[0])
	check(room.get_node("PantryEastWall").position.x > 31.0 and room.get_node("CoffeeMachine").position.x > 29.5, "the annex moves the east wall and kitchen four metres out")
	check(room.get_node("BirthdayCake/Intact").visible and room.get_node("BirthdayCake/Flames").visible and not room.get_node("BirthdayCake/Ruin").visible, "the cake waits intact with its candles lit")
	check(incident.party_hosts.is_empty(), "nobody is celebrating while the first wave is due")

	await fresh_stage(incident.Stage.INVESTIGATION)
	var names: Array = incident.party_hosts.map(func(host: Node3D) -> String: return str(host.identity.name))
	check(names == ["KEVIN", "BRENDA", "MARCO"], "Kevin and two guests are celebrating during the investigation")
	check(incident.party_hosts.all(func(host: Node3D) -> bool: return host.position.x > 18.8 and host.position.x < 31.0 and host.position.z > 2.2 and host.position.z < 15.3), "every guest stands inside the pantry")
	check(incident.party_hosts.all(func(host: Node3D) -> bool: return not host.find_children("PartyHat", "", true, false).is_empty()), "every guest wears a party hat")
	check(incident.party_hosts[0].idle_clip == "ual/fold_arms", "Kevin endures his own party")
	player.position = Vector3(16.5, .05, 8.5)
	await frames(2)
	check("birthday" in str(incident.next_step().get("text", "")), "NEXT offers the optional birthday at the pantry doorway")
	player.position = room.get_node("SpawnPoints/PartyJoin").position
	await frames(2)
	check(incident.nearest_interaction() == "party" and incident.interactions.party.label.visible, "E — SING HAPPY BIRTHDAY appears in front of the table")
	player.position = room.get_node("SpawnPoints/CoffeeMachine").position
	await frames(2)
	check(incident.nearest_interaction() == "coffee", "the moved coffee machine still answers E")
	player.position = incident.party_hosts[1].position + Vector3(.8, 0, 0)
	player.visual.rotation.y = PI * .5
	var stage: int = incident.stage
	player.request_attack()
	await frames(8)
	check(incident.party == "idle" and incident.stage == stage, "swinging at a guest is an HR matter, not the party")

	# Headless: no cutscene; joining turns the guests and the cake at once.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.max_health = 200
	player.health = 100
	incident.run.burnout = 40
	await join_party()
	check(incident.party == "active" and incident.party_alive.size() == 3 and incident.party_hosts.is_empty(), "singing turns all three guests")
	check(incident.party_alive[0].rig.kind == "scope" and incident.party_alive[1].rig.kind == "record" and incident.party_alive[2].rig.kind == "record", "Kevin becomes Scope Creep; his guests become records")
	check(not incident.party_alive[0].details.find_children("PartyHat", "", true, false).is_empty(), "Kevin's Scope Creep keeps the party hat")
	check(incident.bugs.size() == incident.PARTY_BUGS and room.get_node("BirthdayCake/Ruin").visible and not room.get_node("BirthdayCake/Intact").visible, "the cake bursts into a bug swarm")
	check(incident.party_alive.all(func(foe: CharacterBody3D) -> bool: return foe.starts_aware), "the party is an ambush")
	check(incident.encounter_status() == "Birthday · 3 left" and "Kevin" in str(incident.next_step().get("text", "")), "HUD and NEXT track the party fight")
	incident.inspect_console()
	check(not incident.management_call.active, "Management waits until the party is over")
	player.position = Vector3(22.75, .05, -8)
	await frames(3)
	check(incident.quick_sync == "idle", "Quick Sync cannot start in the middle of the party")
	for foe: CharacterBody3D in incident.party_alive.duplicate():
		foe.receive_damage(100000, player.position)
	await frames(3)
	check(incident.party == "done" and player.health == 130 and incident.run.burnout == 25, "ending the party restores health and Burnout")
	check(incident.bugs.all(func(bug: CharacterBody3D) -> bool: return not is_instance_valid(bug) or bug.health <= 0), "leftover cake bugs are closed as WONTFIX")
	check(incident.stage == incident.Stage.INVESTIGATION and not incident.interactions.party.enabled, "the party never retriggers and does not advance the incident")
	incident.use("party")
	check(incident.party == "done" and incident.party_alive.is_empty(), "singing again at the ruined cake does nothing")

	# Rendered path: the voiced scene, candles out, candles back, TAB to the fight.
	incident.party_in_headless = true
	await fresh_stage(incident.Stage.INVESTIGATION)
	await join_party()
	check(incident.party == "cake" and player.narrative_hold and incident.modal_pending() and incident.party_alive.is_empty(), "joining starts the birthday before anyone transforms")
	check("Surprise" in incident.party_scene.caption.text and incident.party_hosts[1].animator.current_animation == "ual/talking", "Brenda opens with the surprise")
	incident.party_scene._next()
	check("Kelvin" in incident.party_scene.caption.text, "a guest notices whose name is on the cake")
	while incident.party_scene.step < 5:
		incident.party_scene._next()
	check("weekend" in incident.party_scene.caption.text, "Kevin wishes for a weekend")
	incident.party_scene.blow_left = .001
	await frames(2)
	check(not room.get_node("BirthdayCake/Flames").visible, "Kevin blows the candles out")
	incident.party_scene._next()
	check(room.get_node("BirthdayCake/Flames").visible and "MORE SCOPE" in incident.party_scene.caption.text, "the trick candles relight as Kevin starts to turn")
	await key(KEY_TAB)
	check(incident.party == "active" and not player.narrative_hold and incident.party_scene == null and incident.party_alive.size() == 3, "skipping hands off to the fight with control restored")

	await fresh_stage(incident.Stage.INVESTIGATION)
	await join_party()
	scene.reset_encounter()
	await frames(2)
	check(not player.narrative_hold and incident.party_scene == null and incident.party == "idle", "restarting during the birthday clears its camera and control hold")
	check(room.get_node("BirthdayCake/Intact").visible and room.get_node("BirthdayCake/Flames").visible, "restarting restores the cake and its candles")

	await fresh_stage(incident.Stage.INVESTIGATION)
	await join_party()
	while incident.party_scene.step < incident.party_scene.STEPS.size() - 1:
		incident.party_scene._next()
	incident.party_scene.left = .001
	await frames(2)
	check(incident.party == "active" and incident.party_scene == null and not player.narrative_hold, "the last line hands off to the transformation without a skip")
	incident.party_in_headless = false

	await fresh_stage(incident.Stage.ENCOUNTER_TWO)
	await frames(2)
	check(incident.party_hosts.is_empty() and incident.party == "idle" and not incident.interactions.party.enabled, "an ignored party goes home when containment starts")
	check(room.get_node("BirthdayCake/Intact").visible, "the uneaten cake stays on the table")

	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
