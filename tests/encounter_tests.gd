extends "res://tests/incident_tests.gd"
## Milestone 12 roster and encounters: outcome checks on real actors in the office.
## They verify mechanics and cleanup, not tuning, readability or fun.


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


func spawn(kind: String, at: Vector3, aware: bool = true) -> CharacterBody3D:
	var actor: CharacterBody3D = incident._spawn_entry([kind, "A1"], incident.alive)
	actor.position = at
	actor.home = at
	actor.wander_target = at
	if aware:
		actor.engage()
	return actor


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	var base_count: int = scene.find_children("*", "", true, false).size()
	# Authored composition.
	await fresh_stage(incident.Stage.INVESTIGATION)
	incident.stage = incident.Stage.ENCOUNTER_ONE
	check(incident.waves().size() == 2 and incident.stage_total() == 4, "first encounter is two authored waves")
	incident.stage = incident.Stage.ENCOUNTER_TWO
	var kinds: Array = incident.waves().map(func(wave: Array) -> Array: return wave.map(func(entry: Array) -> String: return entry[0]))
	check(kinds == [["blocker", "record", "record"], ["invite", "record", "scope"]], "containment combines support, area control and escalation")
	incident.stage = incident.Stage.INVESTIGATION
	# Crowd rules: turn-taking and separation.
	player.position = Vector3(0, .05, 5)
	var crowd: Array[CharacterBody3D] = []
	for index in range(4):
		crowd.append(spawn("record", Vector3(-.6 + index * .4, .05, 3.8)))
	var most: int = 0
	for frame in range(150):
		await frames(1)
		var winding: int = crowd.filter(func(foe: CharacterBody3D) -> bool: return foe.melee.attacking and foe.melee.elapsed < foe.melee.windup + foe.melee.active_time).size()
		most = maxi(most, winding)
	check(most > 0 and most <= incident.max_telegraphs, "a crowd never telegraphs more than %d attacks at once" % incident.max_telegraphs)
	var closest: float = 99.0
	for a in crowd:
		for b in crowd:
			if a != b:
				closest = minf(closest, a.global_position.distance_to(b.global_position))
	check(closest > .5, "separation keeps a crowd from fusing into one silhouette")
	# Blocker: cast, refuse damage, interrupt, release on death.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 9)
	var blocker: CharacterBody3D = spawn("blocker", Vector3(-3, .05, -2))
	var ally: CharacterBody3D = spawn("record", Vector3(-1, .05, -2))
	ally.set_physics_process(false)
	blocker.cast_cooldown = 0
	await frames(3)
	check(blocker.casting >= 0 and blocker.ring.visible, "blocker telegraphs its cast with a visible ring")
	await frames(80)
	check(ally.shield_left > 0 and blocker.shield_left == 0, "cast shields allies but never the blocker itself")
	var before: int = ally.health
	check(not ally.receive_damage(50, player.position) and ally.health == before and ally.label.text == "BLOCKED", "shielded ally refuses damage with explicit BLOCKED feedback")
	blocker.receive_damage(10000, player.position)
	check(ally.shield_left == 0 and ally.receive_damage(10, player.position), "killing the blocker drops every shield it granted")
	var second: CharacterBody3D = spawn("blocker", Vector3(3, .05, -2))
	var ward: CharacterBody3D = spawn("record", Vector3(4, .05, -2))
	ward.set_physics_process(false)
	second.cast_cooldown = 0
	await frames(3)
	second.receive_damage(60, player.position)
	await frames(80)
	check(second.casting < 0 and ward.shield_left == 0, "enough damage mid-cast interrupts the shield")
	# Meeting Invite: telegraphed zone, slow, drain, escape, cleanup.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 6)
	var invite: CharacterBody3D = spawn("invite", Vector3(0, .05, -2))
	invite.zone_cooldown = 0
	await frames(3)
	check(incident.zones.size() == 1 and incident.zones[0].global_position.distance_to(player.global_position) < .5, "invite books a zone at the engineer's feet")
	check(player.zone_multiplier == 1.0, "the telegraph itself does not slow")
	var hp: int = player.health
	await frames(80)
	check(player.zone_multiplier == .5 and player.health < hp, "an active meeting slows and drains attendees")
	player.position = Vector3(0, .05, 11)
	await frames(2)
	check(player.zone_multiplier == 1.0, "leaving the circle restores movement")
	await frames(260)
	check(incident.zones.is_empty() and not incident.actors.any(func(node: Node) -> bool: return node.get_script() == incident.ZONE), "expired meetings leave no actors behind")
	invite.zone_cooldown = 10
	invite.position = player.position + Vector3(0, 0, -2)
	await frames(60)
	check(invite.global_position.distance_to(player.global_position) > 2.6, "invite backs away to keep its distance")
	# Scope Creep: ignored growth, true reach, reset on hit, descoped relief.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 10)
	var creep: CharacterBody3D = spawn("scope", Vector3(0, .05, -6))
	creep.set_physics_process(true)
	var reach: float = creep.melee.reach
	creep.unhit = creep.growth_seconds - .05
	await frames(5)
	check(creep.growth == 1 and creep.melee.reach > reach and creep.health > 90 and incident.presentation.seen.has("scope_grow1"), "ignored scope creep grows in reach, damage and health")
	check(is_equal_approx(creep.tell.scale.x, 1.0) and creep.visual.scale == Vector3.ONE, "growth scales the model only; the telegraph keeps true reach")
	creep.unhit = 4.0
	creep.receive_damage(5, player.position)
	check(creep.unhit == 0, "any hit resets the growth clock")
	creep.grow()
	creep.grow()
	creep.grow()
	check(creep.growth == 3, "growth is bounded at the final stage")
	incident.run.change_burnout(30, "fixture")
	creep.receive_damage(100000, player.position)
	check(incident.run.burnout == 22 and incident.presentation.seen.has("descoped"), "defeating grown scope creep descopes Burnout")
	# Quick Sync: optional trap during investigation, rewarded once.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.health = 60
	player.max_health = 100
	incident.run.change_burnout(40, "fixture")
	player.position = Vector3(22.75, .05, -4)
	await frames(3)
	check(incident.quick_sync == "active" and incident.sync_alive.size() == 3 and incident.room.get_node("QuickSyncDoorA").collision_layer == 1, "entering Quick Sync shuts the doors and starts the meeting")
	check(incident.room.get_node("QuickSyncLight").light_energy == 0 and incident.presentation.seen.has("quick_sync_start"), "lights go out on 'Can we take this offline?'")
	for foe: CharacterBody3D in incident.sync_alive.duplicate():
		foe.receive_damage(100000, player.position)
	await frames(2)
	check(incident.quick_sync == "done" and player.health == 90 and incident.run.burnout == 20 and incident.room.get_node("QuickSyncDoorA").collision_layer == 0, "surviving the meeting restores health and Burnout and opens the doors")
	player.position = Vector3(22.75, .05, -4)
	await frames(3)
	check(incident.sync_alive.is_empty() and incident.stage == incident.Stage.INVESTIGATION, "Quick Sync never retriggers and does not advance the incident")
	# Dependency escalation adds a Blocker to the final containment wave.
	incident.corporate_choice = 2
	incident.stage = incident.Stage.ENCOUNTER_TWO
	check(incident.stage_total() == 7 and incident.waves().back().back()[0] == "blocker", "escalated dependency returns as one extra Blocker")
	incident.stage = incident.Stage.INVESTIGATION
	incident.corporate_choice = -1
	# Awareness: arrivals idle until they see, hear or are told.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 11)
	var idler: CharacterBody3D = spawn("record", Vector3(0, .05, -6), false)
	check(idler.awareness == idler.Awareness.MANIFESTING, "waves materialize before they act")
	await frames(10)
	idler.visual.rotation.y = 0.0
	await frames(110)
	check(idler.awareness == idler.Awareness.UNAWARE and idler.global_position.distance_to(Vector3(0, .05, -6)) < 3.2, "an unaware record busies itself near its arrival instead of chasing")
	var hp_before: int = idler.health
	idler.receive_damage(20, player.position)
	check(hp_before - idler.health == 40 and idler.awareness == idler.Awareness.ENGAGED, "a surprise hit lands double and engages")
	var watcher: CharacterBody3D = spawn("record", Vector3(-3, .05, 1), false)
	var colleague: CharacterBody3D = spawn("record", Vector3(-6, .05, -1), false)
	await frames(70)
	player.position = Vector3(0, .05, 8)
	# Stroll the watcher a meter toward the engineer (facing them); the colleague away.
	watcher.wander_target = watcher.global_position + (player.position - watcher.global_position).normalized()
	colleague.wander_target = colleague.global_position + Vector3(0, 0, -1)
	for still: CharacterBody3D in [watcher, colleague]:
		still.wander_left = 99.0
	for wait in range(60):
		if watcher.awareness != watcher.Awareness.UNAWARE and colleague.awareness != colleague.Awareness.UNAWARE:
			break
		await frames(1)
	check(watcher.awareness in [watcher.Awareness.NOTICING, watcher.Awareness.ENGAGED], "a record that faces the engineer within range notices")
	check(colleague.awareness in [colleague.Awareness.NOTICING, colleague.Awareness.ENGAGED], "noticing alerts colleagues within ten meters")
	check(incident.presentation.seen.has("spotted"), "the first sighting files a spotted alert")
	var listener: CharacterBody3D = spawn("record", Vector3(5, .05, 6), false)
	await frames(70)
	listener.visual.rotation.y = PI * .5
	player.request_attack()
	await frames(20)
	check(listener.awareness != listener.Awareness.UNAWARE, "attacking within earshot is heard even behind its back")
	var bored: CharacterBody3D = spawn("record", Vector3(12, .05, -12), false)
	bored.patience = 1.5
	await frames(180)
	check(bored.awareness != bored.Awareness.UNAWARE, "an ignored arrival is assigned to the engineer after its patience runs out")
	# Engaged pursuers lose a hidden engineer and search the last known spot.
	await fresh_stage(incident.Stage.INVESTIGATION)
	var seeker: CharacterBody3D = spawn("record", Vector3(-1, .05, -6))
	seeker.move_speed = .4
	player.position = Vector3(22.6, .05, 8)
	seeker.last_seen = Vector3(0, .05, 0)
	await frames(60 * 7)
	check(seeker.awareness == seeker.Awareness.SEARCHING or seeker.awareness == seeker.Awareness.UNAWARE, "losing sight for long enough turns pursuit into a search")
	# Reset cleans every new actor kind.
	await fresh_stage(incident.Stage.INVESTIGATION)
	spawn("blocker", Vector3(-3, .05, -2))
	spawn("scope", Vector3(3, .05, -2))
	var booked: CharacterBody3D = spawn("invite", Vector3(0, .05, -2))
	booked.zone_cooldown = 0
	await frames(3)
	scene.reset_encounter()
	await frames(3)
	check(get_nodes_in_group("enemies").is_empty() and incident.zones.is_empty() and player.zone_multiplier == 1.0, "restart removes enemies, meetings and slows")
	check(scene.find_children("*", "", true, false).size() == base_count, "restart keeps a stable node count with the new roster")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
