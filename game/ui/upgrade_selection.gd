extends CanvasLayer
## One persistent modal per incident; stays interactive while combat is paused.
signal selected(index: int)
var panel: CenterContainer
var shade: ColorRect
var heading: Label
var footer: Label
var buttons: Array[Button] = []


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	shade = ColorRect.new()
	shade.color = Color(.01, .02, .03, .95)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = CenterContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(880, 0)
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	heading = Label.new()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color(.65, .95, 1))
	heading.add_theme_font_size_override("font_size", 22)
	box.add_child(heading)
	for index in range(3):
		var button: Button = Button.new()
		button.custom_minimum_size.y = 112
		button.add_theme_font_size_override("font_size", 18)
		for state in ["normal", "hover", "pressed", "focus"]:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = Color(.045, .075, .09) if state == "normal" else Color(.08, .16, .19)
			style.set_corner_radius_all(4)
			style.set_content_margin_all(10)
			if state == "focus":
				style.bg_color = Color(0, 0, 0, 0)
				style.set_border_width_all(3)
				style.border_color = Color(.5, .95, 1)
			button.add_theme_stylebox_override(state, style)
		button.pressed.connect(_choose.bind(index))
		box.add_child(button)
		buttons.append(button)
	footer = Label.new()
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 16)
	box.add_child(footer)
	close()


func open(run: Node) -> void:
	footer.text = "1 / 2 / 3 or click • Arrows / Enter • R restarts\nThis run only. Percentages are totals against base; lower Taken / Recovery is better."
	heading.text = "CHANGE REQUEST / CHOOSE ONE\nDebt %d / %d — %s • Burnout %d — %s" % [run.debt, run.debt_limit, run.severity(), run.burnout, run.burnout_title()]
	for index in range(3):
		buttons[index].text = run.option_text(index)
	_show_choices()


func _show_choices() -> void:
	shade.show()
	panel.show()
	buttons[0].grab_focus()


func close() -> void:
	shade.hide()
	panel.hide()
	for button in buttons:
		button.release_focus()


func _choose(index: int) -> void:
	if panel.visible:
		selected.emit(index)


func _input(event: InputEvent) -> void:
	if not panel.visible or event.is_echo():
		return
	for index in range(3):
		if event.is_action_pressed("choose_record_" + str(index + 1)):
			get_viewport().set_input_as_handled()
			_choose(index)
			return


func open_corporate(run: Node, seconds: float) -> void:
	heading.text = "MANAGEMENT ESCALATION — ETA REQUIRED\nContainment needs an owner. Leadership needs a number."
	var changes: Array[int] = [run.commit_burnout, run.estimate_burnout, -run.dependency_relief]
	var titles: Array[String] = ["Commit to Five Minutes", "Give a Realistic Estimate", "Escalate the Dependency"]
	var consequences: Array[String] = [
		"Clear containment in %ds: −%d bonus Burnout. Expiry: no penalty." % [roundi(seconds), run.commitment_reward],
		"Normal containment. No extra records or timer.",
		"One extra dependency record to fight during containment."]
	for index in range(3):
		var after: int = clampi(run.burnout + changes[index], 0, run.burnout_limit)
		buttons[index].text = "%d   %s\nBurnout %d → %d / %s (%+d now)\n%s\n%s" % [index + 1, titles[index], run.burnout, after, run.burnout_title(after), after - run.burnout, run.modifier_summary(-1, after), consequences[index]]
	footer.text = "1 / 2 / 3 or click • Arrows / Enter • R restarts\nThis run only. Clear containment: −%d Burnout, not health. Debt stays unchanged." % run.containment_relief
	_show_choices()
