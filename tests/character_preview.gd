extends SceneTree
## Render selected poses at a fixed physics phase. Screenshots are not a feel test.
var scene: Node3D
var player: CharacterBody3D
var enemy: CharacterBody3D
var camera: Camera3D

func _initialize() -> void:
	_run.call_deferred()

func shot(name_: String) -> void:
	paused = true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/character_" + name_ + ".png")

func ticks(count: int) -> void:
	paused = false
	for index in range(count):
		await physics_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds")
	scene = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	enemy = scene.get_node("Enemy")
	player.camera_rig.capture_changed.disconnect(scene._on_capture_changed)
	player.camera_rig.set_process_unhandled_input(false)
	player.camera_rig.controls_active = true
	player.hitstop_enabled = false
	player.position = Vector3(-.7, .05, 4)
	enemy.position = Vector3(1.1, .05, 4)
	enemy.target = null
	enemy.visual.rotation.y = 0
	enemy.label.hide()
	camera = Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(-3, 2.3, -.5)
	camera.look_at(Vector3(0, 1, 4))
	camera.fov = 48
	camera.make_current()
	scene.get_node("HUD").hide()
	await ticks(10)
	await shot("identity")
	player.request_attack()
	await ticks(5)
	await shot("anticipation")
	await ticks(5)
	await shot("strike")
	player.melee.cancel()
	player.hitstop_left = 0
	enemy.hide()
	player.request_dodge()
	await ticks(6)
	camera.position = player.position + Vector3(-3, 2, -3)
	camera.look_at(player.position + Vector3.UP)
	await shot("dodge")
	await ticks(40)
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await ticks(8)
	camera.position = player.position + Vector3(-3, 2, -3)
	camera.look_at(player.position + Vector3.UP)
	await shot("run")
	Input.action_release("move_forward")
	Input.action_release("sprint")
	await ticks(12)
	player.invulnerable_left = 0
	player.receive_damage(100, enemy.position)
	await shot("defeat")
	scene.queue_free()
	paused = false
	await create_timer(.25).timeout
	quit()
