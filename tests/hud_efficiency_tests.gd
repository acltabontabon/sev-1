extends "res://tests/incident_tests.gd"
## Stable HUD refreshes must not invalidate typography or reshape unchanged labels.

func _run() -> void:
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	player.camera_rig.set_capture(true)
	incident.presentation.skip_unlocked = true
	incident.presentation.skip()
	await frames(3)
	var hud: CanvasLayer = scene.get_node("HUD")
	incident.run.burnout = 75
	incident.challenge_result = "Active"
	incident.challenge_left = 123.0
	hud.refresh()
	var prompt: Label = hud.get_node("CapturePrompt/Panel/Padding/VBox/Text")
	var burnout: Label = hud.find_child("Burnout", true, false)
	var changes: Array[int] = [0]
	prompt.theme_changed.connect(func() -> void: changes[0] += 1)
	hud.focus_value.theme_changed.connect(func() -> void: changes[0] += 1)
	(hud.burnout_bar.get_theme_stylebox("fill") as StyleBoxFlat).changed.connect(func() -> void: changes[0] += 1)
	for index in range(120):
		hud.refresh()
	check(changes[0] == 0, "120 unchanged HUD refreshes cause no theme/style invalidations")
	check("Committed ETA 2:03" in burnout.text, "complete Burnout text preserves the management countdown")
	player.specials.focus = 100.0
	player.health = 42
	incident.challenge_left = 61.0
	hud.refresh()
	check(hud.focus_value.text == "V READY" and hud.health_value.text.begins_with("42 /"), "health and ultimate readiness still update immediately")
	check("Committed ETA 1:01" in burnout.text, "changing the countdown updates the final label")
	check(changes[0] > 0, "ultimate readiness changes its color when needed")
	print("RESULT: ", failures, " failure(s)")
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)
