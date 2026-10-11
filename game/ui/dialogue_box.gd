extends CanvasLayer
## RPG-style talk: a name plate, the line typing out, then numbered replies.
## Runs while the incident is paused (talking releases the camera capture like any modal).
## Number keys or a click pick replies; E reveals text, then skips speech; Esc leaves.

signal finished

const DIALOGUES: Script = preload("res://game/incidents/dialogues.gd")

const SPEED: float = 60.0
const ACCENT: Color = Color(.35, .9, .95)
static var ROW: StyleBoxEmpty
static var ROW_FOCUS: StyleBoxFlat
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
var on_frame: Callable
## "them" while the other person talks, "you" while the engineer answers.
var speaking: String = "them"
var answer_next: String = ""
var line_time: float = 0.0
var line_count: int = 0
var hold_left: float = 0.0


func _ready() -> void:
	if ROW == null:
		ROW = StyleBoxEmpty.new()
		ROW.content_margin_left = 10
		ROW.content_margin_top = 2
		ROW.content_margin_bottom = 2
		ROW_FOCUS = StyleBoxFlat.new()
		ROW_FOCUS.bg_color = Color(ACCENT, .1)
		ROW_FOCUS.border_color = ACCENT
		ROW_FOCUS.border_width_left = 2
		ROW_FOCUS.content_margin_left = 10
		ROW_FOCUS.content_margin_top = 2
		ROW_FOCUS.content_margin_bottom = 2
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Swallows stray clicks so they cannot recapture the mouse and unpause mid-talk.
	shade = Control.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -340
	panel.offset_right = 340
	panel.offset_top = -26
	panel.offset_bottom = -26
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(.02, .035, .045, .94)
	style.border_color = ACCENT
	style.border_width_left = 4
	style.border_width_top = 1
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	style.content_margin_left = 18
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	var plate: HBoxContainer = HBoxContainer.new()
	plate.add_theme_constant_override("separation", 14)
	column.add_child(plate)
	name_label = _label(plate, "DisplayTitle", 25, Color(.95, .97, 1))
	role_label = _label(plate, "Eyebrow", 11, ACCENT)
	role_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_label = _label(column, "Subhead", 16, Color(.88, .91, .94))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(640, 0)
	replies = VBoxContainer.new()
	replies.add_theme_constant_override("separation", 0)
	column.add_child(replies)
	var bottom: HBoxContainer = HBoxContainer.new()
	column.add_child(bottom)
	footer = _label(bottom, "MonoLabel", 10, Color(.55, .62, .66))
	footer.text = "E  REVEAL LINE     ESC  LEAVE"
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast = _label(bottom, "MonoLabel", 10, Color(1, .72, .4))
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


## Start a talk. `effect` receives a reply's effect dictionary when it has one; `frame`
## is called every frame with (who is speaking: "them" or "you", seconds into the line,
## line number, the line's text) so the incident can cut cameras and gesture.
func open(talk: Dictionary, effect: Callable, again: bool = false, frame: Callable = Callable()) -> void:
	tree = talk
	on_effect = effect
	on_frame = frame
	line_count = 0
	toast.text = ""
	show()
	_go(talk.get("again", talk.start) if again else talk.start)


## Show and speak one line: the other person's (with replies) or the engineer's answer.
func _say(who: String, text: String, clip: String) -> void:
	speaking = who
	line_time = 0.0
	line_count += 1
	name_label.text = "YOU" if who == "you" else tree.get("who", "")
	role_label.text = "ON CALL  ·  ENGINEER" if who == "you" else str(tree.get("role", "")).to_upper()
	if node_id == "good_days":
		role_label.text = "OFF THE CLOCK  ·  JUST US"
		role_label.add_theme_color_override("font_color", Color(.95, .76, .48))
	else:
		role_label.add_theme_color_override("font_color", ACCENT)
	name_label.add_theme_color_override("font_color", ACCENT if who == "you" else Color(.95, .97, 1))
	text_label.text = text
	text_label.visible_characters = 0
	shown = 0.0
	pace = SPEED
	speaker.stop()
	var path: String = DIALOGUES.audio(clip)
	if not clip.is_empty() and ResourceLoader.exists(path):
		speaker.stream = load(path)
		pace = clampf(text_label.get_total_character_count() / maxf(speaker.stream.get_length() * .85, .3), 18.0, 90.0)
		if DisplayServer.get_name() != "headless":
			speaker.play()
	for child in replies.get_children():
		replies.remove_child(child)
		child.queue_free()


func _go(id: String) -> void:
	if id.is_empty() or not tree.nodes.has(id):
		close()
		return
	node_id = id
	var line: Dictionary = DIALOGUES.line(tree, id)
	_say("them", line.text, line.clip)
	var list: Array = options()
	for index in range(list.size()):
		var button: Button = Button.new()
		button.text = "%d   %s" % [index + 1, list[index][0]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.flat = true
		button.custom_minimum_size.y = 24
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, ROW)
		button.add_theme_stylebox_override("focus", ROW_FOCUS)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override("font_color", Color(.75, .92, .95))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		button.add_theme_color_override("font_focus_color", Color(1, 1, 1))
		button.pressed.connect(choose.bind(index))
		replies.add_child(button)
	replies.modulate.a = 0.0


func typed() -> bool:
	return shown >= text_label.get_total_character_count()


func reply_ready() -> bool:
	return typed() and not speaker.playing


func _process(delta: float) -> void:
	if not visible:
		return
	line_time += delta
	shown += delta * pace
	text_label.visible_characters = -1 if typed() else int(shown)
	if on_frame.is_valid():
		on_frame.call(speaking, line_time, line_count, text_label.text)
	# The engineer's answer plays out, then the other person responds.
	if speaking == "you":
		footer.text = "E  REVEAL LINE     ESC  LEAVE" if not typed() else "E  CONTINUE     ESC  LEAVE"
		if typed() and not speaker.playing:
			hold_left -= delta
			if hold_left <= 0:
				advance()
		return
	var ready: bool = reply_ready()
	footer.text = "E  REVEAL LINE     ESC  LEAVE" if not typed() else ("E  SKIP VOICE     ESC  LEAVE" if speaker.playing else "1–%d  REPLY     E  CONTINUE     ESC  LEAVE" % options().size())
	replies.modulate.a = move_toward(replies.modulate.a, 1.0 if ready else 0.0, delta * 8.0)
	for button: Button in replies.get_children():
		button.disabled = not ready
	if ready and replies.get_child_count() > 0 and get_viewport().gui_get_focus_owner() == null:
		(replies.get_child(0) as Button).grab_focus()


func options() -> Array:
	var node: Dictionary = tree.nodes.get(node_id, {})
	return node.get("replies", []) if not node.get("replies", []).is_empty() else [["Leave", "", {}]]


func choose(index: int) -> void:
	if not visible or not reply_ready() or speaking == "you":
		return
	var list: Array = options()
	if index < 0 or index >= list.size():
		return
	var reply: Array = list[index]
	if node_id == "good_days" and tree.has("voice") and not reply[1]:
		DIALOGUES.promises[str(tree.voice)] = str(reply[0])
	var effect: Dictionary = reply[2]
	if not effect.is_empty() and on_effect.is_valid():
		on_effect.call(effect)
		var change: int = int(effect.get("burnout", 0))
		toast.text = "BURNOUT %s%d  ·  %s" % ["+" if change > 0 else "−", absi(change), str(effect.get("note", "")).to_upper()]
	answer_next = reply[1]
	if DIALOGUES.voiced_reply(reply[0]) and reply[0] != "Leave":
		hold_left = .25
		_say("you", reply[0], DIALOGUES.reply_id(reply[0]))
	else:
		_go(answer_next)


## Finish the current line now: complete the typing, or end the engineer's answer.
func advance() -> void:
	if not typed():
		shown = 9999.0
	elif speaker.playing:
		speaker.stop()
	elif speaking == "you":
		speaking = "them"
		_go(answer_next)


func close() -> void:
	if not visible:
		return
	hide()
	speaker.stop()
	speaking = "them"
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
		if not reply_ready() or speaking == "you":
			advance()
		elif options().size() == 1:
			choose(0)
		else:
			# Several replies: Enter goes to the focused reply button instead.
			handled = false
	else:
		handled = false
		for index in range(mini(9, options().size())):
			if event is InputEventKey and (event.physical_keycode == KEY_1 + index or event.physical_keycode == KEY_KP_1 + index):
				choose(index)
				handled = true
	if handled:
		get_viewport().set_input_as_handled()
