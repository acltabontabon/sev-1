extends CanvasLayer
## The "talk" call to action over a coworker: a chat bubble pinned above their head on
## screen, with an E keycap, a corporate verb ("SYNC UP WITH") and their name. It pops in
## when someone comes into reach, bobs gently, and is gone the moment a fight or a talk
## starts. Presentation only.

const VERBS: Array[String] = ["SYNC UP WITH", "TOUCH BASE WITH", "CIRCLE BACK WITH", "PING", "GRAB 5 MIN WITH", "INTERRUPT"]
const HOST_VERBS: Array[String] = ["CHECK ON", "ASK", "SAY HI TO"]
const ACCENT: Color = Color(.35, .9, .95)

var bubble: Control
var card: PanelContainer
var tail: Panel
var verb: Label
var who: Label
var anchor: Vector3
var target: Node3D
var clock: float = 0.0
var shown: float = 0.0


func _ready() -> void:
	layer = 3
	bubble = Control.new()
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(.03, .055, .07, .92)
	style.border_color = ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 8
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.shadow_color = Color(0, 0, 0, .45)
	style.shadow_size = 6
	# The tail: a small rotated square under the card's centre, drawn behind it.
	tail = Panel.new()
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tail_style: StyleBoxFlat = style.duplicate()
	tail_style.set_corner_radius_all(2)
	tail_style.shadow_size = 0
	tail.add_theme_stylebox_override("panel", tail_style)
	tail.size = Vector2(14, 14)
	tail.pivot_offset = Vector2(7, 7)
	tail.rotation = PI * .25
	tail.position = Vector2(-7, -16)
	bubble.add_child(tail)
	card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", style)
	bubble.add_child(card)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var cap: PanelContainer = PanelContainer.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cap_style: StyleBoxFlat = StyleBoxFlat.new()
	cap_style.bg_color = ACCENT
	cap_style.set_corner_radius_all(7)
	cap_style.border_color = ACCENT.darkened(.35)
	cap_style.border_width_bottom = 4
	cap_style.content_margin_left = 11
	cap_style.content_margin_right = 11
	cap_style.content_margin_top = 1
	cap_style.content_margin_bottom = 2
	cap.add_theme_stylebox_override("panel", cap_style)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(cap)
	_label(cap, "E", 22, Color(.02, .05, .06)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var words: VBoxContainer = VBoxContainer.new()
	words.add_theme_constant_override("separation", -4)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(words)
	verb = _label(words, "", 12, ACCENT)
	who = _label(words, "", 21, Color(.96, .97, 1))
	bubble.hide()


func _label(parent: Control, text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_bold.ttf"))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


## True while the bubble is up for someone.
func is_showing() -> bool:
	return target != null


## Point at someone (or nobody). The verb is picked once per person so it does not flicker.
func show_for(body: Node3D, name: String, host: bool, height: float) -> void:
	if body == null:
		# Out instantly (a fight started, or the talk began); in with a pop.
		target = null
		shown = 0.0
		bubble.hide()
		return
	if body != target:
		target = body
		shown = 0.0
		var pool: Array[String] = HOST_VERBS if host else VERBS
		verb.text = pool[absi(hash(name)) % pool.size()]
		who.text = name.to_upper()
	anchor = body.global_position + Vector3.UP * height


func _process(delta: float) -> void:
	clock += delta
	if target == null or not is_instance_valid(target):
		bubble.hide()
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or camera.is_position_behind(anchor):
		bubble.hide()
		return
	shown = move_toward(shown, 1.0, delta * 6.0)
	card.reset_size()
	var size: Vector2 = card.get_combined_minimum_size()
	card.position = Vector2(-size.x * .5, -size.y - 9)
	bubble.position = camera.unproject_position(anchor) + Vector2(0, sin(clock * 3.0) * 3.0)
	# A little overshoot on the way in.
	bubble.scale = Vector2.ONE * shown * (1.0 + .15 * sin(minf(shown, 1.0) * PI))
	bubble.modulate.a = shown
	bubble.show()
