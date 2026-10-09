extends Node
## Own the application screens; Incident retains sole ownership of the run.
const INCIDENT: PackedScene = preload("res://game/incidents/missing_transaction.tscn")
const PREFERENCES: Script = preload("res://game/release/preferences.gd")
const BACKDROP: PackedScene = preload("res://game/release/menu_backdrop.tscn")
const CONTROLS: String = "WASD / arrows      Move relative to camera\nMouse / wheel      Look / zoom\nShift / Space      Sprint / jump\nLeft mouse / F     Light attack; press late to chain three hits\nQ / right mouse    Dodge; stationary dodges backward\nE                  Inspect the nearby OPERATIONS console\n1 / 2 / 3          Select evidence or a decision\nTab                Skip opening (after first viewing) / boss arrival\nR                  Restart incident\nEscape             Pause / back\n\nFace the threat with the camera. Dodge orange warnings, then\nstrike during recovery. The boss is vulnerable during OPEN."
var preferences: RefCounted = PREFERENCES.new()
var session: Node3D
var backdrop: Node3D
var page: String = "main"
var return_page: String = "main"
var overlay: CanvasLayer
var surface: ColorRect
var vignette: TextureRect
var panel: PanelContainer
var box: VBoxContainer
var footer: Label
var hint: Label
var save_notice: Label
var report_subtitle: Label
var ui_sound: AudioStreamPlayer
var quiet: bool = false


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
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(surface)
	# The title reads over the dark half of the office; the desk stays clear on the right.
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(.008, .012, .018, .92))
	gradient.set_color(1, Color(.008, .012, .018, 0))
	gradient.set_offset(1, .62)
	var shade: GradientTexture2D = GradientTexture2D.new()
	shade.gradient = gradient
	vignette = TextureRect.new()
	vignette.texture = shade
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_child(vignette)
	panel = PanelContainer.new()
	surface.add_child(panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	panel.add_child(scroll)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	footer = _corner_label(Control.PRESET_BOTTOM_LEFT, "BUILD %s  ·  FRIDAY DEPLOYMENT  ·  LOCAL TESTER BUILD" % ProjectSettings.get_setting("application/config/version"))
	hint = _corner_label(Control.PRESET_BOTTOM_RIGHT, "↑ ↓  NAVIGATE      ENTER  SELECT      ESC  BACK")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_sound = AudioStreamPlayer.new()
	ui_sound.bus = &"Effects"
	ui_sound.volume_db = -12
	add_child(ui_sound)
	_open_backdrop()
	show_page("main")
	if "--release-smoke" in OS.get_cmdline_user_args():
		add_child(load("res://game/release/release_smoke.gd").new())


func _corner_label(preset: int, text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = "Eyebrow"
	label.set_anchors_and_offsets_preset(preset)
	label.offset_left = -720 if preset == Control.PRESET_BOTTOM_RIGHT else 48
	label.offset_right = -48 if preset == Control.PRESET_BOTTOM_RIGHT else 720
	label.offset_top = -48
	label.offset_bottom = -24
	surface.add_child(label)
	return label


func _layout(title_page: bool) -> void:
	vignette.visible = title_page
	footer.visible = title_page
	hint.visible = title_page
	# Paused or reporting, the incident stays visible behind a dim glass panel.
	surface.color = Color(0, 0, 0, 0) if title_page else Color(.005, .01, .015, .62)
	if title_page:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		panel.offset_left = 72
		panel.offset_right = 72 + 640
		panel.offset_top = 44
		panel.offset_bottom = -64
	else:
		panel.remove_theme_stylebox_override("panel")
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.offset_left = -470
		panel.offset_right = 470
		panel.offset_top = -320
		panel.offset_bottom = 320


func _label(text: String, size: int = 0, variation: String = "") -> Label:
	var label: Label = Label.new()
	label.text = text
	if not variation.is_empty():
		label.theme_type_variation = variation
	if size > 0:
		label.add_theme_font_size_override("font_size", size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	return label


func _button(text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 46
	button.pressed.connect(func() -> void:
		_play(preload("res://assets/audio/sfx/ui_confirm.ogg"))
		action.call())
	button.focus_entered.connect(_play.bind(preload("res://assets/audio/sfx/ui_hover.ogg")))
	box.add_child(button)
	return button


## A primary in-world label and a plain secondary tag, so the joke never hides the function.
func _entry(text: String, plain: String, action: Callable) -> Button:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var button: Button = _button(text, action)
	button.reparent(row)
	button.theme_type_variation = "MenuEntry"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 48
	button.mouse_entered.connect(button.grab_focus)
	var sub: Label = Label.new()
	sub.text = plain.to_upper()
	sub.theme_type_variation = "MenuSub"
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sub)
	return button


func _space(height: float) -> void:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size.y = height
	box.add_child(spacer)


func _play(stream: AudioStream) -> void:
	if not quiet and DisplayServer.get_name() != "headless":
		ui_sound.stream = stream
		ui_sound.play()


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
	_layout(page == "main")
	quiet = true
	match page:
		"main":
			_label("INCIDENT 001  ·  THE MISSING TRANSACTION", 0, "Eyebrow")
			_label("SEV-1", 128, "DisplayTitle").add_theme_constant_override("line_spacing", -30)
			var bar: ColorRect = ColorRect.new()
			bar.color = Color(1, .3, .17)
			bar.custom_minimum_size = Vector2(132, 5)
			bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			box.add_child(bar)
			_label("Works on My Machine", 26, "Subhead")
			_space(22)
			_entry("Acknowledge Incident", "New run", start_incident)
			_entry("Corporate Policy", "Settings", open_settings)
			_entry("Onboarding Docs", "Controls", open_controls)
			_entry("Legal Has Reviewed This", "Credits & licenses", func() -> void: show_page("credits"))
			_entry("Attempt to Log Off", "Quit", open_logoff)
		"pause":
			_label("INC-001  ·  STATUS: ON HOLD", 0, "Eyebrow")
			_label("Incident on hold", 0, "Headline")
			_label("Production is still down. It will wait. Probably.", 0, "Caption")
			_space(8)
			_entry("Resume Suffering", "Resume", resume_incident)
			_entry("Onboarding Docs", "Controls", open_controls)
			_entry("Corporate Policy", "Settings", open_settings)
			_entry("Restart Incident", "Back to Friday, 4:59 PM", restart_incident)
			_entry("Back to Desk", "Main menu", main_menu)
			_entry("Attempt to Log Off", "Quit", open_logoff)
		"logoff":
			_label("SESSION  ·  END REQUESTED", 0, "Eyebrow")
			_label("Attempt to log off?", 0, "Headline")
			_label("You have 1 unresolved SEV-1.\nYour status will be set to: Away (Guilty).", 0, "Subhead")
			_space(12)
			_entry("Log Off Anyway", "Quit the game", quit_game)
			_entry("Stay", "Back", go_back)
		"report":
			_label(session.get_node("Incident").report.replace("\n\n", "\n"), 17, "MonoLabel")
			report_subtitle = _label("", 19)
			report_subtitle.custom_minimum_size.y = 68
			var actions: HBoxContainer = HBoxContainer.new()
			actions.add_theme_constant_override("separation", 12)
			box.add_child(actions)
			for entry: Array in [["Restart Incident", restart_incident], ["Back to Desk", main_menu], ["Attempt to Log Off", open_logoff]]:
				var button: Button = _button(entry[0], entry[1])
				button.reparent(actions)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		"controls":
			_label("WIKI  ·  LAST UPDATED: NEVER", 0, "Eyebrow")
			_label("Onboarding Docs", 0, "Headline")
			_label(CONTROLS, 0, "MonoLabel")
			_button("Back", go_back)
		"settings":
			_label("DEVICE POLICY  ·  HR IS NOT NOTIFIED", 0, "Eyebrow")
			_label("Corporate Policy", 0, "Headline")
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
			save_notice = _label("Saved locally. No run progress is saved.", 15, "Caption")
			_button("Back", go_back)
		"credits":
			_label("COMPLIANCE  ·  APPROVED WITHOUT READING", 0, "Eyebrow")
			_label("Legal Has Reviewed This", 0, "Headline")
			_label("Created by MayhemProd with AI-assisted code, native geometry and synthesized sound.\n\nAuthored speech uses local Kokoro synthesis; see the bundled voice provenance and license notices. Interface and effect sounds by Kenney (kenney.nl, CC0). Typefaces: Barlow Condensed, Inter and JetBrains Mono (SIL Open Font License 1.1). Character motion and office props remain provisional.\n\nMade with Godot Engine (MIT). Engine and bundled third-party license notices accompany this build in THIRD_PARTY_NOTICES.txt.\n\nNo runtime AI, telemetry or online account is used.")
			_button("Back", func() -> void: show_page("main"))
	for child: Node in box.find_children("*", "Control", true, false):
		if child.focus_mode == Control.FOCUS_ALL:
			child.grab_focus()
			break
	quiet = false


func _slider(title: String, key: String, low: float, high: float, step: float) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.custom_minimum_size.x = 360
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
	toggle.button_pressed = preferences.values[key]
	toggle.toggled.connect(func(value: bool) -> void: change_setting(key, value))
	box.add_child(toggle)


func change_setting(key: String, value: Variant) -> void:
	preferences.values[key] = value
	preferences.apply(session)
	if preferences.save_settings() != OK and is_instance_valid(save_notice):
		save_notice.text = "Could not save preferences. Changes apply for this session only."


func _open_backdrop() -> void:
	if backdrop == null:
		backdrop = BACKDROP.instantiate()
		add_child(backdrop)


func _close_backdrop() -> void:
	# Leave the tree now so its camera and environment never overlap the incident's.
	if backdrop != null:
		remove_child(backdrop)
		backdrop.queue_free()
		backdrop = null


func start_incident() -> void:
	if session != null:
		return
	_close_backdrop()
	session = INCIDENT.instantiate()
	add_child(session)
	session.get_node("HUD").configure_release_ui()
	preferences.apply(session)
	# The opening may be skipped only once this device has seen it in full.
	session.get_node("Incident").presentation.skip_unlocked = preferences.values.opening_seen
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
	_open_backdrop()
	show_page("main")


func open_controls() -> void:
	return_page = page
	show_page("controls")


func open_settings() -> void:
	return_page = page
	show_page("settings")


func open_logoff() -> void:
	return_page = page
	_play(preload("res://assets/audio/sfx/ui_error.ogg"))
	show_page("logoff")


func go_back() -> void:
	_play(preload("res://assets/audio/sfx/ui_back.ogg"))
	show_page(return_page)


func quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()


func _process(_delta: float) -> void:
	if is_instance_valid(report_subtitle) and session != null:
		report_subtitle.text = session.get_node("Incident/Voice").subtitle
	if session != null:
		var story: CanvasLayer = session.get_node("Incident").presentation
		if story.opening_seen and not preferences.values.opening_seen:
			preferences.values.opening_seen = true
			preferences.save_settings()
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
			"controls", "settings", "logoff": go_back()
			"credits": show_page("main")
	elif not page.is_empty() and event.is_action_pressed("reset_player"):
		get_viewport().set_input_as_handled()
		if session != null and page in ["pause", "report"] and not event.is_echo():
			restart_incident()
