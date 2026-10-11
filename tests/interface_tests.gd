extends "res://tests/incident_tests.gd"
## Milestone 12 interface: chat cards, HUD bars and the choice cards. Outcomes only;
## typography, timing and whether the jokes land need human review.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	var story: CanvasLayer = incident.presentation
	var feed: Control = story.feed
	var hud: CanvasLayer = scene.get_node("HUD")
	player.camera_rig.set_capture(true)
	player.max_health = 10000
	player.health = 10000
	await frames(60)
	check(story.seen.has("doc_office") and feed.cards.is_empty(), "the cinematic opening speaks in subtitles, never chat cards")
	story.skip_unlocked = true
	story.skip()
	await frames(4)
	check(hud.banner.visible and "SEV-1 DECLARED" in hud.banner_text.text, "declaring the incident raises the full-width alert banner")
	check(incident.timeline.size() == 1 and "declared" in incident.timeline[0][1], "the postmortem timeline records the declaration")
	check(story.sequence == ["status_except"] and incident.voice.current_line == "status_ok", "the status page claim and its correction are queued as one joke")
	check(feed.cards.size() == 1 and "All systems operational." in feed.cards[0].find_child("Message", true, false).text, "a spoken corporate line arrives as a radio card")
	check(feed.cards[0].find_child("Purpose", true, false).text == "RADIO · NO REPLY NEEDED", "radio speech clearly distinguishes itself from interactive dialogue")
	await frames(150)
	check(feed.cards.size() == 1 and "Except three." in feed.cards[0].find_child("Message", true, false).text, "the correction lands as its own card after the claim")
	# Investigation has no arrivals, so only the lines under test speak.
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	await frames(2)
	incident.voice.clear()
	incident.voice.request("debt")
	await frames(3)
	check(feed.cards[0].find_child("Message", true, false).text.begins_with("“") and not feed.cards[0] is PanelContainer, "the engineer's lines read as said out loud, not typed")
	for id: String in ["investigate", "visibility", "rca"]:
		incident.voice.clear()
		incident.voice.request(id)
		await frames(3)
	check(feed.cards.size() == feed.LIMIT, "no more than %d cards stack beside combat" % feed.LIMIT)
	incident.voice.clear()
	await frames(60 * 9)
	check(feed.cards.is_empty(), "cards leave once their line has been read")
	# HUD reflects real state.
	player.health = 40
	incident.run.burnout = 75
	await frames(3)
	incident.run.debt = 45
	await frames(2)
	check(hud.debt_bar.value == 45 and "FRAGILE" in hud.debt_value.text, "the debt bar tracks Technical Debt and its band")
	check(hud.health_bar.value == 40 and hud.burnout_bar.value == 75 and "OVERLOADED" in hud.burnout_value.text, "vitals bars track health and Burnout")
	check("INC-001  ·  UPDATE REQUESTED  ·" in scene.get_node("HUD/Margin/VBox/Title").text, "the ticket header names the requested management update")
	check(not hud.boss_box.visible, "no boss bar without a boss")
	# Special moves read as icons with cooldowns, not a line of text.
	player.specials.wave_cooldown = 0.0
	await frames(2)
	player.specials.wave_cooldown = 3.0
	await frames(2)
	check(hud.skill_bar.visible and hud.skill_bar.remaining(0) > 2.5 and not hud.skill_bar.ready_now(0) and hud.skill_bar.peaks[0] >= 2.9, "the skill bar shows a move cooling down")
	player.specials.wave_cooldown = 0.0
	await frames(2)
	check(hud.skill_bar.ready_now(0) and hud.skill_bar.flashes[0] > 0.0, "a move coming back flashes its icon")
	check(not "REPLY ALL" in scene.get_node("HUD/Controls").text and not "·" in hud.focus_value.text, "move keys and cooldowns are no longer spelled out in text")
	player.health = 10000
	incident._cleanup()
	for next in [incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		incident._enter(next)
	story.skip()
	await frames(60 * 4)
	check(not hud.boss_box.visible and story.title.visible, "the boss bar waits for the arrival title to finish")
	await frames(60 * 6)
	check(hud.boss_box.visible and hud.boss_bar.max_value == incident.boss_health, "the boss bar appears with The Variance")
	# Choice cards keep keyboard order across the horizontal layout.
	scene.reset_encounter()
	player.camera_rig.set_capture(true)
	story.skip()
	incident._offer_upgrade(incident.Stage.INVESTIGATION)
	await frames(3)
	var buttons: Array[Button] = incident.upgrade_ui.buttons
	check(buttons[0].has_focus() and flavor_ok(buttons), "power-ups open focused with plain combat descriptions")
	check(incident.upgrade_ui.heading.text == "Choose a power-up" and "run ends" in incident.upgrade_ui.subhead.text, "power-up purpose and duration are explicit")
	check("More damage" in incident.upgrade_ui.summary(0) and "+35%" in incident.upgrade_ui.summary(0), "power-up summary ties the benefit to its actual value")
	check(feed.LIMIT == 1, "only one radio caption may occupy combat space")
	await key(KEY_RIGHT)
	check(buttons[1].has_focus(), "right arrow walks to the next change request")
	for button in buttons:
		check(root.get_visible_rect().encloses(button.get_global_rect()), "change request card fits the viewport")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)


func flavor_ok(buttons: Array[Button]) -> bool:
	for index in range(3):
		if not incident.upgrade_ui.FLAVOR[index] in incident.upgrade_ui.summary(index):
			return false
	return true
