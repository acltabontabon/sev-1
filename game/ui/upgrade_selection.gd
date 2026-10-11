extends CanvasLayer
## One persistent modal per incident; stays interactive while combat is paused.
## Power-ups lead with combat benefits; management offers three clear replies.
## Each card keeps its
## full plain-text summary in meta "summary" for accessibility and tests.
signal selected(index: int)
const FLAVOR: Array[String] = ["Hit harder with every attack.", "Take less damage from enemy hits.", "Dodge again sooner."]
const REPLIES: Array[String] = ["“Five minutes.”", "“I'll have a realistic estimate shortly.”", "“It's blocked on another team.”"]
const RISK: Array = [["RISK: HIGH", Color(1, .38, .25)], ["RISK: LOW", Color(.35, .9, .6)], ["RISK: MEDIUM", Color(1, .72, .3)]]
var panel: CenterContainer
var shade: ColorRect
var header: VBoxContainer
var eyebrow: Label
var heading: Label
var subhead: Label
var window_bar: PanelContainer
var footer: Label
var buttons: Array[Button] = []


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	shade = ColorRect.new()
	var frost: ShaderMaterial = ShaderMaterial.new()
	frost.shader = preload("res://game/ui/frosted.gdshader")
	frost.set_shader_parameter("blur", 3.5)
	shade.material = frost
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = CenterContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(1060, 0)
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	header = VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	box.add_child(header)
	window_bar = _window_bar()
	header.add_child(window_bar)
	eyebrow = Label.new()
	eyebrow.theme_type_variation = "Eyebrow"
	header.add_child(eyebrow)
	heading = Label.new()
	heading.theme_type_variation = "Headline"
	heading.add_theme_font_size_override("font_size", 40)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(heading)
	subhead = Label.new()
	subhead.theme_type_variation = "Caption"
	subhead.add_theme_font_size_override("font_size", 16)
	subhead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(subhead)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	for index in range(3):
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(336, 392)
		button.pressed.connect(_choose.bind(index))
		button.focus_entered.connect(_lift.bind(button, true))
		button.focus_exited.connect(_lift.bind(button, false))
		button.mouse_entered.connect(button.grab_focus)
		row.add_child(button)
		buttons.append(button)
	# Arrow keys walk the cards in either axis; Enter confirms.
	for index in range(3):
		var next: NodePath = buttons[(index + 1) % 3].get_path()
		var previous: NodePath = buttons[(index + 2) % 3].get_path()
		buttons[index].focus_neighbor_right = next
		buttons[index].focus_neighbor_bottom = next
		buttons[index].focus_neighbor_left = previous
		buttons[index].focus_neighbor_top = previous
	footer = Label.new()
	footer.theme_type_variation = "Eyebrow"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(footer)
	close()


func summary(index: int) -> String:
	return buttons[index].get_meta("summary", "")


func _window_bar() -> PanelContainer:
	var bar: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(.07, .09, .11)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.set_content_margin_all(8)
	style.content_margin_left = 14
	bar.add_theme_stylebox_override("panel", style)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	for color: Color in [Color(1, .37, .34), Color(1, .74, .2), Color(.3, .8, .4)]:
		var dot: PanelContainer = PanelContainer.new()
		var round: StyleBoxFlat = StyleBoxFlat.new()
		round.bg_color = color
		round.set_corner_radius_all(6)
		dot.add_theme_stylebox_override("panel", round)
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
	var name_label: Label = Label.new()
	name_label.text = "   ◆ Synergize — Incident call — Management"
	name_label.theme_type_variation = "MonoLabel"
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(.6, .7, .74))
	row.add_child(name_label)
	return bar


func _clear(button: Button) -> VBoxContainer:
	for child: Node in button.get_children():
		button.remove_child(child)
		child.queue_free()
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	button.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	return column


func _text(parent: Container, text: String, variation: String, size: int = 0, color: Color = Color(0, 0, 0, 0)) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	if size > 0:
		label.add_theme_font_size_override("font_size", size)
	if color.a > 0:
		label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _pill(parent: Container, text: String, color: Color) -> void:
	var pill: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(color, .16)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", style)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = "Eyebrow"
	label.add_theme_color_override("font_color", color)
	pill.add_child(label)
	parent.add_child(pill)


func _badge(parent: Container, number: int, color: Color) -> void:
	var badge: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(17)
	badge.add_theme_stylebox_override("panel", style)
	badge.custom_minimum_size = Vector2(34, 34)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label: Label = Label.new()
	label.text = str(number)
	label.theme_type_variation = "Subhead"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(.03, .04, .05))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(label)
	parent.add_child(badge)


## A meter that shows where a value is now and where this choice would put it.
func _meter(parent: Container, now: float, after: float, limit: float, color: Color) -> void:
	var holder: Control = Control.new()
	holder.custom_minimum_size = Vector2(0, 10)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	for layer_index in range(2):
		var bar: ProgressBar = ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = limit
		bar.value = after if layer_index == 0 else now
		bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var back: StyleBoxFlat = StyleBoxFlat.new()
		back.bg_color = Color(.1, .12, .14) if layer_index == 0 else Color(0, 0, 0, 0)
		back.set_corner_radius_all(3)
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = Color(color, .45) if layer_index == 0 else color
		fill.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("background", back)
		bar.add_theme_stylebox_override("fill", fill)
		holder.add_child(bar)


func _card_style(button: Button, fill: Color, accent: Color, radius: int) -> void:
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = fill if state != "focus" else Color(0, 0, 0, 0)
		if state in ["hover", "pressed"]:
			style.bg_color = fill.lightened(.06)
		style.set_corner_radius_all(radius)
		style.set_border_width_all(1 if state == "normal" else 3)
		style.border_color = Color(accent, .35) if state == "normal" else accent
		button.add_theme_stylebox_override(state, style)


func _stamp(button: Button, text: String, color: Color) -> void:
	var stamp: Label = Label.new()
	stamp.name = "Stamp"
	stamp.text = text
	stamp.theme_type_variation = "Headline"
	stamp.add_theme_font_size_override("font_size", 34)
	stamp.add_theme_color_override("font_color", Color(color, .85))
	stamp.add_theme_constant_override("outline_size", 2)
	stamp.add_theme_color_override("font_outline_color", color)
	stamp.position = Vector2(170, 300)
	stamp.rotation = -.2
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.visible = button.has_focus()
	button.add_child(stamp)


func _lift(button: Button, up: bool) -> void:
	button.pivot_offset = button.custom_minimum_size * .5
	var tween: Tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * (1.04 if up else 1.0), .12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if button.has_node("Stamp"):
		button.get_node("Stamp").visible = up


## Seconds after a modal opens during which choices are ignored (off in headless suites,
## which press keys on the same frame).
var input_guard: float = 0.0 if DisplayServer.get_name() == "headless" else .45
var guard_left: float = 0.0


func open(run: Node) -> void:
	window_bar.hide()
	eyebrow.text = "AREA CLEARED  ·  COMBAT PAUSED"
	heading.text = "Choose a power-up"
	subhead.text = "Pick one. Bonuses stack and last until this run ends. Debt makes enemies chase faster."
	footer.text = "1 · 2 · 3   OR   ← →  +  ENTER   ·   CHOOSE TO CONTINUE"
	var titles: Array[String] = ["More damage", "Less damage taken", "Faster dodge"]
	var benefits: Array[String] = [
		"+%d%% attack damage" % roundi(run.damage_bonus * 100),
		"−%d%% damage taken" % roundi(run.defense_bonus * 100),
		"−%d%% dodge recovery" % roundi(run.recovery_bonus * 100)]
	for index in range(3):
		var button: Button = buttons[index]
		var risk: Array = RISK[index]
		button.text = ""
		button.rotation = 0.0
		_card_style(button, Color(.075, .085, .095, .98), risk[1], 12)
		var column: VBoxContainer = _clear(button)
		_badge(column, index + 1, risk[1])
		_text(column, titles[index], "Headline", 32)
		_text(column, run.TITLES[index], "Caption", 15, Color(.65, .7, .74))
		column.add_child(HSeparator.new())
		_text(column, benefits[index], "Headline", 27, Color(.55, 1, .8))
		_text(column, FLAVOR[index], "Caption", 17)
		var after: int = clampi(run.debt + run.cost(index), 0, run.debt_limit)
		_text(column, ("Cost: +%d debt" % run.cost(index)) if run.cost(index) > 0 else "No added debt", "Subhead", 18, risk[1])
		_text(column, "Enemy chase speed: +%d%% → +%d%%" % [roundi((run.pressure() - 1) * 100), roundi((run.pressure(after) - 1) * 100)], "Caption", 16)
		_text(column, "Debt: %d → %d" % [run.debt, after], "Caption", 15, Color(.65, .7, .74))
		_text(column, "THIS RUN ONLY", "Eyebrow")
		button.set_meta("summary", "%s\n%s\n%s" % [titles[index], FLAVOR[index], run.option_text(index)])
	_show_choices()


func _show_choices() -> void:
	guard_left = input_guard
	shade.show()
	panel.show()
	# Card contents are decoration: every click and hover belongs to the card itself.
	for button in buttons:
		for child: Node in button.find_children("*", "Control", true, false):
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in range(3):
		var button: Button = buttons[index]
		button.modulate.a = 0.0
		var deal: Tween = button.create_tween()
		deal.tween_interval(.06 * index)
		deal.tween_property(button, "modulate:a", 1.0, .18)
	buttons[0].grab_focus()


func close() -> void:
	shade.hide()
	panel.hide()
	# Closed modals hold no card content; each opening builds its cards fresh.
	for button in buttons:
		button.release_focus()
		for child: Node in button.get_children():
			button.remove_child(child)
			child.queue_free()


func _choose(index: int) -> void:
	# Cards arrive mid-fight: a jump (Space accepts) or an attack click aimed at the
	# middle card must not sign anything before the deal-in finishes.
	if panel.visible and guard_left <= 0.0:
		selected.emit(index)


func _process(delta: float) -> void:
	guard_left = maxf(0.0, guard_left - delta)


func _input(event: InputEvent) -> void:
	if not panel.visible or event.is_echo():
		return
	for index in range(3):
		if event.is_action_pressed("choose_record_" + str(index + 1)):
			get_viewport().set_input_as_handled()
			_choose(index)
			return


func open_corporate(run: Node, seconds: float) -> void:
	window_bar.show()
	eyebrow.text = "CONTAINMENT REQUEST  ·  MANAGEMENT CALL  ·  ETA REQUIRED"
	heading.text = "Management asks: how long?"
	subhead.text = "Choose a reply to continue. Burnout is stress: high stress increases damage dealt and taken."
	footer.text = "1 · 2 · 3   OR   ← →  +  ENTER   ·   CLEARING CONTAINMENT RELIEVES %d BURNOUT   ·   DEBT UNCHANGED" % run.containment_relief
	var changes: Array[int] = [run.commit_burnout, run.estimate_burnout, -run.dependency_relief]
	var titles: Array[String] = ["Commit to Five Minutes", "Give a Realistic Estimate", "Escalate the Dependency"]
	var consequences: Array[String] = [
		"Optional %ds timer: beat it for −%d bonus Burnout. Missing it costs nothing." % [roundi(seconds), run.commitment_reward],
		"Normal containment. No timer, no extra threats.",
		"The dependency comes back as one extra Blocker."]
	for index in range(3):
		var button: Button = buttons[index]
		var after: int = clampi(run.burnout + changes[index], 0, run.burnout_limit)
		var tone: Color = [Color(1, .45, .3), Color(1, .75, .35), Color(.45, .85, 1)][run.burnout_band(after)]
		button.text = ""
		button.rotation = 0.0
		_card_style(button, Color(.09, .2, .21, .97), Color(.45, .9, .85), 18)
		var column: VBoxContainer = _clear(button)
		var top: HBoxContainer = HBoxContainer.new()
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(top)
		_badge(top, index + 1, Color(.45, .9, .85))
		var reply: Label = _text(top, "  YOU REPLY", "Eyebrow", 0, Color(.6, .9, .85))
		reply.autowrap_mode = TextServer.AUTOWRAP_OFF
		reply.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_text(column, REPLIES[index], "Headline", 28)
		_text(column, titles[index], "Caption", 15, Color(.7, .8, .82))
		column.add_child(HSeparator.new())
		_text(column, "Burnout %d → %d  ·  %s" % [run.burnout, after, run.burnout_title(after)], "Subhead", 18, tone)
		_meter(column, run.burnout, after, run.burnout_limit, tone)
		_text(column, consequences[index], "Caption", 15, Color(.82, .86, .88))
		_stamp(button, "SEND?", Color(.45, .9, .85))
		button.set_meta("summary", "%d   %s\n%s\nBurnout %d → %d / %s (%+d now)\n%s\n%s" % [index + 1, REPLIES[index], titles[index], run.burnout, after, run.burnout_title(after), after - run.burnout, run.modifier_summary(-1, after), consequences[index]])
	_show_choices()
