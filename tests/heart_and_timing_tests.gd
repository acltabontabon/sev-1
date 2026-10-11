extends "res://tests/skill_impact_tests.gd"
## Actual ultimate/contact + input/lifecycle regressions for the Friday direction pass.


func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	var foe: CharacterBody3D = await fixture(Vector3(0, .05, 3.5))
	var survey: CanvasLayer = incident.rollback_survey
	check(not player.specials.rollback() and not survey.pending, "an unavailable ultimate produces no paperwork")
	player.specials.add_focus(100)
	check(player.specials.rollback(), "a charged rollback starts")
	check(not survey.pending and not survey.active, "the survey does not interrupt the ultimate windup")
	await frames(210)
	check(foe.health < 1000 and survey.active and survey.receipt.visible, "the real completed rollback damages its target then delivers the survey")
	check(survey.rating == 0, "the ultimate cannot award itself satisfaction stars")
	check(not paused and not player.narrative_hold and player.camera_rig.controls_active, "the receipt never steals combat control")
	check(root.get_visible_rect().encloses(survey.receipt.get_global_rect()), "the whole receipt fits the viewport")
	var minimap: Control = scene.get_node("HUD").minimap
	check(not survey.receipt.get_global_rect().intersects(minimap.get_global_rect()), "paperwork leaves the floor minimap clear")
	for node in survey.receipt.find_children("*", "Control", true, false):
		check(node.mouse_filter == Control.MOUSE_FILTER_IGNORE, "receipt child lets combat clicks through: " + str(node.name))
	# Land ordinary attacks after the ultimate. A whiff cannot vote.
	player.position = Vector3(0, .05, 5)
	foe.position = Vector3(0, .05, 3.5)
	player.camera_rig.rotation.y = 0
	player.visual.rotation.y = 0
	await frames(25)
	var health_before: int = foe.health
	check(player.request_attack(), "melee remains available while the survey is up")
	await frames(28)
	check(foe.health < health_before and survey.rating == 1, "an actual subsequent sword contact stamps one star")
	var rating_before: int = survey.rating
	player.visual.rotation.y = PI
	player.camera_rig.rotation.y = PI
	player.request_attack()
	await frames(40)
	check(survey.rating == rating_before, "missing the target cannot fabricate a hit vote")
	# Explicitly exercise a modal gap with the current receipt; no invisible voting.
	incident.dialogue.open({"who": "TEST", "start": "a", "nodes": {"a": {"text": "A quiet moment.", "replies": []}}}, Callable())
	await frames(2)
	check(not survey.receipt.visible, "dialogue hides the survey")
	incident.dialogue.close()
	player.camera_rig.set_capture(true)
	await frames(650)
	check(survey.completed and "Consent assumed" in survey.small_print.text, "ignoring the form yields the rigged consent punchline")
	await frames(250)
	check(not survey.active and not survey.receipt.visible, "paperwork expires without any input")
	foe = await fixture(Vector3(0, .05, 3.5))
	player.specials.add_focus(100)
	player.specials.rollback()
	await frames(210)
	for vote in range(5):
		player.position = Vector3(0, .05, 5)
		foe.position = Vector3(0, .05, 3.5)
		player.camera_rig.rotation.y = 0
		player.visual.rotation.y = 0
		await frames(2)
		check(player.request_attack(), "survey vote swing is ready after recovery")
		await frames(65)
	check(survey.completed and survey.rating == 5 and "enthusiasm" in survey.small_print.text, "five real contacts complete the rigged survey through play")
	incident.fail()
	await frames(2)
	check(not survey.active and not survey.pending, "run failure clears the gag before the report")
	await fixture(Vector3(0, .05, 3.5))
	# All four original replies remain available through actual key input.
	var data: Script = preload("res://game/incidents/dialogues.gd")
	var talk: Dictionary = data.tree("Manager")
	check(talk.nodes.a.replies[1][1] == "good_days" and talk.nodes.a.replies.size() == 4, "the personal branch is discoverable without deleting other choices")
	incident.dialogue.open(talk, Callable())
	incident.dialogue.advance()
	# Headless dialogue normally skips playback. Use a silent PCM fixture for
	# the real playing/stop gate without creating an unserviced Ogg decoder.
	var voice_fixture: AudioStreamWAV = AudioStreamWAV.new()
	voice_fixture.mix_rate = 44100
	var silence: PackedByteArray = PackedByteArray()
	silence.resize(44100)
	voice_fixture.data = silence
	incident.dialogue.speaker.stream = voice_fixture
	incident.dialogue.speaker.play()
	incident.dialogue.choose(0)
	check(incident.dialogue.speaking == "them", "revealing text cannot accidentally cut off a playing punchline")
	incident.dialogue.advance()
	check(not incident.dialogue.speaker.playing, "a second deliberate advance skips the remaining speech")
	await key(KEY_4)
	check(incident.dialogue.speaking == "you" and incident.dialogue.answer_next == "home", "key 4 selects the actual fourth reply")
	incident.dialogue.close()
	incident.dialogue.open(talk, Callable())
	incident.dialogue.advance()
	await key(KEY_2)
	incident.dialogue.advance()
	incident.dialogue.advance()
	check(incident.dialogue.node_id == "good_days", "the second shortcut reaches the living coworker's ordinary life")
	incident.dialogue.advance()
	await key(KEY_2)
	check(data.promises.get(talk.voice, "") == "After this, lunch is on me.", "the ending remembers a promise actually chosen by the player")
	incident.dialogue.close()
	var jo: Dictionary = incident.coworkers.person("Intern")
	player.position = jo.body.position + Vector3(1, .05, 1)
	incident.talk({"body": jo.body, "tree": data.tree("Intern"), "name": "Intern", "standing": true, "animator": jo.animator})
	incident.dialogue._go("good_days")
	await frames(3)
	var camera: Camera3D = incident.presentation.camera
	check(camera.global_position.distance_to(jo.body.global_position + Vector3.UP * 1.5) > 1.8,
		"the personal conversation stays out of Jo's face beside the office wall")
	var angle_before: Vector3 = incident.talk_wide_offset
	incident.dialogue.advance()
	incident.dialogue.choose(0)
	await frames(3)
	check(incident.talk_wide_offset == angle_before, "the personal reply preserves its established camera side")
	incident.dialogue.close()
	scene.reset_encounter()
	await frames(3)
	check(data.promises.is_empty() and not survey.active and not survey.pending, "retry clears personal promises and all survey state")
	scene.queue_free()
	paused = false
	await frames(3)
	print("RESULT: ", failures, " failure(s)")
	quit(0 if failures == 0 else 1)
