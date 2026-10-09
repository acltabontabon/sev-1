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
	shade.color = Color(.01, .02, .03, .92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = CenterContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(700, 0)
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	heading = Label.new()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	box.add_child(heading)
	for index in range(3):
		var button: Button = Button.new()
		button.custom_minimum_size.y = 90
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_choose.bind(index))
		box.add_child(button)
		buttons.append(button)
	footer = Label.new()
	footer.text = "1 / 2 / 3 or click to choose • Arrows / Enter also work\nBonuses last this run and add against base values. R restarts."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(footer)
	close()


func open(run: Node) -> void:
	footer.text = "1 / 2 / 3 or click to choose • Arrows / Enter also work\nBonuses last this run and add against base values. R restarts."
	heading.text = "CHANGE REQUEST  /  CHOOSE ONE\nTechnical Debt: %d / %d — %s" % [run.debt, run.debt_limit, run.severity()]
	for index in range(3):
		buttons[index].text = run.option_text(index)
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
	heading.text = "MANAGEMENT ESCALATION — ETA REQUIRED\nQuick question. Leadership wants an ETA.\nCan you commit to resolving this in the next five minutes?"
	buttons[0].text = "1   Commit to Five Minutes\n“Sure. Five minutes should be enough.”\n+%d Burnout. Clear containment in %d active seconds: −%d Burnout bonus. No failure penalty." % [run.commit_burnout, roundi(seconds), run.commitment_reward]
	buttons[1].text = "2   Give a Realistic Estimate\n“I’ll provide an estimate after identifying the root cause.”\n+%d Burnout. No additional encounter modifier." % run.estimate_burnout
	buttons[2].text = "3   Escalate the Dependency\n“The issue appears to be owned by another service.”\n−%d Burnout (minimum 0). One extra dependency record in containment." % run.dependency_relief
	footer.text = "1 / 2 / 3 or click • Arrows / Enter • R restarts\nAll choices: clear containment for −%d Burnout. Technical Debt is unchanged." % run.containment_relief
	shade.show()
	panel.show()
	buttons[0].grab_focus()
