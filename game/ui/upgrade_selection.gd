extends CanvasLayer
## One persistent modal per incident; stays interactive while combat is paused.
## Upgrades read as change requests; the management decision as a direct message.
signal selected(index: int)
const FLAVOR: Array[String] = ["“Tests are just opinions.”", "“Slower. Safer. Somehow controversial.”", "“Nothing is more permanent.”"]
const REPLIES: Array[String] = ["“Five minutes.”", "“I'll have a realistic estimate shortly.”", "“It's blocked on another team.”"]
var panel: CenterContainer
var shade: ColorRect
var eyebrow: Label
var heading: Label
var footer: Label
var buttons: Array[Button] = []


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	shade = ColorRect.new()
	shade.color = Color(.01, .015, .02, .82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = CenterContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(1000, 0)
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	eyebrow = Label.new()
	eyebrow.theme_type_variation = "Eyebrow"
	box.add_child(eyebrow)
	heading = Label.new()
	heading.theme_type_variation = "Headline"
	heading.add_theme_font_size_override("font_size", 34)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(heading)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	for index in range(3):
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(324, 280)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_choose.bind(index))
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
	footer.theme_type_variation = "Caption"
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(footer)
	close()


func open(run: Node) -> void:
	eyebrow.text = "CHANGE REQUEST  ·  CHOOSE ONE  ·  TECH DEBT %d / %d  ·  %s" % [run.debt, run.debt_limit, run.severity()]
	heading.text = "Approve one shortcut. Every shortcut is approved."
	footer.text = "1 / 2 / 3, arrows + Enter, or click  ·  R restarts  ·  This run only. Percentages are totals against base; lower Taken and Recovery are better."
	for index in range(3):
		var text: String = run.option_text(index)
		buttons[index].text = text.insert(text.find("\n") + 1, FLAVOR[index] + "\n\n")
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
	eyebrow.text = "DIRECT MESSAGE  ·  LEADERSHIP  ·  1 UNREAD  ·  MARKED URGENT"
	heading.text = "“Quick one: can we fix this without making any changes? Also, ETA? I told the VP ‘shortly’.”"
	var changes: Array[int] = [run.commit_burnout, run.estimate_burnout, -run.dependency_relief]
	var titles: Array[String] = ["Commit to Five Minutes", "Give a Realistic Estimate", "Escalate the Dependency"]
	var consequences: Array[String] = [
		"Clear containment in %ds for −%d bonus Burnout. Expiry: no penalty." % [roundi(seconds), run.commitment_reward],
		"Normal containment. No timer, no extra threats.",
		"The dependency comes back: one extra Blocker in containment."]
	for index in range(3):
		var after: int = clampi(run.burnout + changes[index], 0, run.burnout_limit)
		buttons[index].text = "%d  ·  %s\n%s\n\nBurnout %d → %d / %s (%+d now)\n%s\n\n%s" % [index + 1, REPLIES[index], titles[index], run.burnout, after, run.burnout_title(after), after - run.burnout, run.modifier_summary(-1, after), consequences[index]]
	footer.text = "1 / 2 / 3, arrows + Enter, or click  ·  R restarts  ·  Clearing containment relieves %d Burnout, not health. Debt stays unchanged." % run.containment_relief
	_show_choices()
