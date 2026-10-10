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
	# Roaming: waves break out at named sites away from the engineer, marked by a beacon.
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	player.max_health = 10000
	player.health = 10000
	incident.presentation.skip()
	for wait in range(400):
		if not incident.alive.is_empty():
			break
		await frames(1)
	await frames(30)
	var first_area: String = incident.wave_area
	var nearest: float = INF
	for foe: CharacterBody3D in incident.alive:
		nearest = minf(nearest, Vector2(foe.global_position.x - player.global_position.x, foe.global_position.z - player.global_position.z).length())
	check(first_area != "" and nearest > 10.0 and incident.beacon.visible and incident.encounter_status().begins_with("Incident reported at " + first_area), "the first wave breaks out at a named site away from the engineer, with a beacon")
	for foe: CharacterBody3D in incident.alive.duplicate():
		foe.receive_damage(100000, player.position)
	for wait in range(600):
		if not incident.alive.is_empty():
			break
		await frames(1)
	check(incident.wave_area != "" and incident.wave_area != first_area, "the next wave breaks out somewhere else")
	# Every archetype wears its own CC0 rigged body; the native boxes stay hidden.
	await fresh_stage(incident.Stage.INVESTIGATION)
	var worn: Array = []
	for kind: String in ["record", "blocker", "invite", "scope"]:
		var body: CharacterBody3D = spawn(kind, Vector3(worn.size() * 2.5 - 4, .05, -6))
		worn.append([body.rig.kind if body.rig != null else "", body.get_node("Visual/Body").visible])
	check(worn == [["record", false], ["blocker", false], ["invite", false], ["scope", false]], "each archetype wears its own rigged body")
	# A Blocker's slam lands as a quake: camera tremor near the impact, effects on the floor.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 2)
	player.camera_rig.reset_view()
	var slammer: CharacterBody3D = spawn("blocker", Vector3(0, .05, 0))
	slammer.melee.start()
	var guard: int = 0
	while slammer.melee.attacking and not slammer.melee.is_active() and guard < 120:
		guard += 1
		await frames(1)
	await frames(2)
	var quaking: int = slammer.get_children().filter(func(child: Node) -> bool: return child is ElementFx).size()
	check(player.camera_rig.tremor > 0 and quaking >= 4, "a blocker slam shakes the camera and cracks the floor")
	slammer.reset_enemy()
	player.camera_rig.reset_view()
	check(player.camera_rig.tremor == 0 and slammer.get_children().filter(func(child: Node) -> bool: return child is ElementFx).is_empty(), "reset clears the quake and the tremor")
	# Minions: one hit fixes a bug; whatever survives the stage is closed as WONTFIX.
	await fresh_stage(incident.Stage.INVESTIGATION)
	var swatted: CharacterBody3D = spawn("bug", Vector3(-2, .05, -3))
	swatted.receive_damage(1, player.position)
	check(swatted.health == 0, "any accepted hit fixes a bug")
	var stragglers: Array[CharacterBody3D] = []
	for index in range(3):
		var straggler: CharacterBody3D = spawn("bug", Vector3(index * 1.5 - 2, .05, -6))
		incident.bugs.append(straggler)
		straggler.died.connect(incident._on_bug_died.bind(straggler), CONNECT_ONE_SHOT)
		stragglers.append(straggler)
	incident._close_bugs()
	check(incident.bugs.is_empty() and stragglers.all(func(bug: CharacterBody3D) -> bool: return bug.health == 0), "clearing a stage closes every surviving bug as WONTFIX")
	# The overtime crew cowers during a fight and the manager takes the credit after.
	var crew: Node3D = incident.coworkers
	incident.battle_mode.engaged = true
	crew._process(.016)
	var manager: AnimationPlayer = crew.people[2].animator
	check(crew.people.size() == 4 and manager.current_animation.ends_with("Defeat"), "coworkers cower while an enemy is engaged")
	incident.battle_mode.engaged = false
	crew._process(.016)
	check(manager.current_animation.ends_with("Victory") and (crew.people[2].line as Label3D).text == "Great teamwork, everyone!", "after the fight the manager takes the credit")
	crew.reset()
	check(not manager.current_animation.ends_with("Victory") and crew.find_children("*", "CollisionObject3D", true, false).is_empty(), "crew resets and never blocks the fight")
	# Combat framing: a resting mouse lets the view ease toward the fight; input takes it back.
	var rig: Node3D = player.camera_rig
	rig.reset_view()
	rig.controls_active = true
	rig.focus = player.global_position + Vector3(6, 0, 0)
	rig.input_idle = 5.0
	var before_yaw: float = rig.rotation.y
	for step in range(30):
		rig._frame_fight(1.0 / 60.0)
	check(absf(angle_difference(before_yaw, rig.rotation.y)) > .3, "a resting mouse lets the camera turn toward the fight")
	rig.orbit(Vector2(4, 0))
	var held_yaw: float = rig.rotation.y
	rig._frame_fight(1.0 / 60.0)
	check(rig.rotation.y == held_yaw, "mouse input hands the camera straight back")
	rig.reset_view()
	# Freeze-frame: always restores real-time speed.
	ElementFx.freeze_in_headless = true
	ElementFx.freeze(incident, .05)
	var frozen_scale: float = Engine.time_scale
	await create_timer(.2, true, false, true).timeout
	check(frozen_scale < .1 and Engine.time_scale == 1.0, "a freeze-frame stops the fight briefly and restores speed")
	ElementFx.freeze_in_headless = false
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
	# Awareness: arrivals idle until they see the engineer or are hit; colleagues investigate.
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
	check(colleague.awareness == colleague.Awareness.SEARCHING or colleague.awareness in [colleague.Awareness.NOTICING, colleague.Awareness.ENGAGED], "noticing sends colleagues within ten meters to look")
	check(incident.presentation.seen.has("spotted"), "the first sighting files a spotted alert")
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 8)
	var listener: CharacterBody3D = spawn("record", Vector3(5, .05, 6), false)
	# Short-sighted for this check: it cannot see the engineer 5 m away, only hear them.
	listener.sight_range = 3.0
	await frames(70)
	check(listener.awareness == listener.Awareness.UNAWARE, "an arrival that cannot see the engineer stays busy")
	player.request_attack()
	await frames(20)
	check(listener.awareness == listener.Awareness.UNAWARE, "noise behind its back does not start a chase")
	var bored: CharacterBody3D = spawn("record", Vector3(12, .05, -12), false)
	await frames(60 * 20)
	check(bored.awareness == bored.Awareness.UNAWARE, "an unseen arrival keeps waiting where it broke out, however long it takes")
	var poked: CharacterBody3D = spawn("record", Vector3(-9, .05, -10), false)
	await frames(70)
	poked.receive_damage(5, player.position)
	check(poked.awareness == poked.Awareness.ENGAGED, "hitting an enemy makes it chase")
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
