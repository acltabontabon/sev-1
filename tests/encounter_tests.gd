extends "res://tests/incident_tests.gd"
## Milestone 12 roster and encounters: outcome checks on real actors in the office.
## They verify mechanics and cleanup, not tuning, readability or fun.


## Check physical support, not navigation height, including raised floors and reveal parents.
func check_npc_support() -> void:
	for site: Array in incident.SITES:
		var at: Vector3 = incident._on_floor(site[1])
		var host: Node3D = incident._make_host("record", at)
		await frames(3)
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			host.global_position + Vector3.UP * .1, host.global_position - Vector3.UP, 1)
		var support: Dictionary = host.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not support.is_empty() and absf(host.global_position.y - support.position.y - .05) < .005,
			"strange employee stands on the physical floor at %s" % site[0])
		# A reveal reparents the employee onto an enemy at navigation height.
		var carrier: Node3D = Node3D.new()
		incident.add_child(carrier)
		carrier.position = at
		host.reparent(carrier)
		host.position = Vector3.ZERO
		await frames(3)
		check(absf(host.global_position.y - support.position.y - .05) < .005,
			"transformation keeps the employee grounded at %s" % site[0])
		carrier.position.y = support.position.y
		await frames(3)
		check(absf(host.global_position.y - support.position.y - .05) < .005,
			"employee stays grounded when its reveal parent settles at %s" % site[0])
		incident.actors.erase(host)
		carrier.queue_free()
		await frames(1)
	for someone: Dictionary in incident.coworkers.people:
		if someone.entry.routine in ["sit", "asleep"]:
			continue # Furniture contact has dedicated hip/leg checks below.
		var body: Node3D = someone.body
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			body.global_position + Vector3.UP * .1, body.global_position - Vector3.UP, 1)
		var support: Dictionary = body.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not support.is_empty() and absf(body.global_position.y - support.position.y) < .005,
			"regular coworker %s is supported by the floor or conference deck" % someone.entry.name)


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


## One of the boss's moves on the engineer 4 m in front of it, who either stands there
## (facing it) or takes the way out. Returns the damage taken.
func move_outcome(boss: CharacterBody3D, move: String, escape: bool) -> int:
	var moves: Node3D = boss.moves
	moves.cancel()
	boss.phase_time = 0.0
	player.health = 10000
	player.invulnerable_left = 0.0
	player.position = boss.global_position + Vector3(0, 0, 4.0)
	moves.turn = moves.ORDER.find(move)
	moves.start(player)
	var before: int = player.health
	while moves.active():
		boss.phase_time = minf(boss.phase_time, 3.0)
		player.camera_rig.rotation.y = PI if escape and move == "expose" else 0.0
		if escape and move in ["delayer", "downsize"] and moves.t > 1.35 or escape and move == "pop" and moves.t > .1:
			player.position = boss.global_position + Vector3(5.0, 0, 4.0)
		if escape and move == "decommission":
			player.invulnerable_left = .2
		await physics_frame
	return before - player.health


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
	await check_npc_support()
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
	# Tactics: a squad surrounds (back first), reads wind-ups, lunges in, regroups once.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 2)
	player.visual.rotation.y = 0.0
	var squad: Array[CharacterBody3D] = []
	for index in range(3):
		var member: CharacterBody3D = spawn("record", Vector3(index * 2.0 - 2.0, .05, -4), true)
		member.set_physics_process(false)
		squad.append(member)
	incident.slot_clock = 0.0
	incident._assign_slots(.016)
	var angles: Array[float] = []
	var behind_taken: bool = false
	for member: CharacterBody3D in squad:
		angles.append(atan2(member.slot.x - player.position.x, member.slot.z - player.position.z))
		behind_taken = behind_taken or member.slot.z > player.position.z + 1.5
	var spread_out: bool = absf(angle_difference(angles[0], angles[1])) > .8 and absf(angle_difference(angles[1], angles[2])) > .8 and absf(angle_difference(angles[0], angles[2])) > .8
	check(spread_out and behind_taken, "an engaged squad is given slots around the engineer, starting behind")
	var dodger: CharacterBody3D = squad[1]
	dodger.global_position = player.position + Vector3(0, 0, -1.8)
	dodger.set_physics_process(true)
	dodger.evade_chance = 1.0
	dodger.evade_cooldown = 0.0
	player.request_attack()
	await frames(2)
	check(dodger.knockback.length() > 3.0 or dodger.evade_cooldown > 0, "an enemy reads a wind-up aimed at it and steps out")
	await frames(40)
	var lunger: CharacterBody3D = squad[2]
	lunger.global_position = player.position + Vector3(2.8, 0, 0)
	lunger.set_physics_process(true)
	lunger.lunge_cooldown = 0.0
	lunger.melee.cancel()
	var start_gap: float = lunger.global_position.distance_to(player.position)
	await frames(8)
	check(lunger.lunge_cooldown > 0 and lunger.global_position.distance_to(player.position) < start_gap - .5, "an engaged enemy lunges to close the last metres")
	var hurt: CharacterBody3D = squad[0]
	hurt.set_physics_process(true)
	hurt.receive_damage(hurt.max_health - 5, player.position)
	await frames(3)
	check(hurt.regrouped and hurt.regroup_left > 0, "a badly hurt enemy falls back once to regroup")
	# Guidance: the next step always says what to do and, when there is somewhere to go, where.
	await fresh_stage(incident.Stage.INVESTIGATION)
	var investigate: Dictionary = incident.next_step()
	check(investigate.get("tag", "") == "" and "answer Management" in investigate.text, "after the first encounter the call can be answered without backtracking")
	await frames(2)
	var hud: CanvasLayer = scene.get_node("HUD")
	check(hud.guide.visible and "NEXT  ·  E answer Management · detours optional." in hud.guide_text.text and not hud.guide_arrow.visible, "the HUD offers the management call without a false destination arrow")
	await fresh_stage(incident.Stage.BOSS)
	check(incident.next_step().get("tag", "") == "CORRIDOR", "before the boss the next step points through the server corridor")
	await frames(2)
	check(hud.guide.visible and hud.guide_arrow.visible and " m" in hud.guide_text.text, "the vault destination keeps its compass arrow and distance")
	# Every outbreak site, and every spawn slot around it, is reachable on foot.
	var stranded: Array[String] = []
	for entry: Array in incident.SITES:
		incident.wave_site = incident._on_floor(entry[1])
		if not incident.reachable(incident.wave_site):
			stranded.append(entry[0])
		for slot in range(12):
			var spot: Vector3 = incident._near_site(Vector3(cos(slot * 2.4), 0, sin(slot * 2.4)) * 2.2)
			if not incident.reachable(spot):
				stranded.append("%s/%d" % [entry[0], slot])
	check(stranded.is_empty(), "no outbreak site or spawn slot is stranded in a sealed room: %s" % [stranded])
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
	check(first_area != "" and nearest > 10.0 and incident.beacon.visible and incident.encounter_status().contains("nearest"), "the first wave breaks out away from the engineer, marked and roaming")
	var sites: Dictionary = {}
	for foe: CharacterBody3D in incident.alive:
		sites[Vector2i(roundi(foe.home.x / 4.0), roundi(foe.home.z / 4.0))] = true
	check(sites.size() >= 2, "wave members break out at different sites instead of one group")
	for foe: CharacterBody3D in incident.alive.duplicate():
		foe.receive_damage(100000, player.position)
	for wait in range(600):
		if not incident.alive.is_empty():
			break
		await frames(1)
	var second_nearest: float = INF
	for foe: CharacterBody3D in incident.alive:
		second_nearest = minf(second_nearest, Vector2(foe.global_position.x - player.global_position.x, foe.global_position.z - player.global_position.z).length())
	check(incident.wave_area != "" and second_nearest > 10.0, "the next wave also breaks out away from the engineer")
	# Each archetype keeps its rigged presentation, including the accepted skeleton.
	await fresh_stage(incident.Stage.INVESTIGATION)
	var worn: Array = []
	for kind: String in ["record", "blocker", "invite", "scope"]:
		var body: CharacterBody3D = spawn(kind, Vector3(worn.size() * 2.5 - 4, .05, -6))
		var body_kind: String = body.rig.kind if body.rig != null else ""
		worn.append([body_kind, body.get_node("Visual/Body").visible])
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
	var manager: AnimationPlayer = crew.person("Manager").animator
	check(crew.people.size() == crew.CAST.size() and crew.people.size() >= 9 and manager.current_animation.ends_with("Defeat"), "coworkers cower while an enemy is engaged")
	incident.battle_mode.engaged = false
	crew._process(.016)
	check(manager.current_animation.ends_with("Victory") and (crew.person("Manager").line as Label3D).text == "Great teamwork, everyone!", "after the fight the manager takes the credit")
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
	# Slow motion layers: a hit's freeze-frame inside the ultimate hands back to the crawl.
	ElementFx.slow_motion(&"test", .2)
	ElementFx.freeze(incident, .05)
	var deepest: float = Engine.time_scale
	await create_timer(.2, true, false, true).timeout
	check(deepest < .1 and is_equal_approx(Engine.time_scale, .2), "a freeze-frame inside slow motion returns to the slow motion, not full speed")
	ElementFx.slow_motion(&"test", 1.0)
	check(Engine.time_scale == 1.0, "releasing the last slow motion restores normal speed")
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
	# The projector waits through the reveal/grace, then gives a real escape window.
	incident.outbreak_left = 1.0
	incident.sync_action_left = .1
	incident._tick_quick_sync(1.0)
	check(not incident.zones.any(func(zone: Node3D) -> bool: return zone.has_meta("sync_action")), "action items cannot start during the employee transformation")
	incident.outbreak_left = 0.0
	for foe: CharacterBody3D in incident.sync_alive:
		foe.reveal_grace_left = 0.0
		foe.set_physics_process(false)
	incident._tick_quick_sync(.2)
	var action: Node3D = incident.zones.back()
	check(action.has_meta("sync_action") and not action.contains(player), "a floor action item warns before it can hurt or slow the engineer")
	player.position = action.position
	player.invulnerable_left = 0.0
	var before_action: int = player.health
	await frames(125)
	check(player.health < before_action and player.zone_multiplier == .5, "attending the action item drains health and slows the engineer")
	player.position = Vector3(29, .05, -7)
	await frames(2)
	var escaped_health: int = player.health
	await frames(62)
	check(player.health == escaped_health and player.zone_multiplier == 1.0, "running into the annex escapes the action item without further damage")
	player.health = 60
	for foe: CharacterBody3D in incident.sync_alive.duplicate():
		foe.receive_damage(100000, player.position)
	await frames(2)
	check(incident.quick_sync == "done" and player.health == 90 and incident.run.burnout == 20 and incident.room.get_node("QuickSyncDoorA").collision_layer == 0, "surviving the meeting restores health and Burnout and opens the doors")
	check(not incident.zones.any(func(zone: Node3D) -> bool: return zone.has_meta("sync_action")) and "email" in incident.room.get_node("SyncDetail").text, "adjournment cancels floor action items and records the useless meeting minutes")
	player.position = Vector3(22.75, .05, -4)
	await frames(3)
	check(incident.sync_alive.is_empty() and incident.stage == incident.Stage.INVESTIGATION, "Quick Sync never retriggers and does not advance the incident")
	# The rendered stand-up is skippable without losing the transformation or reward.
	await fresh_stage(incident.Stage.INVESTIGATION)
	incident.standup_in_headless = true
	player.position = Vector3(22.75, .05, -8)
	await frames(2)
	check(incident.quick_sync == "standup" and player.narrative_hold and incident.sync_hosts.size() == 3 and incident.sync_alive.is_empty(), "the engineer arrives during a stand-up before anyone transforms")
	incident.standup_scene._next()
	incident.standup_scene._next()
	check("One story point" in incident.standup_scene.caption.text, "the engineer proposes estimating the emergency before the attendees react")
	await key(KEY_TAB)
	check(incident.quick_sync == "active" and not player.narrative_hold and incident.sync_alive.size() == 3 and incident.sync_alive[0].rig.kind == "standup", "skipping the stand-up reveals the unique horned facilitator and restores playable control")
	check(incident.sync_alive[0].bark("spot", 1.0, true) and incident.sync_alive[0].last_bark.begins_with("bark_invite_"), "the stand-up monster retains voiced Meeting Invite reactions")
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(22.75, .05, -8)
	await frames(2)
	scene.reset_encounter()
	await frames(2)
	check(not player.narrative_hold and incident.standup_scene == null and incident.quick_sync == "idle", "restarting during the stand-up clears its camera, actors and control hold")
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(22.75, .05, -8)
	await frames(2)
	while incident.standup_scene.step < 4:
		incident.standup_scene._next()
	incident.standup_scene.left = .001
	await frames(2)
	check(incident.quick_sync == "active" and incident.standup_scene == null and not player.narrative_hold, "the last voiced reaction naturally hands off to transformation without a skip")
	incident.standup_in_headless = false
	await fresh_stage(incident.Stage.INVESTIGATION)
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
	check(idler.awareness == idler.Awareness.UNAWARE and idler.global_position.distance_to(player.position) > 6.0, "an unaware record patrols instead of chasing")
	check(idler.cone.visible, "an unaware enemy shows what it can see")
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
	bored.sight_range = .5
	await frames(60 * 20)
	check(bored.awareness == bored.Awareness.UNAWARE, "an unseen arrival keeps waiting where it broke out, however long it takes")
	var poked: CharacterBody3D = spawn("record", Vector3(-9, .05, -10), false)
	await frames(70)
	poked.receive_damage(5, player.position)
	check(poked.awareness == poked.Awareness.ENGAGED, "hitting an enemy makes it chase")
	await frames(2)
	check(not poked.cone.visible, "a chasing enemy hides its sight cone")
	# Engaged pursuers lose a hidden engineer and search the last known spot.
	await fresh_stage(incident.Stage.INVESTIGATION)
	var seeker: CharacterBody3D = spawn("record", Vector3(-1, .05, -6))
	seeker.move_speed = .4
	player.position = Vector3(22.6, .05, 8)
	seeker.last_seen = Vector3(0, .05, 0)
	await frames(60 * 7)
	check(seeker.awareness == seeker.Awareness.SEARCHING or seeker.awareness == seeker.Awareness.UNAWARE, "losing sight for long enough turns pursuit into a search")
	# Outbreaks: a wave waits inside planted employees and breaks out after a cutscene.
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	player.max_health = 10000
	player.health = 10000
	incident.outbreak_in_headless = true
	incident.presentation.skip()
	await frames(2)
	var planted: Array[Vector3] = []
	for host: Node3D in incident.hosts:
		planted.append(host.position)
	check(planted.size() == 2 and planted.all(func(at: Vector3) -> bool: return Vector2(at.x - player.position.x, at.z - player.position.z).length() >= incident.ROAM_DISTANCE - .5), "the first wave waits inside two employees planted away from the engineer")
	incident.spawn_delay = 0
	await frames(3)
	var odd: Node3D = incident._strangest()
	check(incident.armed and incident.alive.is_empty() and incident.next_step().get("tag", "") == "???", "a due wave waits inside its employees, and NEXT points at the one acting strange")
	await frames(120)
	check(incident.alive.is_empty(), "nobody turns while the engineer keeps their distance")
	var odd_at: Vector3 = odd.global_position
	player.position = incident._on_floor(odd_at + Vector3(1.4, 0, 0))
	await frames(roundi(incident.HOVER_LIMIT * .5 * 60))
	check(incident.alive.is_empty() and odd.line.visible, "hovering earns a polite question first")
	await frames(roundi(incident.HOVER_LIMIT * .5 * 60) + 6)
	var patient: CharacterBody3D = incident.alive[0]
	check(patient.disguised() and not patient.visual.visible and incident.presentation.beat_shot == "outbreak" and player.narrative_hold, "hovering too long sets them off: the camera watches the employee turn")
	check(Vector2(patient.global_position.x - odd_at.x, patient.global_position.z - odd_at.z).length() < 1.0, "the cutscene follows the employee the engineer set off")
	check(Vector2(player.global_position.x - patient.global_position.x, player.global_position.z - patient.global_position.z).length() > 2.0, "close-range reveal stages the engineer back to see the transformation")
	check(not incident.request_attack(patient) and incident.bugs.is_empty(), "nobody swings and no bugs arrive before the burst")
	await frames(roundi(incident.OUTBREAK_BURST * 60) + 12)
	check(incident.alive.size() == 2 and incident.alive.all(func(actor: CharacterBody3D) -> bool: return not actor.disguised() and actor.visual.visible) and incident.bugs.size() == 3, "the burst turns every employee in the wave and releases the swarm")
	check(incident.hosts.size() == 2, "the next wave's employees take their places as this one breaks out")
	var reveal_at: Vector3 = patient.global_position
	await frames(30)
	check(patient.global_position.distance_to(reveal_at) < .08 and patient.reveal_grace_left > 1.9, "the revealed monster stays planted while the camera holds the engineer")
	while incident.presentation.beat_shot == "outbreak":
		await frames(1)
	check(incident.presentation.beat_shot == "" and not player.narrative_hold and scene.get_node("HUD").visible, "the cutscene hands control back")
	var retreat_from: Vector3 = player.global_position
	Input.action_press("move_back")
	await frames(45)
	Input.action_release("move_back")
	check(player.global_position.distance_to(retreat_from) > .5, "the engineer can run during the post-reveal breathing room")
	check(patient.global_position.distance_to(reveal_at) < .08 and incident.bugs.all(func(bug: CharacterBody3D) -> bool: return bug.reveal_grace_left > 0 and not bug.melee.attacking), "the whole wave and swarm wait while the engineer retreats")
	check(not incident.request_attack(patient), "no attack permission during the retreat window")
	await frames(150)
	check(patient.reveal_grace_left == 0 and incident.request_attack(patient), "enemies resume normal combat after the breathing room")
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	incident.spawn_delay = 0
	await frames(3)
	incident._break_out(incident.hosts[0], "timeout")
	await frames(2)
	incident.presentation.skip()
	await frames(2)
	check(not incident.alive[0].disguised() and incident.outbreak_left == 0 and incident.bugs.size() == 3, "TAB skips the cutscene straight to the burst")
	check(incident.alive[0].reveal_grace_left > 1.9 and not incident.request_attack(incident.alive[0]), "skipping the reveal preserves the escape window")
	# Hitting first: no cutscene, the wave turns on the spot and the first blow lands double.
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	incident.spawn_delay = 0
	await frames(3)
	var target_host: Node3D = incident.hosts[1]
	player.position = incident._on_floor(target_host.global_position + Vector3(0, 0, 1.4))
	player.visual.rotation.y = 0.0
	player.request_attack()
	for frame in range(40):
		await frames(1)
		if not incident.alive.is_empty():
			break
	var struck: CharacterBody3D = incident.alive[0] if not incident.alive.is_empty() else null
	check(struck != null and not struck.disguised() and struck.health < struck.max_health and incident.presentation.beat_shot != "outbreak", "hitting a strange coworker turns the wave on the spot and lands the first blow")
	# Ignored too long, they snap anyway.
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	incident.spawn_delay = 0
	await frames(3)
	incident.armed_left = .05
	await frames(8)
	check(not incident.alive.is_empty() and not incident.armed, "ignored long enough, the wave breaks out on its own")
	# Talking to them only ends one way.
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	incident.presentation.skip()
	incident.spawn_delay = 0
	await frames(3)
	var chatty: Node3D = incident.hosts[0]
	player.position = incident._on_floor(chatty.global_position + Vector3(1.0, 0, 0))
	await frames(2)
	incident.talk(incident.talk_target())
	await frames(2)
	incident.dialogue.close()
	await frames(2)
	check(not incident.alive.is_empty() and incident.alive[0].host == chatty, "a conversation with someone the wave is waiting inside ends with them turning")
	incident.outbreak_left = 2.0
	var lurker: CharacterBody3D = incident._spawn_entry(["record", "A1"], incident.alive)
	check(lurker.disguised(), "a member spawned mid-outbreak still wears an employee")
	lurker.receive_damage(5, player.position)
	check(not lurker.disguised() and lurker.awareness == lurker.Awareness.ENGAGED, "hitting an employee early forces the reveal")
	incident.outbreak_in_headless = false
	# The Quick Sync is in session before anyone walks in.
	await fresh_stage(incident.Stage.INVESTIGATION)
	check(incident.sync_hosts.size() == 3 and incident.sync_hosts.all(func(host: Node3D) -> bool: return host.position.x > 18.8), "the Quick Sync attendees stand in Meeting Room 3 during the investigation")
	# Talking to the night shift.
	var morgan: Dictionary = incident.coworkers.person("Manager")
	player.position = Vector3(morgan.body.global_position.x + 1.2, .05, morgan.body.global_position.z)
	await frames(2)
	var someone: Dictionary = incident.talk_target()
	check(someone.get("name", "") == "Manager" and incident.talk_prompt.is_showing(), "E — TALK appears over a coworker in reach")
	incident.talk(someone)
	await frames(2)
	check(incident.dialogue.is_open() and incident.modal_pending() and paused, "talking opens the dialogue and holds the incident")
	var talking_character: Node3D = player.get_node("Visual/Character")
	var model_basis: Basis = talking_character.model.transform.basis
	player.dodging = true
	player.dodge_elapsed = 0.0
	await frames(30)
	check(talking_character.animator.current_animation == "rig/idle_casual" and talking_character.crouch == 0.0 and talking_character.position == Vector3.ZERO, "a paused dodge cannot crouch or roll the engineer during talk")
	check(talking_character.model.transform.basis.is_equal_approx(model_basis), "talk preserves the engineer's model size")
	player.dodging = false
	check(incident.dialogue.speaker.stream != null and incident.dialogue.pace != incident.dialogue.SPEED, "every line is voiced and the text keeps pace with the voice")
	var calm: int = incident.run.burnout
	var standing: Vector3 = morgan.body.global_position
	incident.dialogue.shown = 999.0
	incident.dialogue.choose(0)
	check(incident.dialogue.speaking == "you" and incident.dialogue.speaker.stream != null and incident.dialogue.name_label.text == "YOU", "the engineer speaks the chosen reply out loud")
	await frames(30)
	check(morgan.body.global_position.distance_to(standing) < .01, "the person you are talking to stops walking")
	incident.dialogue.advance()
	incident.dialogue.advance()
	check(incident.dialogue.speaking == "them" and incident.dialogue.node_id == "eta", "after the reply, they answer")
	incident.dialogue.shown = 999.0
	incident.dialogue.choose(0)
	check(incident.run.burnout == calm + 5, "a reply can cost Burnout through the run's own bookkeeping")
	incident.dialogue.advance()
	incident.dialogue.advance()
	incident.dialogue.shown = 999.0
	incident.dialogue.choose(0)
	await frames(2)
	check(not incident.dialogue.is_open() and not incident.modal_pending() and not paused, "leaving the talk resumes play")
	check(not talking_character.conversing, "leaving restores the normal character animation controller")
	incident.talk(incident.talk_target())
	check(incident.dialogue.node_id == "again", "a second visit opens differently")
	incident.dialogue.close()
	await frames(2)
	var planted_talk: Node3D = incident.sync_hosts[0]
	player.position = Vector3(planted_talk.global_position.x - 1.0, .05, planted_talk.global_position.z)
	await frames(2)
	check(incident.talk_target().get("body") == planted_talk, "the employees a wave is waiting inside can be talked to")
	spawn("record", player.position + Vector3(0, 0, 3))
	await frames(4)
	check(incident.talk_target().is_empty() and not incident.talk_prompt.is_showing(), "nobody chats while something is hunting the engineer")
	var silent: Array[String] = []
	var talk_data: Dictionary = preload("res://game/incidents/dialogues.gd").data()
	_dialogue_variations(talk_data)
	for tree: Dictionary in talk_data.trees.values():
		for node: Dictionary in tree.nodes.values():
			for reply: Array in node.replies:
				var dialogues: Script = preload("res://game/incidents/dialogues.gd")
				if dialogues.voiced_reply(reply[0]) and not ResourceLoader.exists(dialogues.audio(dialogues.reply_id(reply[0]))):
					silent.append(reply[0])
	check(silent.is_empty(), "every spoken reply has the engineer's recorded line %s" % [silent])
	# Special moves: a long piercing slash and a radial ultimate.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 6)
	player.camera_rig.rotation.y = 0.0
	await frames(4)
	var first_cut: CharacterBody3D = spawn("record", Vector3(0, .05, 1.0), false)
	var second_cut: CharacterBody3D = spawn("record", Vector3(.6, .05, -4.0), false)
	for foe: CharacterBody3D in [first_cut, second_cut]:
		foe.set_physics_process(false)
	check(player.specials.reply_all(), "C fires Reply All")
	check(player.specials.last_call == "reply_all" and player.specials.voice.stream != null and player.specials.whoosh.stream != null and scene.get_node("HUD").cut_in.visible, "the engineer shouts the move's name over a whoosh, anime style, with a cut-in")
	check(not player.specials.reply_all(), "the wave has a cooldown")
	await frames(50)
	check(first_cut.health < first_cut.max_health and second_cut.health < second_cut.max_health, "the wave pierces a line of enemies 5 and 10 m away")
	check(player.specials.blades.is_empty() and player.specials.focus > 0, "the blade expires at its range, and its hits build FOCUS")
	check(not player.specials.rollback(), "the ultimate waits for a full FOCUS bar")
	player.specials.add_focus(100)
	var behind: CharacterBody3D = spawn("record", Vector3(0, .05, 9.5), false)
	var beyond: CharacterBody3D = spawn("record", Vector3(3, .05, -8.0), false)
	for foe: CharacterBody3D in [behind, beyond]:
		foe.set_physics_process(false)
	await frames(30)
	var blinks: Array[Vector3] = []
	var record_blink: Callable = func(at: Vector3, _target: Vector3, _index: int) -> void: blinks.append(at)
	player.specials.omnislash_step.connect(record_blink)
	var origin: Vector3 = player.global_position
	check(player.specials.rollback() and player.specials.focus == 0 and player.narrative_hold, "V unleashes Force Rollback when FOCUS is full, spending all of it")
	await frames(130)
	player.specials.omnislash_step.disconnect(record_blink)
	var spread: float = 0.0
	for at: Vector3 in blinks:
		spread = maxf(spread, at.distance_to(origin))
	check(blinks.size() == player.specials.OMNI_SLASHES + 1 and spread > 1.0, "the omnislash blinks seven times around its targets, then back")
	check(player.global_position.distance_to(origin) < .1 and not player.narrative_hold and not player.specials.omnislashing(), "the engineer lands back where he started, in control")
	check(player.specials.last_call == "reset_hard", "the ultimate is called twice: on the leap and on the slam")
	check(behind.health < behind.max_health and beyond.health == beyond.max_health, "Force Rollback hits everything around the engineer, nothing beyond its radius")
	# Blame Shift: dash through a line, cutting and blaming everything passed.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 6)
	player.camera_rig.rotation.y = 0.0
	await frames(4)
	var passed: Array[CharacterBody3D] = [spawn("record", Vector3(0, .05, 3.5), false), spawn("record", Vector3(.6, .05, 1.0), false)]
	for foe: CharacterBody3D in passed:
		foe.set_physics_process(false)
	var start_z: float = player.global_position.z
	check(player.specials.blame_shift(), "X dashes")
	check(player.specials.last_call == "blame_shift", "Blame Shift is called out")
	check(not player.specials.blame_shift(), "the dash has a cooldown")
	await frames(4)
	check(passed[0].health < passed[0].max_health and passed[1].health == passed[1].max_health, "the dash cuts the first enemy as it passes, before reaching the second")
	await frames(12)
	check(start_z - player.global_position.z > 5.0 and passed.all(func(foe: CharacterBody3D) -> bool: return foe.health < foe.max_health), "the engineer goes straight through, cutting everything on the way")
	await frames(30)
	check(player.dash_velocity == Vector3.ZERO and player.specials.dash_marked.is_empty(), "the dash ends cleanly on arrival")
	var blamed: CharacterBody3D = passed[0]
	check(blamed.blamed_left > 0, "everyone the dash passes is BLAMED")
	var before_blame: int = blamed.health
	blamed.receive_damage(10, player.position)
	check(before_blame - blamed.health == 13, "a blamed incident takes 30% more from every hit")
	player.specials.dash_cooldown = 0.0
	await frames(40)
	player.request_dodge()
	await frames(2)
	check(player.specials.blame_shift() and not player.dodging, "attacking out of a dodge turns it into the dash slash")
	await frames(60)
	# Circle Back: a whirlwind that hits everything around, several times.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 5)
	await frames(4)
	var ring: Array[CharacterBody3D] = [spawn("record", Vector3(2, .05, 5), true), spawn("record", Vector3(-1.5, .05, 6.5), true)]
	for foe: CharacterBody3D in ring:
		foe.max_health = 1000
		foe.health = 1000
		foe.set_physics_process(false)
	check(player.specials.circle_back(), "Z starts the whirlwind")
	check(player.specials.last_call == "circle_back", "Circle Back is called out")
	check(not player.specials.circle_back(), "the whirlwind has a cooldown")
	await frames(roundi(player.specials.SPIN_TIME * 60) + 10)
	check(ring.all(func(foe: CharacterBody3D) -> bool: return foe.max_health - foe.health >= player.specials.SPIN_DAMAGE * 3), "the whirlwind hits everything around the engineer again and again")
	check(ring.all(func(foe: CharacterBody3D) -> bool: return foe.stagger_left > 1.0), "the last pulse sends survivors to the parking lot")
	# Works On My Machine: a timed counter. A hit in the stance is cancelled and answered.
	await fresh_stage(incident.Stage.INVESTIGATION)
	player.position = Vector3(0, .05, 5)
	await frames(4)
	var heckler: CharacterBody3D = spawn("record", Vector3(0, .05, 3.6), true)
	heckler.set_physics_process(false)
	var steady: int = player.health
	var focus_before: float = player.specials.focus
	check(player.specials.works_on_my_machine() and player.specials.dome.visible and not player.request_attack(), "G raises the localhost stance; no swinging inside it")
	await frames(6)
	check(not player.receive_damage(30, heckler.global_position) and player.health == steady, "a hit inside the stance does nothing")
	check(heckler.health < heckler.max_health and heckler.stagger_left > 0 and player.specials.last_call == "works_on_my_machine" and player.specials.focus >= focus_before + 20, "the attacker takes the blame instead: damaged, staggered, called out, FOCUS +20")
	check(player.specials.counter_cooldown < 1.0, "a clean counter refunds most of the cooldown")
	await frames(70)
	player.invulnerable_left = 0.0
	player.specials.counter_cooldown = 0.0
	check(player.specials.works_on_my_machine(), "the stance comes back up")
	await frames(roundi(player.specials.COUNTER_WINDOW * 60) + 3)
	check(player.specials.counter_recover > 0 and not player.request_attack() and player.specials.counter_cooldown > 2.0, "a whiff leaves a short, open recovery and the full cooldown")
	check(player.receive_damage(5, Vector3(40, 0, 40)) and player.health < steady, "outside the stance, hits land as usual")
	# Physical deaths: blade kills slice humanoids in half, others tumble, chunks spray.
	await fresh_stage(incident.Stage.INVESTIGATION)
	MonsterRig.gore_in_headless = true
	var halved: CharacterBody3D = spawn("record", Vector3(-3, .05, -2), true)
	var rolled: CharacterBody3D = spawn("record", Vector3(3, .05, -2), true)
	var flung: CharacterBody3D = spawn("bug", Vector3(0, .05, -6), true)
	# One left standing, so clearing these does not end the stage (and pause for upgrades).
	var spare: CharacterBody3D = spawn("record", Vector3(-9, .05, -12), false)
	spare.set_physics_process(false)
	await frames(3)
	halved.receive_damage(1000, Vector3(-3, .05, 0))
	rolled.health = 5
	rolled.receive_damage(10, Vector3(3, .05, 0))
	flung.set_meta("kill_style", "slice")
	flung.receive_damage(100, Vector3(0, .05, -4))
	await frames(2)
	check(halved.rig.death_style == "slice" and halved.rig.pieces.size() == 1 and halved.rig.collapsed.size() == 2, "a heavy blade kill slices a humanoid in half: the legs stay, the upper half flies")
	check(rolled.rig.death_style == "tumble" and rolled.rig.model.get_parent() is RigidBody3D, "a light kill launches the whole body tumbling")
	check(flung.rig.death_style == "tumble", "bodies that cannot be cut (flyers, blobs) tumble instead")
	var chunks: int = halved.get_children().filter(func(node: Node) -> bool: return node.has_meta("gib")).size()
	check(chunks >= 6, "data chunks spray from the kill")
	check(get_nodes_in_group("blood").filter(func(node: Node) -> bool: return node is Decal).size() >= 1, "a slice splashes blood on the floor")
	var lifted: float = halved.rig.pieces[0].global_position.y
	await frames(20)
	check(halved.rig.pieces[0].global_position.y > lifted - .2 or halved.rig.pieces[0].linear_velocity.length() > .5, "the severed half is a live physics body")
	await frames(110)
	check(halved.rig.pieces.all(func(body: RigidBody3D) -> bool: return body.freeze), "pieces come to rest before they dissolve")
	check(get_nodes_in_group("blood").filter(func(node: Node) -> bool: return node is Decal).size() >= 2, "the severed half leaves a second pool where it lands")
	scene.reset_encounter()
	await frames(2)
	check(get_nodes_in_group("blood").is_empty(), "restart mops up the blood")
	MonsterRig.gore_in_headless = false
	# Monsters talk: overworked employees who lost their minds, voiced, one at a time.
	await fresh_stage(incident.Stage.INVESTIGATION)
	var talker: CharacterBody3D = spawn("record", Vector3(-3, .05, 0), false)
	var other_talker: CharacterBody3D = spawn("scope", Vector3(3, .05, 0), false)
	for foe: CharacterBody3D in [talker, other_talker]:
		foe.set_physics_process(false)
	talker.next_bark_ms = 0
	check(talker.bark("idle") and talker.bubble.text != "" and talker.mouth.stream != null and talker.last_bark.begins_with("bark_record_idle"), "a monster mutters about its workload, voiced")
	check(not other_talker.bark("attack") and not talker.bark("attack"), "one bark at a time across the floor, and a pause per monster")
	# Earlier combat may have consumed the shared last-words slot less than 650 ms ago.
	# This fixture checks urgent playback, so give it a fresh slot explicitly.
	preload("res://game/enemies/incident.gd").last_words_ms = -650
	check(other_talker.bark("death", 1.0, true) and other_talker.last_bark.begins_with("bark_scope_death"), "a dying monster always gets its last words")
	# Satisfying kills: a stamped death notice, FOCUS, and a streak banner for quick kills.
	await fresh_stage(incident.Stage.INVESTIGATION)
	var stamped: CharacterBody3D = spawn("record", Vector3(-3, .05, 0), true)
	var streaked: CharacterBody3D = spawn("record", Vector3(3, .05, 0), true)
	var holdout: CharacterBody3D = spawn("record", Vector3(-9, .05, -12), false)
	holdout.set_physics_process(false)
	await frames(3)
	var focus_start: float = player.specials.focus
	stamped.receive_damage(1000, player.global_position)
	check(incident.STAMPS.has(stamped.label.text) and player.specials.focus >= focus_start + 6, "a kill stamps the body with a corporate death notice and pays FOCUS")
	streaked.receive_damage(1000, player.global_position)
	check(incident.kill_streak == 2 and scene.get_node("HUD").streak.visible and scene.get_node("HUD").streak_title.text == "DOUBLE MERGE", "two quick kills: DOUBLE MERGE")
	# Finisher kill cam: slow motion from a low side angle, then straight back to play.
	await fresh_stage(incident.Stage.INVESTIGATION)
	incident.presentation.killcam_in_headless = true
	incident.presentation.killcam_ready = 0
	var finished: CharacterBody3D = spawn("record", Vector3(-3, .05, 0), true)
	var second_kill: CharacterBody3D = spawn("record", Vector3(3, .05, 0), true)
	var survivor: CharacterBody3D = spawn("record", Vector3(-9, .05, -12), false)
	survivor.set_physics_process(false)
	await frames(3)
	finished.receive_damage(1000, player.global_position)
	await frames(2)
	check(incident.presentation.beat_shot == "killcam" and incident.presentation.camera.current, "a big finishing blow cuts to the kill cam")
	second_kill.receive_damage(1000, player.global_position)
	check(incident.presentation.beat_shot == "killcam" and incident.presentation.killcam_start > 0, "kill cams never stack")
	# The kill cam runs on real time (it plays through its own slow motion).
	var deadline: int = Time.get_ticks_msec() + 3000
	var hero: Node3D = player.get_node("Visual/Character")
	var swung: bool = false
	var furthest: float = 0.0
	while incident.presentation.beat_shot == "killcam" and Time.get_ticks_msec() < deadline:
		await frames(1)
		if hero.story_pose == hero.Pose.FINISH:
			swung = swung or (hero.right_reach == 1.0 and hero.held == 0.0)
			furthest = maxf(furthest, hero.finish_progress)
	check(swung and furthest > .6, "the finisher swings the Monolith through the kill in slow motion (reached %.2f)" % furthest)
	check(incident.presentation.beat_shot == "" and player.get_node("CameraRig/SpringArm3D/Camera3D").current and scene.get_node("HUD").visible and hero.story_pose == 0, "the kill cam hands straight back to play")
	incident.presentation.killcam_in_headless = false
	scene.reset_encounter()
	await frames(2)
	check(player.specials.focus == 0 and player.specials.wave_cooldown == 0 and player.specials.blades.is_empty() and player.specials.dash_cooldown == 0 and player.specials.spin_left == 0, "restart clears FOCUS, cooldowns and blades")
	await fresh_stage(incident.Stage.INVESTIGATION)
	# Minimap, seating and the corridor invites.
	var sofa: Node3D = incident.room.get_node("Decor/LoungeSofa")
	var rio: Node3D = incident.coworkers.person("Remote").body
	var rio_skeleton: Skeleton3D = rio.find_child("Skeleton3D", true, false)
	var hips: Vector3 = sofa.to_local(rio_skeleton.global_transform * rio_skeleton.get_bone_global_pose(rio_skeleton.find_bone("Hips")).origin)
	check(hips.x > .35 and hips.x < .77 and hips.y > .25 and hips.y < .29 and hips.z > -.24 and hips.z < -.04, "RIO's hips rest above the sofa cushion between its arms and clear of the backrest")
	for side: String in ["L", "R"]:
		var knee: Vector3 = sofa.to_local(rio_skeleton.global_transform * rio_skeleton.get_bone_global_pose(rio_skeleton.find_bone("LowerLeg." + side)).origin)
		var foot: Vector3 = sofa.to_local(rio_skeleton.global_transform * rio_skeleton.get_bone_global_pose(rio_skeleton.find_bone("Foot." + side)).origin)
		check(knee.z > .03 and foot.z > .03, "RIO's %s shin hangs in front of the sofa instead of passing through its base" % side)
	var minimap: Control = scene.get_node("HUD/Minimap")
	check(minimap.floor_mesh != null and minimap.visible, "the minimap draws the walkable floor during play")
	var character: Node3D = player.get_node("Visual/Character")
	character.story_pose = character.Pose.TYPING
	await frames(60)
	check(character.position.distance_to(character.SEATED_OFFSET) < .03, "seated, the engineer sits up on the cushion and off the backrest")
	character.story_pose = 0
	check(incident.room.get_node("CalendarDrift").cards.all(func(card: Node3D) -> bool: return card.position.y > 2.9), "corridor invites drift under the ceiling, above the camera line")
	# Each employee turns into the monster they were planted as, whoever set them off.
	var planted_crew: Array = [incident._make_host("scope", Vector3(0, .05, 9)), incident._make_host("record", Vector3(1, .05, 9))]
	incident.pending = [["record", "A2"], ["scope", "A4"]]
	incident.pending_hosts = planted_crew.duplicate()
	incident._match_hosts()
	check(incident.pending[0][0] == "scope" and incident.pending[1][0] == "record", "the employee set off first becomes their own monster, not the wave's first")
	incident.pending.clear()
	incident.pending_hosts.clear()
	for host: Node3D in planted_crew:
		host.queue_free()
	# Choice cards ignore input while they deal in (a jump or attack click mid-fight).
	await fresh_stage(incident.Stage.INVESTIGATION)
	incident.upgrade_ui.input_guard = .45
	incident._offer_upgrade(incident.Stage.ENCOUNTER_TWO)
	await frames(2)
	incident.upgrade_ui._choose(1)
	check(incident.upgrade_pending and incident.run.choices.is_empty(), "a choice card ignores input the moment it opens")
	await create_timer(.5, true, false, true).timeout
	incident.upgrade_ui._choose(1)
	check(not incident.upgrade_pending and incident.run.choices.size() == 1, "once dealt in, the card takes the choice")
	incident.upgrade_ui.input_guard = 0.0
	# The run's end plays out (finisher, fall) before the report pauses everything.
	await fresh_stage(incident.Stage.INVESTIGATION)
	incident.hold_ending = true
	incident.fail()
	await frames(3)
	check(incident.terminal() and not paused and player.narrative_hold, "the run's end plays out before the report pauses the game")
	await create_timer(incident.ENDING_HOLD + .3, true, false, true).timeout
	check(paused and not player.camera_rig.controls_active, "the report follows once the ending has played")
	incident.hold_ending = false
	# Won: the all-hands plays first (leadership walks in over the night shift); TAB ends
	# it, the report follows, and a restart leaves nothing of it behind.
	await fresh_stage(incident.Stage.BOSS)
	var quiet_nodes: int = scene.find_children("*", "", true, false).size()
	incident.presentation.killcam_in_headless = true
	incident.hold_ending = true
	incident._enter(incident.Stage.RESOLVED)
	await frames(3)
	var party: Node3D = incident.presentation.all_hands
	check(incident.presentation.beat_shot == "all_hands" and is_instance_valid(party) and party.beat == "death" and not paused, "winning opens the finale before the report")
	var hold_on: int = Time.get_ticks_msec() + 25000
	while is_instance_valid(party) and party.beat != "memorial" and Time.get_ticks_msec() < hold_on:
		await frames(1)
	check(is_instance_valid(party) and party.beat == "memorial" and not player.get_node("Visual/Character").overtime_on \
		and incident.room.get_node("LedgerText1").text == "SUCCESS", "the boss comes apart, the ledger reconciles, the overtime burns out, and the dead are remembered")
	party._beat("grief")
	incident.presentation.voice.clear()
	incident.presentation.say("pm_pitch")
	await frames(2)
	incident.presentation._process(.001)
	check(incident.presentation.panel.visible and incident.presentation.caption.text == incident.presentation.voice.subtitle \
		and incident.presentation.voice.lines.pm_pitch.subtitle in incident.presentation.caption.text,
		"finale dialogue captions remain visible after the presentation updates")
	await key(KEY_TAB)
	await create_timer(.7, true, false, true).timeout
	check(not is_instance_valid(party) and paused, "TAB ends the all-hands and the report follows")
	incident.presentation.killcam_in_headless = false
	incident.hold_ending = false
	scene.reset_encounter()
	await frames(3)
	check(scene.find_children("*", "", true, false).size() <= quiet_nodes + 2 and incident.room.get_node("LedgerText1").text != "SUCCESS", "a restart leaves no leadership, cards or reconciled ledger behind")
	# Monday's postmortem: corrective action three fills the call with the five as AI agents,
	# and the meeting leaves nothing behind.
	var before_call: int = scene.find_children("*", "", true, false).size()
	var meeting: Node3D = load("res://game/incidents/postmortem_call.gd").new(incident.presentation)
	incident.presentation.add_child(meeting)
	meeting.start()
	var backfill_step: int = -1
	for index in range(meeting.STEPS.size()):
		if meeting.STEPS[index][0] == "pm_pitch" or meeting.STEPS[index][0] == "pm_objection":
			meeting.step = index - 1
			meeting._next()
			meeting.tick(.1)
			check(meeting.agents_joined == 0 and meeting.tiles.slice(4, 9).all(func(tile: Control) -> bool: return not tile.visible),
				"replacement agents stay hidden during the proposal and the engineer's objection")
		if meeting.STEPS[index][0] == "pm_backfill":
			backfill_step = index
	incident.presentation.voice.clear()
	meeting.step = backfill_step - 1
	meeting._next()
	var joining: int = Time.get_ticks_msec() + 10000
	while meeting.agents_joined < 5 and Time.get_ticks_msec() < joining:
		meeting.tick(1.0 / 60.0)
		await frames(1)
	check(meeting.agents_joined == 5 and meeting.tiles.slice(4, 9).all(func(tile: Control) -> bool: return tile.visible) and "AI" in meeting.doc.text,
		"the postmortem backfills the night shift with five AI agents on the call")
	incident.presentation.voice.clear()
	for index in range(meeting.STEPS.size()):
		if meeting.STEPS[index][1] == "photo":
			meeting.step = index - 1
			meeting._next()
	check(meeting.card.visible and is_equal_approx(Engine.time_scale, .02), "the expanded meeting still captures the leadership photo")
	meeting._next()
	check(not meeting.card.visible and is_equal_approx(Engine.time_scale, 1.0), "the on-call assignment releases the photo freeze")
	meeting.finish()
	await frames(3)
	check(scene.find_children("*", "", true, false).size() == before_call, "the postmortem call leaves nothing behind")
	# The vault, first time: the night shift is already fighting The Variance, falls in
	# front of the engineer, and the real fight starts after; a restart brings them back.
	await fresh_stage(incident.Stage.INVESTIGATION)
	var crew_count: int = scene.find_children("*", "", true, false).size()
	incident.coworkers.cavalry_in_headless = true
	incident.presentation.killcam_in_headless = true
	incident.presentation.boss_seen = false
	incident._enter(incident.Stage.ENCOUNTER_TWO)
	incident._enter(incident.Stage.BOSS)
	await frames(2)
	check(incident.coworkers.cavalry_standing() == 5 and incident.presentation.demon.visible, "the gate opens on the night shift charging The Variance")
	player.position = Vector3(9, .05, -31.0)
	await frames(3)
	check(incident.presentation.beat_shot == "massacre" and not is_instance_valid(incident.boss), "walking into the vault starts the massacre before the fight")
	# The casualty cams run on real time; frames here run faster than that.
	var massacre_deadline: int = Time.get_ticks_msec() + 70000
	var talking_at_once: int = 0
	var crowded: bool = false
	var night_shift: Node = incident.coworkers
	while not is_instance_valid(incident.boss) and Time.get_ticks_msec() < massacre_deadline:
		await frames(1)
		var talking: int = 0
		var prey: Dictionary = night_shift.victim()
		for worker: Dictionary in night_shift.people:
			if worker.charging or worker.dead:
				talking += 1 if worker.line_left > 0.0 else 0
				if worker.charging and not is_same(worker, prey) and not prey.is_empty() and prey.engaged:
					# (It may sail over someone mid-leap; on the ground it keeps to its victim.)
					crowded = crowded or night_shift.landed() and worker.body.global_position.distance_to(incident.presentation.demon.global_position) < 2.5
		talking_at_once = maxi(talking_at_once, talking)
	check(incident.coworkers.cavalry_fallen() == 5 and is_instance_valid(incident.boss) and not incident.presentation.demon.visible, "all five fall, then the real Variance takes over")
	check(talking_at_once == 1, "the night shift take turns: never two of them talking at once")
	check(not crowded, "The Variance takes them one at a time while the rest run laps out of reach")
	var fate: Callable = func(name: String) -> Dictionary: return night_shift.person(name)
	check(fate.call("Manager").body.scale.y < .1 and not fate.call("SRE").pieces.is_empty() and not fate.call("Designer").body.visible \
		and fate.call("Intern").body.find_child("Skeleton3D", true, false).get_bone_pose_scale(fate.call("Intern").body.find_child("Skeleton3D", true, false).find_bone("Abdomen")).x < .01 \
		and fate.call("Director").body.scale.y < .05,
		"each of them goes to their own move: flattened, sliced, popped, paid in exposure down to the legs, shrunk and stepped on")
	var spots: Array[Vector3] = []
	for worker: Dictionary in night_shift.people:
		if worker.dead:
			spots.append(worker.body.global_position * Vector3(1, 0, 1))
	var apart: bool = spots.size() == 5
	for index in range(spots.size()):
		for other in range(index + 1, spots.size()):
			apart = apart and spots[index].distance_to(spots[other]) > 2.5
	check(apart, "each of them dies somewhere else in the vault")
	check(player.get_node("Visual/Character").overtime_on, "watching them die sends the engineer into Unpaid Overtime")
	incident.coworkers.cavalry_in_headless = false
	incident.presentation.killcam_in_headless = false
	scene.reset_encounter()
	await frames(3)
	check(incident.coworkers.cavalry_fallen() == 0 and incident.coworkers.cavalry_standing() == 0 and scene.find_children("*", "", true, false).size() <= crew_count + 2, "a restart brings the night shift back and leaves no gore behind")
	check(not player.get_node("Visual/Character").overtime_on and night_shift.person("Intern").body.position.y < 1.0 and night_shift.person("Manager").body.scale.y > .5, "a restart ends the overtime and puts everyone back on the floor")
	# The fight moveset: every move lands on an engineer who stands in it, and each has a
	# way out (step away, roll through, look away).
	await fresh_stage(incident.Stage.BOSS)
	incident.presentation.boss_seen = true
	await enter_vault()
	incident.spawn_delay = 0
	var boss_deadline: int = Time.get_ticks_msec() + 5000
	while not is_instance_valid(incident.boss) and Time.get_ticks_msec() < boss_deadline:
		await frames(1)
	var move_hurt: Dictionary = {}
	for move: String in ["delayer", "pop", "decommission", "expose", "downsize"]:
		move_hurt[move] = [await move_outcome(incident.boss, move, false), await move_outcome(incident.boss, move, true)]
	check(move_hurt.values().all(func(pair: Array) -> bool: return pair[0] > 0 and pair[1] == 0),
		"each of The Variance's moves hurts if stood in and misses if escaped: %s" % [move_hurt])
	# The killing blow cuts to the duel: the boss lives through it, hidden, then dies
	# sliced at its end, and the finale takes over.
	incident.presentation.killcam_in_headless = true
	var dueling: CharacterBody3D = incident.boss
	dueling.moves.cancel()
	dueling.phase_time = 5.0
	await physics_frame
	await physics_frame
	dueling.receive_damage(dueling.health + 50, player.global_position)
	await frames(2)
	check(incident.presentation.beat_shot == "duel" and dueling.health > 0 and not dueling.visible and incident.presentation.demon.visible,
		"the killing blow cuts to the duel; the real Variance waits, hidden, for it")
	var duel_end: int = Time.get_ticks_msec() + 15000
	while incident.stage != incident.Stage.RESOLVED and Time.get_ticks_msec() < duel_end:
		await frames(1)
	await frames(2)
	check(incident.stage == incident.Stage.RESOLVED and dueling.health <= 0 and dueling.get_meta("kill_style", "") == "slice" \
		and incident.presentation.beat_shot == "all_hands", "the duel ends in the blow that cuts it in half, and the finale begins")
	incident.presentation.skip()
	incident.presentation.killcam_in_headless = false
	await fresh_stage(incident.Stage.BOSS)
	incident.presentation.boss_seen = true
	await enter_vault()
	incident.spawn_delay = 0
	boss_deadline = Time.get_ticks_msec() + 5000
	while not is_instance_valid(incident.boss) and Time.get_ticks_msec() < boss_deadline:
		await frames(1)
	await move_outcome(incident.boss, "downsize", false)
	var shrunk: float = player.visual.scale.x
	scene.reset_encounter()
	await frames(2)
	check(shrunk < .6 and is_equal_approx(player.visual.scale.x, 1.0), "Downsizing shrinks the engineer, and a restart puts him back to size")
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


func _dialogue_variations(talk_data: Dictionary) -> void:
	var dialogues: Script = preload("res://game/incidents/dialogues.gd")
	var box: CanvasLayer = preload("res://game/ui/dialogue_box.gd").new()
	root.add_child(box)
	for name_: String in talk_data.trees:
		var tree: Dictionary = dialogues.tree(name_)
		for node_id: String in tree.nodes:
			var node: Dictionary = tree.nodes[node_id]
			var variants: Array = node.get("text_variants", [])
			if variants.is_empty():
				continue
			dialogues.variation_bags.erase(tree.voice + node_id)
			var previous: String = ""
			var correct: bool = true
			var seen: Array[String] = []
			# Three complete bags cover both exhaustion and refill boundaries.
			for visit in range((variants.size() + 1) * 3):
				if visit % (variants.size() + 1) == 0:
					seen.clear()
				# Fresh tree copies simulate incident retries; target lookups consume nothing.
				for lookup in range(5):
					dialogues.tree(name_)
				box.open(dialogues.tree(name_), Callable())
				if node_id != tree.start:
					box._go(node_id)
				var said: String = box.text_label.text
				var clip: String = tree.voice + node_id
				if said != node.text:
					var index: int = variants.find(said)
					correct = correct and index >= 0
					clip += "_variant_%d" % (index + 1)
				correct = correct and said != previous and not seen.has(said)
				correct = correct and box.speaker.stream == load(dialogues.audio(clip))
				correct = correct and box.tree.nodes[node_id].replies == node.replies
				previous = said
				seen.append(said)
				box.close()
			check(correct, "%s/%s cycles distinct voiced takes across retries with matching captions and unchanged choices" % [name_, node_id])
	box.queue_free()
