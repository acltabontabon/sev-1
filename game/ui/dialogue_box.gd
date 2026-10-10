extends CanvasLayer
## RPG-style talk: a name plate, the line typing out, then up to three replies.
## Runs while the incident is paused (talking releases the camera capture like any modal).
## 1 · 2 · 3 or a click picks a reply; E / Space finishes the line or continues; Esc leaves.

signal finished

const DIALOGUES: Script = preload("res://game/incidents/dialogues.gd")

const SPEED: float = 60.0
const ACCENT: Color = Color(.35, .9, .95)
var tree: Dictionary = {}
var node_id: String = ""
var shown: float = 0.0
var on_effect: Callable
var shade: Control
var panel: PanelContainer
var name_label: Label
var role_label: Label
var text_label: Label
var replies: VBoxContainer
var footer: Label
var toast: Label
## Each line is spoken; the text types out at the speed of the voice.
var speaker: AudioStreamPlayer
var pace: float = SPEED


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Swallows stray clicks so they cannot recapture the mouse and unpause mid-talk.
	shade = Control.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -470
	panel.offset_right = 470
	panel.offset_top = -40
	panel.offset_bottom = -40
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(.02, .035, .045, .94)
	style.border_color = ACCENT
	style.border_width_left = 4
	style.border_width_top = 1
	style.set_corner_radius_all(6)
	style.set_content_margin_all(18)
	style.content_margin_left = 24
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var plate: HBoxContainer = HBoxContainer.new()
	plate.add_theme_constant_override("separation", 14)
	column.add_child(plate)
	name_label = _label(plate, "DisplayTitle", 34, Color(.95, .97, 1))
	role_label = _label(plate, "Eyebrow", 14, ACCENT)
	role_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_label = _label(column, "Subhead", 21, Color(.88, .91, .94))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(880, 0)
	replies = VBoxContainer.new()
	replies.add_theme_constant_override("separation", 4)
	column.add_child(replies)
	var bottom: HBoxContainer = HBoxContainer.new()
	column.add_child(bottom)
	footer = _label(bottom, "MonoLabel", 12, Color(.55, .62, .66))
	footer.text = "1 · 2 · 3  REPLY     E  CONTINUE     ESC  LEAVE"
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast = _label(bottom, "MonoLabel", 12, Color(1, .72, .4))
	speaker = AudioStreamPlayer.new()
	speaker.bus = &"Voice"
	add_child(speaker)
	hide()


func _label(parent: Control, variation: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func is_open() -> bool:
	return visible


## Start a talk. `effect` receives a reply's effect dictionary when it has one.
func open(talk: Dictionary, effect: Callable, again: bool = false) -> void:
	tree = talk
	on_effect = effect
	name_label.text = talk.get("who", "")
	role_label.text = str(talk.get("role", "")).to_upper()
	toast.text = ""
	show()
	_go(talk.get("again", talk.start) if again else talk.start)


func _go(id: String) -> void:
	if id.is_empty() or not tree.nodes.has(id):
		close()
		return
	node_id = id
	var node: Dictionary = tree.nodes[id]
	text_label.text = node.text
	text_label.visible_characters = 0
	shown = 0.0
	pace = SPEED
	speaker.stop()
	var path: String = DIALOGUES.audio(str(tree.get("voice", "")) + id)
	if tree.has("voice") and ResourceLoader.exists(path):
		speaker.stream = load(path)
		pace = clampf(text_label.get_total_character_count() / maxf(speaker.stream.get_length() * .85, .3), 18.0, 90.0)
		if DisplayServer.get_name() != "headless":
			speaker.play()
	for child in replies.get_children():
		replies.remove_child(child)
		child.queue_free()
	var options: Array = node.replies if not node.replies.is_empty() else [["Leave", "", {}]]
	for index in range(options.size()):
		var button: Button = Button.new()
		button.text = "%d   %s" % [index + 1, options[index][0]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.flat = true
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", Color(.75, .92, .95))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		button.add_theme_color_override("font_focus_color", Color(1, 1, 1))
		button.pressed.connect(choose.bind(index))
		replies.add_child(button)
	replies.modulate.a = 0.0


func typed() -> bool:
	return shown >= text_label.get_total_character_count()


func _process(delta: float) -> void:
	if not visible:
		return
	shown += delta * pace
	text_label.visible_characters = -1 if typed() else int(shown)
	var ready: bool = typed()
	replies.modulate.a = move_toward(replies.modulate.a, 1.0 if ready else 0.0, delta * 8.0)
	for button: Button in replies.get_children():
		button.disabled = not ready
	if ready and replies.get_child_count() > 0 and get_viewport().gui_get_focus_owner() == null:
		(replies.get_child(0) as Button).grab_focus()


func options() -> Array:
	var node: Dictionary = tree.nodes.get(node_id, {})
	return node.get("replies", []) if not node.get("replies", []).is_empty() else [["Leave", "", {}]]


func choose(index: int) -> void:
	if not visible or not typed():
		return
	var list: Array = options()
	if index < 0 or index >= list.size():
		return
	var reply: Array = list[index]
	var effect: Dictionary = reply[2]
	if not effect.is_empty() and on_effect.is_valid():
		on_effect.call(effect)
		var change: int = int(effect.get("burnout", 0))
		toast.text = "BURNOUT %s%d  ·  %s" % ["+" if change > 0 else "−", absi(change), str(effect.get("note", "")).to_upper()]
	_go(reply[1])


func close() -> void:
	if not visible:
		return
	hide()
	speaker.stop()
	tree = {}
	node_id = ""
	for child in replies.get_children():
		replies.remove_child(child)
		child.queue_free()
	finished.emit()


func _input(event: InputEvent) -> void:
	if not visible or event.is_echo() or not event.is_pressed():
		return
	var handled: bool = true
	if event.is_action_pressed("release_mouse"):
		close()
	elif event.is_action_pressed("inspect_record") or (event is InputEventKey and event.physical_keycode in [KEY_SPACE, KEY_ENTER]):
		if not typed():
			shown = 9999.0
		elif options().size() == 1:
			choose(0)
		else:
			# Several replies: Enter goes to the focused reply button instead.
			handled = false
	else:
		handled = false
		for index in range(3):
			if event.is_action_pressed("choose_record_%d" % (index + 1)):
				choose(index)
				handled = true
	if handled:
		get_viewport().set_input_as_handled()
