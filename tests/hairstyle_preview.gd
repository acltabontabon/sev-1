extends SceneTree
## Every haircut on the body that wears it, front and back, in plain studio light:
## builds/hair_<row>_<front|back>.png. Then the cast in the office: builds/hair_office.png.

const CREW = preload("res://game/incidents/coworkers.gd")
const HAIR = preload("res://game/incidents/hairstyles.gd")
const BODY: Dictionary = {"side_part": "suit_male.fbx", "pompadour": "suit_male.fbx", "bedhead": "casual2_male.fbx",
	"curly": "casual2_male.fbx", "man_bun": "casual3_male.fbx", "horseshoe": "casual3_male.fbx", "shoulder": "casual2_male.fbx",
	"chignon": "suit_female.fbx", "mullet": "worker_male.fbx", "undercut": "casual3_male.fbx", "buzz_beard": "casual3_male.fbx",
	"high_ponytail": "casual_female.fbx", "slick_back": "casual3_male.fbx", "spiky": "casual2_male.fbx", "bob": "casual2_female.fbx",
	"top_knot": "suit_female.fbx", "receding": "suit_male.fbx", "braid": "casual2_female.fbx", "afro": "casual2_male.fbx"}
const COLOURS: Array[Color] = [Color(.2, .12, .08), Color(.45, .36, .2), Color(.06, .05, .05), Color(.62, .44, .2), Color(.86, .5, .64)]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var stage: Node3D = Node3D.new()
	root.add_child(stage)
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(.16, .17, .2)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(.55, .57, .62)
	stage.add_child(environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation = Vector3(-.7, .5, 0)
	sun.shadow_enabled = true
	stage.add_child(sun)
	var camera: Camera3D = Camera3D.new()
	camera.fov = 30
	stage.add_child(camera)
	camera.current = true
	DirAccess.make_dir_recursive_absolute("res://builds")
	var styles: Array[String] = HAIR.STYLES.duplicate()
	var row: int = 0
	while not styles.is_empty():
		var batch: Array[String] = styles.slice(0, 5)
		styles = styles.slice(5)
		var bodies: Array[Node3D] = []
		for index in batch.size():
			var body: Node3D = load(CREW.ROOT + BODY[batch[index]]).instantiate()
			stage.add_child(body)
			body.position = Vector3((index - 2) * 1.5, 0, 0)
			CREW.dress(body, [Color(.3, .4, .55), Color(.15, .15, .2), Color(.78, .58, .44), COLOURS[index % COLOURS.size()]], "office", batch[index])
			var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
			animator.play("CharacterArmature|Idle")
			animator.seek(.4, true)
			animator.pause()
			bodies.append(body)
		for view: Array in [["front", 0.0], ["back", PI], ["side", PI * .5]]:
			for body in bodies:
				body.rotation.y = view[1] + .25
			camera.position = Vector3(0, 2.75, 10.5)
			camera.look_at(Vector3(0, 2.45, 0))
			await _grab("hair_%d_%s" % [row, view[0]])
		for body in bodies:
			body.queue_free()
		row += 1
	# One sheet per view: every row's heads, stacked.
	for view in ["front", "back", "side"]:
		var sheet: Image = Image.create(1200, 270 * row, false, Image.FORMAT_RGBA8)
		for index in range(row):
			var shot: Image = Image.load_from_file("res://builds/hair_%d_%s.png" % [index, view])
			shot.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(shot, Rect2i(200, 290, 1200, 270), Vector2i(0, 270 * index))
		sheet.save_png("res://builds/hair_sheet_%s.png" % view)
	stage.queue_free()
	await process_frame
	quit()


func _grab(name_: String) -> void:
	for index in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png("res://builds/" + name_ + ".png")
	assert(error == OK)
