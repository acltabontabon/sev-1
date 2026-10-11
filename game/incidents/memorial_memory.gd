extends Node3D
## Illustrated memories: a specific shared action per teammate, told by the narrator.
## The drawings replace the discarded repeated desk tableaux and wandering extras.
const PEOPLE: Array[String] = ["Manager", "SRE", "Designer", "Intern", "Director"]
const FILES: Dictionary = {"Manager": "morgan", "SRE": "nadia", "Designer": "jun", "Intern": "jo", "Director": "val"}
const ART: String = "res://assets/environment/memorial_illustrations/%s_sketch.png"
var story: Node
var canvas: Control
var artwork: TextureRect
var memory_material: ShaderMaterial
var memory_tag: Label
var who: String = ""
var textures: Dictionary = {}


func _init(presentation: Node) -> void:
	story = presentation


func _ready() -> void:
	canvas = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.clip_contents = true
	story.add_child(canvas)
	# Image and grade precede the letterbox/captions: words remain sharp and readable.
	story.move_child(canvas, 0)
	artwork = TextureRect.new()
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(artwork)
	memory_material = ShaderMaterial.new()
	memory_material.shader = preload("res://game/incidents/memory_grade.gdshader")
	artwork.material = memory_material
	memory_tag = Label.new()
	memory_tag.position = Vector2(65, 55)
	memory_tag.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_semibold.ttf"))
	memory_tag.add_theme_font_size_override("font_size", 25)
	memory_tag.modulate = Color(.93, .84, .7, .8)
	memory_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(memory_tag)
	canvas.hide()
	hide()


func recall(person: String) -> void:
	who = person
	if not textures.has(who):
		textures[who] = load(ART % FILES[who])
	artwork.texture = textures[who]
	memory_tag.text = "BEFORE THE INCIDENT"
	canvas.show()
	show()


func frame(time: float, duration: float) -> void:
	var progress: float = smoothstep(0.0, duration, time)
	var zoom: float
	var drift: Vector2
	match who:
		"Manager":
			zoom = lerpf(1.035, 1.065, progress)
			drift = Vector2(18, -5).lerp(Vector2(-16, 3), progress)
		"SRE":
			zoom = lerpf(1.085, 1.025, progress)
			drift = Vector2(-8, 12).lerp(Vector2(8, -4), progress)
		"Designer":
			zoom = lerpf(1.025, 1.045, progress)
			drift = Vector2(-12, 0).lerp(Vector2(10, -3), progress)
		"Intern":
			zoom = lerpf(1.025, 1.085, progress)
			drift = Vector2(12, -8).lerp(Vector2(-5, 5), progress)
		_:
			zoom = lerpf(1.065, 1.025, progress)
			drift = Vector2(15, -5).lerp(Vector2(-10, 3), progress)
	var size: Vector2 = canvas.size
	artwork.offset_left = -size.x * (zoom - 1.0) * .5 + drift.x
	artwork.offset_right = size.x * (zoom - 1.0) * .5 + drift.x
	artwork.offset_top = -size.y * (zoom - 1.0) * .5 + drift.y
	artwork.offset_bottom = size.y * (zoom - 1.0) * .5 + drift.y
	memory_material.set_shader_parameter("memory_time", time)
	var dissolve: float = (1.0 - smoothstep(0.0, .65, time)) * .75 + smoothstep(duration - .6, duration, time) * .8
	memory_material.set_shader_parameter("dissolve", dissolve)


func conceal() -> void:
	hide()
	canvas.hide()


func _exit_tree() -> void:
	if is_instance_valid(canvas):
		canvas.queue_free()
