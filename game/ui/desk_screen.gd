extends Node3D
## The engineer's monitor: real interface layout rendered into the 3D display.
## Owned by its viewer (menu backdrop or opening); it never reads incident state.

const SIZE: Vector2i = Vector2i(1024, 584)
const FACE: Vector2 = Vector2(.93, .53)
const CHAT_LIMIT: int = 3
var viewport: SubViewport
var root: Control
var clock: Label
var chat: VBoxContainer
var typing: Label
var editor: Control
var banner_label: Label
var logoff: PanelContainer
var logoff_button: Label
var cursor: Polygon2D
var alarm_panel: ColorRect
var alarm_title: Label
var alarm_detail: Label
var alarm_time: float = -1.0
var glow: OmniLight3D
var glow_energy: float = .9
var pulse: float = 0.0


func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = SIZE
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	root = Control.new()
	root.size = SIZE
	viewport.add_child(root)
	_rect(root, Rect2(Vector2.ZERO, SIZE), Color(.035, .05, .062))
	_build_editor()
	_build_chat()
	_build_bar()
	_build_logoff()
	_build_alarm()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = FACE
	var face: MeshInstance3D = MeshInstance3D.new()
	face.name = "Face"
	face.mesh = quad
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	face.material_override = material
	add_child(face)
	# Screen light falls on the engineer's face; this is the scene's key light at the desk.
	glow = OmniLight3D.new()
	glow.position = Vector3(0, 0, .55)
	glow.light_color = Color(.55, .8, .9)
	glow.omni_range = 2.4
	glow.omni_attenuation = 1.6
	glow.light_energy = glow_energy
	add_child(glow)


func _rect(parent: Control, area: Rect2, color: Color) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.position = area.position
	rect.size = area.size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


func _text(parent: Control, text: String, at: Vector2, variation: String = "", size: int = 0, color: Color = Color(.88, .93, .94)) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = at
	if not variation.is_empty():
		label.theme_type_variation = variation
	if size > 0:
		label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _build_bar() -> void:
	_rect(root, Rect2(0, 0, SIZE.x, 34), Color(.012, .018, .024))
	_text(root, "◆  Synergize", Vector2(14, 5), "MonoLabel", 16, Color(.6, .86, .9))
	_text(root, "Workspace: Payments Platform", Vector2(170, 6), "Caption", 15)
	clock = _text(root, "FRI 16:59", Vector2(SIZE.x - 118, 5), "MonoLabel", 17)


func _build_editor() -> void:
	editor = Control.new()
	editor.position = Vector2(0, 34)
	editor.size = Vector2(560, SIZE.y - 34)
	root.add_child(editor)
	_rect(editor, Rect2(Vector2.ZERO, editor.size), Color(.025, .036, .045))
	_text(editor, "reconcile_ledger.py  —  main  ✓ tests passing", Vector2(16, 10), "MonoLabel", 13, Color(.5, .62, .64))
	var widths: Array[int] = [220, 310, 180, 360, 260, 140, 330, 290, 200, 380, 240, 170, 300]
	for index in range(widths.size()):
		var indent: int = 16 + (index % 4) * 22
		_rect(editor, Rect2(56 + indent, 46 + index * 31, widths[index], 9), [Color(.33, .72, .66), Color(.55, .63, .8), Color(.8, .62, .4)][index % 3].darkened(.15))
		_text(editor, str(index + 141), Vector2(14, 38 + index * 31), "MonoLabel", 12, Color(.3, .37, .4))
	var strip: ColorRect = _rect(editor, Rect2(0, editor.size.y - 44, editor.size.x, 44), Color(.42, .05, .03))
	banner_label = _text(strip, "", Vector2(16, 10), "MonoLabel", 16, Color(1, .86, .82))
	strip.hide()


func _build_chat() -> void:
	var panel: Control = Control.new()
	panel.position = Vector2(560, 34)
	panel.size = Vector2(SIZE.x - 560, SIZE.y - 34)
	root.add_child(panel)
	_rect(panel, Rect2(Vector2.ZERO, panel.size), Color(.045, .062, .078))
	_rect(panel, Rect2(0, 0, 2, panel.size.y), Color(.12, .18, .21))
	_text(panel, "# general", Vector2(20, 12), "Subhead", 20)
	_text(panel, "248 members · 3 online", Vector2(20, 42), "Caption", 13)
	_rect(panel, Rect2(0, 70, panel.size.x, 1), Color(.12, .18, .21))
	chat = VBoxContainer.new()
	chat.position = Vector2(16, 82)
	chat.size = Vector2(panel.size.x - 32, panel.size.y - 130)
	chat.alignment = BoxContainer.ALIGNMENT_END
	chat.add_theme_constant_override("separation", 14)
	panel.add_child(chat)
	typing = _text(panel, "", Vector2(20, panel.size.y - 38), "Caption", 14)


func _build_logoff() -> void:
	logoff = PanelContainer.new()
	logoff.theme_type_variation = "Card"
	logoff.position = Vector2(300, 190)
	logoff.custom_minimum_size = Vector2(420, 0)
	root.add_child(logoff)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	logoff.add_child(box)
	var title: Label = Label.new()
	title.text = "End session?"
	title.theme_type_variation = "Subhead"
	box.add_child(title)
	var body: Label = Label.new()
	body.text = "You have 0 open incidents.\nYour status will change to Away."
	body.theme_type_variation = "Caption"
	box.add_child(body)
	var button: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(.18, .55, .5)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	button.add_theme_stylebox_override("panel", style)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	box.add_child(button)
	logoff_button = Label.new()
	logoff_button.text = "  Log Off  "
	logoff_button.theme_type_variation = "Subhead"
	button.add_child(logoff_button)
	logoff.hide()
	cursor = Polygon2D.new()
	cursor.polygon = PackedVector2Array([Vector2(0, 0), Vector2(0, 22), Vector2(6, 17), Vector2(11, 26), Vector2(14, 24), Vector2(9, 15), Vector2(16, 15)])
	cursor.color = Color.WHITE
	cursor.position = Vector2(420, 470)
	cursor.hide()
	root.add_child(cursor)


func _build_alarm() -> void:
	alarm_panel = _rect(root, Rect2(Vector2.ZERO, SIZE), Color(.55, .03, .02))
	alarm_panel.clip_contents = true
	_rect(alarm_panel, Rect2(0, 0, SIZE.x, 34), Color(.2, 0, 0))
	_text(alarm_panel, "ON-CALL PAGER  ·  ESCALATION POLICY: YOU", Vector2(14, 6), "MonoLabel", 15, Color(1, .8, .75))
	alarm_title = _text(alarm_panel, "SEV-1", Vector2.ZERO, "DisplayTitle", 210, Color.WHITE)
	alarm_detail = _text(alarm_panel, "CRITICAL PRODUCTION INCIDENT\nINC-001  ·  Payments  ·  Transaction states inconsistent\nAcknowledge within 00:00:00", Vector2.ZERO, "Subhead", 30, Color(1, .9, .86))
	for label: Label in [alarm_title, alarm_detail]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size.x = SIZE.x
	alarm_title.position.y = 60
	alarm_detail.position.y = 330
	alarm_panel.hide()


## After acknowledgement the takeover shrinks to a banner; the chat stays readable.
func alarm_compact() -> void:
	alarm_panel.size.y = 34
	alarm_title.hide()
	alarm_detail.hide()
	banner("SEV-1  ·  INC-001  ·  ACKNOWLEDGED BY: YOU")


func banner(text: String) -> void:
	banner_label.text = text
	banner_label.get_parent().visible = not text.is_empty()


func set_clock(text: String) -> void:
	clock.text = text


func post(speaker: String, text: String, color: Color, time: String = "16:59") -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var avatar: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	avatar.add_theme_stylebox_override("panel", style)
	avatar.custom_minimum_size = Vector2(40, 40)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var initials: Label = Label.new()
	for word: String in speaker.split(" ", false):
		initials.text += word.left(1)
	initials.text = initials.text.left(2)
	initials.theme_type_variation = "Subhead"
	initials.add_theme_font_size_override("font_size", 16)
	initials.add_theme_color_override("font_color", Color(.02, .03, .04))
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(initials)
	row.add_child(avatar)
	var body: VBoxContainer = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 2)
	var name_label: Label = Label.new()
	name_label.text = "%s   %s" % [speaker, time]
	name_label.theme_type_variation = "Subhead"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", color.lightened(.25))
	body.add_child(name_label)
	var message: Label = Label.new()
	message.text = text
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Known wrap width up front, or the first layout pass inflates the row height.
	message.custom_minimum_size.x = chat.size.x - 56
	message.add_theme_font_size_override("font_size", 18)
	body.add_child(message)
	row.add_child(body)
	chat.add_child(row)
	while chat.get_child_count() > CHAT_LIMIT:
		var oldest: Node = chat.get_child(0)
		chat.remove_child(oldest)
		oldest.queue_free()
	row.modulate.a = 0.0
	create_tween().tween_property(row, "modulate:a", 1.0, .25)
	typing.text = ""
	pulse = 1.0


func set_typing(text: String) -> void:
	typing.text = text


func clear_chat() -> void:
	for child: Node in chat.get_children():
		chat.remove_child(child)
		child.queue_free()
	typing.text = ""


## progress 0..1 moves the cursor onto Log Off; pressed darkens the button.
func show_logoff(open: bool, progress: float = 0.0, pressed: bool = false) -> void:
	logoff.visible = open
	cursor.visible = open
	if open:
		cursor.position = Vector2(420, 470).lerp(Vector2(640, 322), smoothstep(0, 1, progress))
		logoff_button.get_parent().modulate = Color(.7, .7, .7) if pressed else Color.WHITE


func alarm(active: bool) -> void:
	alarm_panel.visible = active
	alarm_panel.size.y = SIZE.y
	alarm_title.show()
	alarm_detail.show()
	alarm_time = 0.0 if active else -1.0
	glow.light_color = Color(1, .2, .12) if active else Color(.55, .8, .9)


## Live while it is on camera; afterwards the last frame stays on the display for free.
func set_live(live: bool) -> void:
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if live else SubViewport.UPDATE_ONCE
	set_process(live)


func reset_screen() -> void:
	clear_chat()
	banner("")
	show_logoff(false)
	alarm(false)
	set_clock("FRI 16:59")


func _process(delta: float) -> void:
	pulse = maxf(0, pulse - delta * 2.5)
	glow.light_energy = glow_energy * (1.0 + pulse * .6)
	if alarm_time >= 0:
		alarm_time += delta
		var flash: float = .5 + .5 * cos(alarm_time * TAU * 1.4)
		alarm_panel.color = Color(.32, .015, .01).lerp(Color(.7, .05, .03), flash)
		glow.light_energy = glow_energy * (1.4 + flash)
