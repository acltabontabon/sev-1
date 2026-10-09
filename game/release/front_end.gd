extends Node
## Own the application screens; Incident retains sole ownership of the run.
const INCIDENT: PackedScene = preload("res://game/incidents/missing_transaction.tscn")
const PREFERENCES: Script = preload("res://game/release/preferences.gd")
const CONTROLS: String = "WASD / arrows    Move relative to camera\nMouse / wheel    Look / zoom\nShift / Space    Sprint / jump\nLeft mouse / F    Light attack; press late to chain three hits\nQ / right mouse    Dodge; stationary dodges backward\nE    Inspect the nearby OPERATIONS console\n1 / 2 / 3    Select evidence or a decision\nTab    Skip opening / boss arrival\nR    Restart incident\nEscape    Pause / back\n\nFace the threat with the camera. Dodge orange warnings, then\nstrike during recovery. The boss is vulnerable during OPEN."
var preferences: RefCounted = PREFERENCES.new()
var session: Node3D
var page: String = "main"
var return_page: String = "main"
var overlay: CanvasLayer
var surface: ColorRect
var box: VBoxContainer
var save_notice: Label
var report_subtitle: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if "--release-smoke" in OS.get_cmdline_user_args():
		preferences.path = "user://smoke_nonexistent.cfg"
	preferences.load_settings()
	preferences.apply()
	overlay = CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)
	surface = ColorRect.new()
	surface.color = Color(.015, .028, .038, 1)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(surface)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 620)
	panel.add_theme_stylebox_override("panel", _style(Color(.025, .05, .065)))
	center.add_child(panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(920, 620)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	show_page("main")
	if "--release-smoke" in OS.get_cmdline_user_args():
		add_child(load("res://game/release/release_smoke.gd").new())


func _style(color: Color, focus: bool = false) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(9)
	style.set_corner_radius_all(4)
	if focus:
		style.set_border_width_all(3)
		style.border_color = Color(.55, .95, 1)
	return style


func _label(text: String, size: int = 20) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(.85, .93, .95))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	return label


func _button(text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.add_theme_font_size_override("font_size", 20)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, _style(Color(.045, .09, .11) if state == "normal" else Color(.09, .18, .21), state == "focus"))
	button.pressed.connect(action)
	box.add_child(button)
	return button


func show_page(next: String) -> void:
	page = next
	report_subtitle = null
	if session != null:
		session.get_node("Incident/Voice").set_presentation_state(page, preferences.values.subtitles)
	for child: Node in box.get_children():
		box.remove_child(child)
		child.queue_free()
	surface.visible = not page.is_empty()
	if session != null:
		session.get_node("Player/CameraRig").set_process_unhandled_input(page.is_empty())
		var choice: CanvasLayer = session.get_node("Incident").upgrade_ui
		choice.visible = page.is_empty()
		choice.set_process_input(page.is_empty())
		if page.is_empty() and session.get_node("Incident").modal_pending():
			choice.buttons[0].grab_focus()
	if page.is_empty():
		return
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	match page:
		"main":
			_label("FRIDAY DEPLOYMENT  /  VERTICAL SLICE 0.1", 17)
			_label("SEV-1", 72)
			_label("Works on My Machine", 28)
			_label("The system is down. Management is watching.\n\nIncident 001 — The Missing Transaction", 20)
			_button("Start Incident", start_incident)
			_button("Controls", open_controls)
			_button("Settings", open_settings)
			_button("Credits & licenses", func() -> void: show_page("credits"))
			_button("Quit", quit_game)
		"pause":
			_label("INCIDENT ON HOLD", 32)
			_label("Production can wait while you take a breath.")
			_button("Resume", resume_incident)
			_button("Controls", open_controls)
			_button("Settings", open_settings)
			_button("Restart Incident", restart_incident)
			_button("Return to Main Menu", main_menu)
			_button("Quit", quit_game)
		"report":
			_label(session.get_node("Incident").report.replace("\n\n", "\n"), 17)
			report_subtitle = _label("", 19)
			report_subtitle.custom_minimum_size.y = 68
			var actions: HBoxContainer = HBoxContainer.new()
			actions.add_theme_constant_override("separation", 12)
			box.add_child(actions)
			for entry: Array in [["Restart Incident", restart_incident], ["Return to Main Menu", main_menu], ["Quit", quit_game]]:
				var button: Button = _button(entry[0], entry[1])
				button.reparent(actions)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		"controls":
			_label("CONTROLS", 32)
			_label(CONTROLS)
			_button("Back", go_back)
		"settings":
			_label("SETTINGS", 32)
			_slider("Master volume", "master", 0, 1, .05)
			_slider("Effects & office ambience", "effects", 0, 1, .05)
			_slider("Voice volume", "voice", 0, 1, .05)
			_toggle("Subtitles", "subtitles")
			_slider("Mouse sensitivity", "sensitivity", .2, 3, .1)
			_slider("Camera shake", "shake", 0, 1, .1)
			_toggle("Damage flash", "flash")
			_toggle("Fullscreen", "fullscreen")
			var quality: OptionButton = OptionButton.new()
			quality.add_item("Reduced effects — no SSAO, glow or MSAA")
			quality.add_item("Standard — SSAO, glow and MSAA 2×")
			quality.selected = preferences.values.quality
			quality.custom_minimum_size.y = 42
			quality.item_selected.connect(func(index: int) -> void: change_setting("quality", index))
			box.add_child(quality)
			save_notice = _label("Saved locally. No run progress is saved. No music track is used.", 16)
			_button("Back", go_back)
		"credits":
			_label("SEV-1 / CREDITS", 32)
			_label("Created by MayhemProd with AI-assisted code, native geometry and synthesized sound.\n\nVisuals and effects are original procedural work. Authored speech uses local Kokoro synthesis; see the bundled voice provenance and license notices. Character motion, office props and audio remain provisional.\n\nMade with Godot Engine (MIT). Engine and bundled third-party license notices accompany this build in THIRD_PARTY_NOTICES.txt.\n\nNo runtime AI, telemetry or online account is used.")
			_button("Back", func() -> void: show_page("main"))
	for child: Node in box.find_children("*", "Control", true, false):
		if child.focus_mode == Control.FOCUS_ALL:
			child.grab_focus()
			break


func _slider(title: String, key: String, low: float, high: float, step: float) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.custom_minimum_size.x = 360
	label.add_theme_font_size_override("font_size", 20)
	label.text = "%s  %.2f" % [title, preferences.values[key]]
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = preferences.values[key]
	slider.custom_minimum_size.y = 38
	row.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void:
		label.text = "%s  %.2f" % [title, value]
		change_setting(key, value))
	box.add_child(row)


func _toggle(title: String, key: String) -> void:
	var toggle: CheckButton = CheckButton.new()
	toggle.text = title
	toggle.add_theme_font_size_override("font_size", 20)
	toggle.button_pressed = preferences.values[key]
	toggle.toggled.connect(func(value: bool) -> void: change_setting(key, value))
	box.add_child(toggle)


func change_setting(key: String, value: Variant) -> void:
	preferences.values[key] = value
	preferences.apply(session)
	if preferences.save_settings() != OK and is_instance_valid(save_notice):
		save_notice.text = "Could not save preferences. Changes apply for this session only."


func start_incident() -> void:
	if session != null:
		return
	session = INCIDENT.instantiate()
	add_child(session)
	session.get_node("HUD").configure_release_ui()
	preferences.apply(session)
	resume_incident()


func resume_incident() -> void:
	show_page("")
	if not session.get_node("Incident").modal_pending():
		session.get_node("Player/CameraRig").set_capture(true)


func pause_incident() -> void:
	session.get_node("Player/CameraRig").set_capture(false)
	show_page("pause")


func restart_incident() -> void:
	session.reset_encounter()
	preferences.apply(session)
	resume_incident()


func main_menu() -> void:
	if session != null:
		remove_child(session)
		session.queue_free()
		session = null
	show_page("main")


func open_controls() -> void:
	return_page = page
	show_page("controls")


func open_settings() -> void:
	return_page = page
	show_page("settings")


func go_back() -> void:
	show_page(return_page)


func quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()


func _process(_delta: float) -> void:
	if is_instance_valid(report_subtitle) and session != null:
		report_subtitle.text = session.get_node("Incident/Voice").subtitle
	if session != null and page.is_empty():
		var incident: Node = session.get_node("Incident")
		if incident.terminal():
			show_page("report")
		elif not incident.modal_pending() and not session.get_node("Player/CameraRig").controls_active:
			show_page("pause")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse") and not event.is_echo():
		get_viewport().set_input_as_handled()
		match page:
			"": pause_incident()
			"pause": resume_incident()
			"controls", "settings": go_back()
			"credits": show_page("main")
	elif not page.is_empty() and event.is_action_pressed("reset_player"):
		get_viewport().set_input_as_handled()
		if session != null and page in ["pause", "report"] and not event.is_echo():
			restart_incident()
