extends SceneTree
## Rigged engineer graphical probe: a contact sheet of gameplay states for human review.
## sh tools/godot.sh --path . --script tests/rig_preview.gd
## Writes builds/rig_states.png. It does not establish feel, timing quality or fun.
var scene: Node3D
var player: CharacterBody3D
var camera: Camera3D
var tiles: Array[Image] = []
var labels: Array[String] = []
## Focus loss releases mouse capture, which pauses the lab; the probe keeps it running.
var keep_running: bool = false


func _initialize() -> void:
	_run.call_deferred()
	create_timer(200, true).timeout.connect(func() -> void: print("PROBE TIMEOUT"); quit(1))


func _process(_delta: float) -> bool:
	if keep_running and paused:
		paused = false
	return false


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
	await process_frame


func grab(label: String) -> void:
	await process_frame
	RenderingServer.force_draw()
	var image: Image = root.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(640, 360)
	tiles.append(image)
	labels.append(label)
	print("TILE ", tiles.size(), " ", label)


func frame_player(offset: Vector3) -> void:
	camera.position = player.global_position + offset
	camera.look_at(player.global_position + Vector3(0, .95, 0))


func _run() -> void:
	scene = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Enemy")
	enemy.position = Vector3(-2.6, .05, -1.5)
	enemy.set_physics_process(false)
	player.position = Vector3(0, .05, 2)
	camera = Camera3D.new()
	camera.fov = 45
	scene.add_child(camera)
	camera.make_current()
	scene.get_node("HUD").hide()
	player.camera_rig.set_capture(true)
	paused = false
	keep_running = true
	await frames(20)
	player.visual.rotation.y = 0
	frame_player(Vector3(2.2, 1.4, -2.6))
	await frames(20)
	if "--clips" in OS.get_cmdline_user_args():
		var view: Node3D = player.get_node("Visual/Character")
		view.weapon.visible = false
		for entry: Array in [["fold_arms", .5], ["phone", .5], ["talking", .4], ["sitting_talking", .4], ["fixing", .5], ["zombie_walk", .3], ["zombie_idle", .5], ["zombie_scratch", .4], ["no", .5], ["yes", .5], ["sword_a", .4], ["hit_knockback", .3]]:
			view.preview_clip = entry[0]
			view.preview_at = entry[1]
			await frames(4)
			await grab(entry[0])
		var clips_sheet: Image = Image.create(640 * 3, 360 * 4, false, Image.FORMAT_RGBA8)
		for index in range(tiles.size()):
			clips_sheet.blit_rect(tiles[index], Rect2i(0, 0, 640, 360), Vector2i(640 * (index % 3), 360 * (index / 3)))
		clips_sheet.save_png("res://builds/ual_sheet.png")
		print("SHEET clips")
		quit()
		return
	await grab("idle")
	Input.action_press("move_forward")
	await frames(30)
	frame_player(Vector3(2.8, 1.3, -1.2))
	await grab("run")
	Input.action_release("move_forward")
	await frames(30)
	player.position = Vector3(0, .05, 2)
	player.visual.rotation.y = 0
	for step in range(3):
		frame_player(Vector3(2.3, 1.6, -2.7))
		player.request_attack()
		var melee: Node3D = player.melee
		var guard: int = 0
		while melee.attacking and melee.elapsed < melee.windup * .85 and guard < 120:
			guard += 1
			await physics_frame
		await grab("step %d windup" % step)
		while melee.attacking and melee.elapsed < melee.windup + melee.active_time * .5:
			await physics_frame
		await grab("step %d strike" % step)
		while melee.attacking and melee.elapsed < melee.windup + melee.active_time + melee.recovery * .3:
			await physics_frame
		await grab("step %d follow" % step)
		while melee.attacking:
			await physics_frame
		if step < 2:
			await frames(2)
	await frames(40)
	player.position = Vector3(0, .05, 2)
	player.visual.rotation.y = 0
	await frames(5)
	frame_player(Vector3(3.2, 1.4, -1.0))
	player.request_dodge()
	await frames(5)
	await grab("dodge")
	await frames(60)
	frame_player(Vector3(2.4, 1.5, -2.4))
	player.invulnerable_left = 0
	player.receive_damage(5, Vector3(0, 0, -2))
	await frames(4)
	await grab("hurt")
	await frames(60)
	player.invulnerable_left = 0
	keep_running = false
	player.receive_damage(100000, Vector3(0, 0, -2))
	await grab("defeat")
	print("composing")
	player.camera_rig.set_capture(false)
	var sheet: Image = Image.create(640 * 3, 360 * ceili(tiles.size() / 3.0), false, Image.FORMAT_RGBA8)
	for index in range(tiles.size()):
		sheet.blit_rect(tiles[index], Rect2i(0, 0, 640, 360), Vector2i(640 * (index % 3), 360 * (index / 3)))
	sheet.save_png("res://builds/rig_states.png")
	print("SHEET ", labels)
	quit()
