extends Node3D
## Monday, 9:00 AM: the blameless postmortem, the epilogue of Incident 001 (run by
## all_hands.gd after the night). The engineer stands alone in the Quick Sync room;
## everyone else dials in on its wall screen (a live 2D call rendered into the room):
## the Chief Synergy Officer joining from Cabo, the VP with her camera off, the Head of
## People on a Peloton, the AI note-taker, and his own self-view. The postmortem types
## itself out: root cause, an engineer was present; impact, one cent and five "resource
## attrition events"; what went well, leadership. Corrective action three backfills the
## night shift with AI after the VP pitches it, the engineer objects, and the note-taker
## misrecords consent. Five agents with their names join; JO.ai greets the call. A
## screenshot for LinkedIn (his tile blacked out), on call this weekend, meeting ended.
## Presentation only, on real time.

const ROOT: String = "res://assets/characters/quaternius/"
const MOTION: AnimationLibrary = preload("res://game/player/engineer_animations.res")
const CREW = preload("res://game/incidents/coworkers.gd")
const SCREEN_AT: Vector3 = Vector3(26.88, 2.0, -8.75)
const SCREEN_SIZE: Vector2 = Vector2(3.0, 1.6875)
const VIEW: Vector2i = Vector2i(1280, 720)
const STANDS_AT: Vector3 = Vector3(20.55, .05, -8.75)
## Where leadership "is" (sets far off the map, filmed for their tiles).
const CABO: Vector3 = Vector3(300, 150, 0)
const PELOTON: Vector3 = Vector3(312, 150, 0)
## The call, tile by tile in grid order: [name, kind, status]. kind: "ceo", "people"
## (filmed), "off" (camera off), "notes" (the AI note-taker), "agent" (joins later),
## "you" (his self-view).
const TILES: Array = [
	["Brent Fairweather (CSO) · Cabo", "ceo", ""],
	["VP of Alignment", "off", "camera off · muted"],
	["Head of People · Peloton", "people", ""],
	["ENGI-NOTES AI", "notes", "taking notes"],
	["MORGAN.ai", "agent", "Escalating to another AI"],
	["NADIA.ai", "agent", "On call forever · no pager"],
	["JUN.ai", "agent", "Six fingers. 400 logos."],
	["JO.ai", "agent", "Alive per service agreement"],
	["VAL.ai", "agent", "2,000 slides. Zero answers."],
	["You", "you", ""]]
const DOC: Array[String] = [
	"BLAMELESS POSTMORTEM — INC-001\nStatus: blameless ✓\n\n",
	"ROOT CAUSE: Attempted to go home.\nCONTRIBUTING FACTOR: Home is a competitor.\n\n",
	"IMPACT: $0.01 (recovered) · 5 resource attrition events\n\n",
	"WHAT WENT WELL: Leadership.\n",
	"WHAT WENT WRONG: The engineer survived.\n\n",
	"CORRECTIVE ACTIONS\n 1. Record objection as enthusiastic consent\n 2. Engineer to own all AI mistakes\n",
	" 3. Replace the night shift with AI (5 agents)\n\nOWNER: You    DUE: Yesterday"]
## The meeting, step by step: [line ("" for none), shot, how much of DOC is out, the
## least it holds on screen].
const STEPS: Array = [
	["", "glass", 1, 2.4],
	["allhands_ceo", "tile:0", 1, 1.0],
	["pm_root", "screen", 2, 1.0],
	["pm_impact", "screen", 3, 1.0],
	["allhands_vp", "screen", 4, 1.0],
	["allhands_people", "tile:2", 5, 1.0],
	["pm_pitch", "screen", 5, 1.0],
	["pm_objection", "him_close", 5, 1.2],
	["pm_consent", "tile:3", 6, 1.0],
	["pm_backfill", "screen", 7, 1.0],
	["pm_agent", "tile:7", 7, 1.0],
	["", "him_close", 7, 2.4],
	["allhands_photo", "screen", 7, 1.0],
	["", "photo", 7, 4.0],
	["allhands_oncall", "him", 7, 1.0],
	["allhands_engineer", "him_close", 7, 1.2]]
const POST: String = "Humbled to share that our leadership team ran a flawless blameless postmortem today. Root cause identified, actions owned, and our night shift is now fully AI-powered.\n\nProud of what we built. Grateful for our people (5 fewer).\n\n#leadership #AI #blameless #grateful"

var story: Node
var incident: Node
var player: CharacterBody3D
var step: int = -1
var step_at: float = 0.0
var clock: float = 0.0
var done: bool = false
var nodes: Array[Node] = []
var screen: SubViewport
var doc: Label
var doc_shown: float = 0.0
var tiles: Array[Control] = []
var agents_joined: int = 0
var notes_bars: Array[ColorRect] = []
var ended: Control
var card: PanelContainer
var photo: TextureRect


func _init(presentation: Node) -> void:
	story = presentation
	incident = presentation.incident
	player = incident.player
	name = "Postmortem"


func start() -> void:
	player.global_position = STANDS_AT
	player.visual.rotation.y = -PI * .5
	_build_screen()
	_build_sets()
	_build_post()
	_next()


func _next() -> void:
	step += 1
	step_at = clock
	if step >= STEPS.size():
		return
	var entry: Array = STEPS[step]
	if not str(entry[0]).is_empty():
		story.say(entry[0])
	match str(entry[1]):
		"photo":
			_screenshot()
		"him":
			ElementFx.slow_motion(&"photo", 1.0)
			story.crew_freeze.hide()
			card.hide()
		"pullout":
			ended.show()


## Returns false when the meeting is over.
func tick(real: float) -> bool:
	if done or step >= STEPS.size():
		return false
	clock += real
	var t: float = clock - step_at
	var entry: Array = STEPS[step]
	var quiet: bool = story.voice.current_line.is_empty() and story.voice.queue.is_empty()
	# The document types itself out as the AI reads it.
	var target: int = 0
	for index in range(mini(entry[2], DOC.size())):
		target += DOC[index].length()
	doc_shown = minf(float(target), doc_shown + real * 55.0)
	doc.visible_characters = int(doc_shown)
	# The agents join one by one while the AI announces them.
	if str(entry[0]) == "pm_backfill" and agents_joined < 5 and t > .9 + agents_joined * .75:
		tiles[4 + agents_joined].show()
		agents_joined += 1
		story.sting(preload("res://assets/audio/sfx/chat_ping_soft.ogg"), -6)
	for index in range(notes_bars.size()):
		notes_bars[index].size.y = 10.0 + 34.0 * absf(sin(clock * (3.0 + index * .7) + index))
		notes_bars[index].position.y = 60.0 - notes_bars[index].size.y * .5
	_shot(entry[1], t)
	if t >= entry[3] and (str(entry[0]).is_empty() or quiet):
		_next()
		if step >= STEPS.size():
			return false
	story.camera.make_current()
	return true


func finish() -> void:
	if done:
		return
	done = true
	ElementFx.slow_motion(&"photo", 1.0)
	story.crew_freeze.hide()
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	nodes.clear()
	queue_free()


func _exit_tree() -> void:
	finish()


func _shot(kind: String, t: float) -> void:
	var camera: Camera3D = story.camera
	var face: Vector3 = STANDS_AT + Vector3.UP * 1.45
	if kind.begins_with("tile:"):
		var at: Vector3 = _tile_world(int(kind.get_slice(":", 1)))
		camera.global_position = Vector3(SCREEN_AT.x - 1.0 + t * .03, at.y, at.z)
		camera.look_at(at)
		camera.fov = 26.0
		return
	match kind:
		"glass":
			# Through the glass from the corridor: one man, one table, one enormous screen.
			camera.global_position = Vector3(17.2, 1.75, -13.4) + Vector3(.2, 0, .3) * minf(1.0, t / 4.0)
			camera.look_at(Vector3(23.0, 1.5, -8.6))
			camera.fov = 52.0
		"screen", "photo":
			camera.global_position = Vector3(24.4 + minf(t, 6.0) * .03, 2.0, -8.75)
			camera.look_at(SCREEN_AT)
			camera.fov = 46.0
		"him":
			camera.global_position = Vector3(25.4, 1.75, -8.1)
			camera.look_at(face)
			camera.fov = 30.0
		"him_close":
			camera.global_position = Vector3(21.75, 1.55, -8.35) + Vector3(-.05, 0, 0) * minf(1.0, t / 3.0)
			camera.look_at(face)
			camera.fov = 36.0
		"pullout":
			# Back out through the glass: him, the screen, "Meeting ended".
			var back: float = smoothstep(0.0, 4.5, t)
			camera.global_position = Vector3(21.2, 1.6, -7.2).lerp(Vector3(16.6, 2.0, -7.6), back)
			camera.look_at(Vector3(23.5, 1.6, -8.75))
			camera.fov = 50.0


## Where a tile sits on the wall screen, in the world.
func _tile_world(index: int) -> Vector3:
	var tile: Control = tiles[index]
	var centre: Vector2 = tile.position + tile.size * .5
	var u: float = centre.x / VIEW.x
	var v: float = centre.y / VIEW.y
	return Vector3(SCREEN_AT.x, SCREEN_AT.y + (.5 - v) * SCREEN_SIZE.y, SCREEN_AT.z + (u - .5) * SCREEN_SIZE.x)


## The call: a 2D layout rendered into the room's wall screen.
func _build_screen() -> void:
	screen = SubViewport.new()
	screen.size = VIEW
	screen.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	screen.transparent_bg = false
	add_child(screen)
	var ui: Control = Control.new()
	ui.size = VIEW
	screen.add_child(ui)
	var back: ColorRect = ColorRect.new()
	back.color = Color(.08, .09, .11)
	back.size = VIEW
	ui.add_child(back)
	var bar: Label = _label("SYNERGEX MEET   ·   MONDAY 9:00 AM   ·   Blameless Postmortem — INC-001   ·   ● REC   ·   47 participants", 20, Color(.8, .82, .86))
	bar.position = Vector2(24, 16)
	ui.add_child(bar)
	var sheet: ColorRect = ColorRect.new()
	sheet.color = Color(.97, .97, .96)
	sheet.position = Vector2(24, 56)
	sheet.size = Vector2(760, 640)
	ui.add_child(sheet)
	doc = _label("".join(DOC), 22, Color(.1, .1, .12))
	doc.position = Vector2(48, 76)
	doc.size = Vector2(712, 600)
	doc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doc.visible_characters = 0
	ui.add_child(doc)
	for index in range(TILES.size()):
		var entry: Array = TILES[index]
		var tile: Control = Control.new()
		tile.position = Vector2(808 + (index % 2) * 228, 56 + floori(index / 2.0) * 128)
		tile.size = Vector2(216, 120)
		tile.clip_contents = true
		ui.add_child(tile)
		tiles.append(tile)
		var fill: ColorRect = ColorRect.new()
		fill.size = tile.size
		fill.color = Color(.16, .17, .2)
		tile.add_child(fill)
		match entry[1]:
			"ceo", "people", "you":
				var feed: TextureRect = TextureRect.new()
				feed.size = tile.size
				feed.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				feed.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				feed.texture = _feed(entry[1])
				tile.add_child(feed)
			"off":
				var initials: Label = _label("VA", 40, Color(.9, .9, .95))
				initials.position = Vector2(80, 26)
				tile.add_child(initials)
			"notes":
				for bar_index in range(5):
					var level: ColorRect = ColorRect.new()
					level.color = Color(.4, .85, 1)
					level.position = Vector2(70 + bar_index * 16, 50)
					level.size = Vector2(10, 20)
					tile.add_child(level)
					notes_bars.append(level)
			"agent":
				fill.color = Color(.24, .16, .42)
				var glow: ColorRect = ColorRect.new()
				glow.color = Color(.45, .7, 1, .9)
				glow.position = Vector2(84, 18)
				glow.size = Vector2(48, 48)
				tile.add_child(glow)
				var letter: Label = _label(str(entry[0]).substr(0, 1), 34, Color(.08, .06, .16))
				letter.position = Vector2(98, 20)
				tile.add_child(letter)
				tile.hide()
		if not str(entry[2]).is_empty():
			var status: Label = _label(entry[2], 12, Color(.75, .78, .85))
			status.position = Vector2(8, 74)
			tile.add_child(status)
		var tag: ColorRect = ColorRect.new()
		tag.color = Color(0, 0, 0, .55)
		tag.position = Vector2(0, 94)
		tag.size = Vector2(216, 26)
		tile.add_child(tag)
		var who: Label = _label(entry[0], 13, Color(.95, .95, .97))
		who.position = Vector2(8, 98)
		tile.add_child(who)
	ended = Control.new()
	ended.size = VIEW
	ended.hide()
	ui.add_child(ended)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(.05, .05, .07, .96)
	dim.size = VIEW
	ended.add_child(dim)
	var over: Label = _label("Meeting ended.\n\nNext: Quick Sync (15 min) — recurring daily, forever\nRate this meeting:  ★ ☆ ☆ ☆ ☆", 34, Color(.9, .9, .94))
	over.position = Vector2(160, 230)
	ended.add_child(over)
	# The wall screen itself.
	var panel: MeshInstance3D = MeshInstance3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = SCREEN_SIZE
	panel.mesh = quad
	var glass: StandardMaterial3D = StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.albedo_texture = screen.get_texture()
	panel.material_override = glass
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	incident.add_child(panel)
	panel.global_position = SCREEN_AT + Vector3(-.03, 0, 0)
	panel.rotation.y = -PI * .5
	nodes.append(panel)
	var spill: OmniLight3D = OmniLight3D.new()
	spill.light_color = Color(.75, .85, 1)
	spill.light_energy = 1.4
	spill.omni_range = 6.0
	incident.add_child(spill)
	spill.global_position = SCREEN_AT + Vector3(-1.2, 0, 0)
	nodes.append(spill)


## A live feed for a tile: a small camera on a set (or on him, for the self-view).
func _feed(kind: String) -> Texture2D:
	var view: SubViewport = SubViewport.new()
	view.size = Vector2i(320, 180)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var lens: Camera3D = Camera3D.new()
	lens.fov = 40.0
	view.add_child(lens)
	match kind:
		"ceo":
			lens.global_position = CABO + Vector3(0, 1.0, 1.7)
			lens.look_at(CABO + Vector3(0, .85, 0))
		"people":
			lens.global_position = PELOTON + Vector3(0, 1.2, 1.7)
			lens.look_at(PELOTON + Vector3(0, 1.05, 0))
		"you":
			lens.global_position = SCREEN_AT + Vector3(-.2, .9, 0)
			lens.look_at(STANDS_AT + Vector3.UP * 1.3)
			lens.fov = 30.0
	return view.get_texture()


## Cabo (a sunset, a lounger's worth of slouch) and a Peloton studio, far off the map.
func _build_sets() -> void:
	var sunset: GradientTexture2D = GradientTexture2D.new()
	var sky: Gradient = Gradient.new()
	sky.set_color(0, Color(1, .55, .25))
	sky.set_color(1, Color(.45, .2, .55))
	sunset.gradient = sky
	sunset.fill_from = Vector2(0, 1)
	sunset.fill_to = Vector2(0, 0)
	_backdrop(CABO, null, sunset, "CABO")
	var sun: MeshInstance3D = MeshInstance3D.new()
	var disc: SphereMesh = SphereMesh.new()
	disc.radius = .3
	disc.height = .6
	sun.mesh = disc
	var bright: StandardMaterial3D = StandardMaterial3D.new()
	bright.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bright.albedo_color = Color(1, .9, .45)
	sun.material_override = bright
	incident.add_child(sun)
	sun.global_position = CABO + Vector3(.75, 1.25, -1.1)
	nodes.append(sun)
	_person(CABO, "suit_male.fbx", [Color(.1, .65, .6), Color(.95, .9, .8), Color(.86, .66, .52), Color(.55, .5, .45)], "ual/sitting_talking")
	_backdrop(PELOTON, Color(.18, .19, .22), null, "PELOTON  ·  LIVE  ·  32 MPH")
	_person(PELOTON, "casual2_female.fbx", [Color(.95, .3, .55), Color(.12, .12, .15), Color(.78, .58, .45), Color(.6, .35, .2)], "ual/jog")


func _backdrop(at: Vector3, colour: Variant, texture: Texture2D, caption: String) -> void:
	var wall: MeshInstance3D = MeshInstance3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(5, 3.4)
	wall.mesh = quad
	var paint: StandardMaterial3D = StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if texture != null:
		paint.albedo_texture = texture
	else:
		paint.albedo_color = colour
	wall.material_override = paint
	incident.add_child(wall)
	wall.global_position = at + Vector3(0, 1.2, -1.3)
	nodes.append(wall)
	var words: Label3D = Label3D.new()
	words.text = caption
	words.font = preload("res://assets/fonts/barlow_condensed_bold.ttf")
	words.font_size = 64
	words.pixel_size = .006
	words.modulate = Color(1, 1, 1, .85)
	words.outline_size = 0
	incident.add_child(words)
	words.global_position = at + Vector3(-.7, 1.7, -1.25)
	nodes.append(words)
	var key: OmniLight3D = OmniLight3D.new()
	key.light_energy = 2.4
	key.omni_range = 5.0
	incident.add_child(key)
	key.global_position = at + Vector3(.4, 1.8, 1.4)
	nodes.append(key)


func _person(at: Vector3, model: String, palette: Array, clip: String) -> void:
	var body: Node3D = load(ROOT + model).instantiate()
	incident.add_child(body)
	body.scale = Vector3.ONE * .62
	CREW.dress(body, palette, "athletic")
	var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
	animator.add_animation_library("ual", MOTION)
	animator.play(clip)
	body.global_position = at
	nodes.append(body)


## "Everyone say synergy!": the gallery screenshot, his tile blacked out, posted.
func _screenshot() -> void:
	story.sting(preload("res://assets/audio/sfx/light_relay.ogg"), -2)
	if DisplayServer.get_name() != "headless":
		var shot: Image = screen.get_texture().get_image()
		var you: Control = tiles[TILES.size() - 1]
		shot.fill_rect(Rect2i(Vector2i(you.position), Vector2i(you.size)), Color(0, 0, 0))
		photo.texture = ImageTexture.create_from_image(shot)
		story.whiteout(.3)
	story.crew_freeze.visible = true
	(story.crew_freeze.material as ShaderMaterial).set_shader_parameter("amount", .55)
	(story.crew_freeze.material as ShaderMaterial).set_shader_parameter("tint", Color(.8, .82, .9))
	ElementFx.slow_motion(&"photo", .02)
	card.show()
	card.modulate.a = 0.0
	var arrive: Tween = card.create_tween()
	arrive.set_ignore_time_scale(true)
	arrive.tween_interval(.3)
	arrive.tween_property(card, "modulate:a", 1.0, .25)


func _build_post() -> void:
	card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	card.offset_left = -600
	card.offset_right = -60
	card.offset_top = -300
	card.offset_bottom = 300
	card.rotation = deg_to_rad(-1.5)
	var paper: StyleBoxFlat = StyleBoxFlat.new()
	paper.bg_color = Color(1, 1, 1)
	paper.set_corner_radius_all(10)
	paper.set_content_margin_all(18)
	paper.shadow_color = Color(0, 0, 0, .45)
	paper.shadow_size = 18
	card.add_theme_stylebox_override("panel", paper)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)
	column.add_child(_wrapped("Brent Fairweather · Chief Synergy Officer at SYNERGEX · 1st\nPosted Monday, 9:31 AM · from Cabo", 15, Color(.35, .37, .4)))
	column.add_child(_wrapped(POST, 17, Color(.1, .1, .12)))
	photo = TextureRect.new()
	photo.custom_minimum_size = Vector2(500, 281)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	column.add_child(photo)
	column.add_child(_wrapped("♥ 4,812   ·   312 comments   ·   97 reposts   ·   1 engineer cropped out", 16, Color(.35, .37, .4)))
	card.hide()
	story.add_child(card)
	nodes.append(card)


func _label(words: String, size: int, colour: Color) -> Label:
	var label: Label = Label.new()
	label.text = words
	label.add_theme_font_override("font", preload("res://assets/fonts/inter_variable.ttf"))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label


func _wrapped(words: String, size: int, colour: Color) -> Label:
	var label: Label = _label(words, size, colour)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 500
	return label
