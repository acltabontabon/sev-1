extends CanvasLayer
## One persistent modal per incident; stays interactive while combat is paused.
signal selected(index: int)
var panel: CenterContainer
var shade: ColorRect
var heading: Label
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
	var footer: Label = Label.new()
	footer.text = "1 / 2 / 3 or click to choose • Arrows / Enter also work\nBonuses last this run and add against base values. R restarts."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(footer)
	close()


func open(run: Node) -> void:
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
