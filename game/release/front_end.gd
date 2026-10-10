extends Node
## Own the application screens; Incident retains sole ownership of the run.
const INCIDENT: PackedScene = preload("res://game/incidents/missing_transaction.tscn")
const PREFERENCES: Script = preload("res://game/release/preferences.gd")
const BACKDROP: PackedScene = preload("res://game/release/menu_backdrop.tscn")
const CONTROLS: String = "WASD / arrows      Move relative to camera\nMouse / wheel      Look / zoom\nShift / Space      Sprint / jump\nLeft mouse / F     Light attack; press late to chain three hits\nQ / right mouse    Dodge; stationary dodges backward\nC / middle mouse   Reply All: a crescent that hits everyone in line\nX / dodge + attack Blame Shift: dash through; they take +30% for 4 s\nZ                  Circle Back: fire whirlwind; survivors parked\nG                  Works On My Machine: counter stance (time it)\nV                  Force Rollback (ultimate, when FOCUS is full)\nE                  Inspect the nearby OPERATIONS console\n1 / 2 / 3          Select evidence or a decision\nTab                Skip opening (after first viewing) / boss arrival\nR                  Restart incident\nEscape             Pause / back\n\nFace the threat with the camera. Dodge orange warnings, then\nstrike during recovery. The boss is vulnerable during OPEN."
const KEYS: Array = [
	[["W", "A", "S", "D"], "Move, relative to the camera"], [["MOUSE"], "Look  ·  wheel zooms"],
	[["SHIFT"], "Sprint"], [["SPACE"], "Jump"],
	[["LMB", "F"], "Attack  ·  press late in recovery to chain three hits"],
	[["Q", "RMB"], "Dodge  ·  no direction dodges backward"],
	[["C", "MMB"], "Reply All  ·  a crescent that hits everyone in line"],
	[["X"], "Blame Shift  ·  dash through enemies; the blamed take +30% (or attack out of a dodge)"],
	[["Z"], "Circle Back  ·  a fire whirlwind; the last pulse parks survivors"],
	[["G"], "Works On My Machine  ·  counter stance: get hit in it and they take the blame"],
	[["V"], "Force Rollback  ·  ultimate; landing hits fills FOCUS"],
	[["E"], "Use: the console, the coffee machine, everything else"],
	[["1", "2", "3"], "Choose evidence, change requests and replies"],
	[["TAB"], "Skip the opening (after first viewing) or the boss arrival"],
	[["R"], "Restart the incident"], [["ESC"], "Pause  ·  back"]]
const FIELD_NOTES: Array[String] = [
	"Monsters start as coworkers. Follow ▼ to the one acting strange: talk, hover or hit first.",
	"Monsters only chase what they see, or whoever hits them. Sneak up for double damage.",
	"Orange arc: an attack is coming. Dodge aside, then counter during recovery.",
	"Bugs die in one hit. The Blocker shields friends: hit it mid-cast or take it down first.",
	"Meeting zones start after a countdown. Scope Creep grows if ignored; any hit resets it.",
	"The Variance only takes damage while OPEN. Trust the solid ◆."]
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
var stamps: Array[Label] = []


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
	surface.material = ShaderMaterial.new()
	surface.material.shader = preload("res://game/ui/frosted.gdshader")
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
	scroll.follow_focus = true
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


func _layout(title_page: bool, report: bool = false) -> void:
	vignette.visible = title_page
	footer.visible = title_page
	hint.visible = title_page
	# Paused or reporting, the incident stays visible behind frosted glass.
	surface.color = Color(0, 0, 0, 0) if title_page else Color(.005, .01, .015, .62)
	surface.material.set_shader_parameter("blur", 0.0 if title_page else (1.2 if report else 3.5))
	surface.material.set_shader_parameter("tint", Color(.01, .015, .02, 0.0 if title_page else (.35 if report else .66)))
	if title_page:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		panel.offset_left = 72
		panel.offset_right = 72 + 640
		panel.offset_top = 44
		panel.offset_bottom = -64
	elif report:
		# The postmortem is a document on the right; the ending shot stays visible left.
		surface.color = Color(.005, .01, .015, .25)
		panel.remove_theme_stylebox_override("panel")
		panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		panel.offset_left = -640
		panel.offset_right = -36
		panel.offset_top = 36
		panel.offset_bottom = -36
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
	_layout(page == "main", page == "report")
	for stamp: Label in stamps:
		stamp.queue_free()
	stamps.clear()
	quiet = true
	match page:
		"main":
			_label("INCIDENT 001  ·  THE MISSING TRANSACTION", 0, "Eyebrow")
			var logo: Label = _label("SEV-1", 128, "DisplayTitle")
			logo.add_theme_constant_override("line_spacing", -30)
			# A faint alarm scanline keeps sweeping the logo, like a monitor that knows.
			var scan: ColorRect = ColorRect.new()
			scan.color = Color(1, .25, .15, .45)
			scan.size = Vector2(300, 2)
			scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
			logo.add_child(scan)
			var sweep: Tween = scan.create_tween().set_loops()
			sweep.tween_property(scan, "position:y", 150.0, 2.6).from(14.0).set_trans(Tween.TRANS_SINE)
			sweep.tween_property(scan, "modulate:a", 0.0, .3)
			sweep.tween_interval(1.4)
			sweep.tween_property(scan, "modulate:a", 1.0, .01)
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
			var warning: HBoxContainer = HBoxContainer.new()
			warning.add_theme_constant_override("separation", 14)
			box.add_child(warning)
			var sign: PanelContainer = PanelContainer.new()
			var round: StyleBoxFlat = StyleBoxFlat.new()
			round.bg_color = Color(1, .7, .2)
			round.set_corner_radius_all(24)
			sign.add_theme_stylebox_override("panel", round)
			sign.custom_minimum_size = Vector2(48, 48)
			sign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var bang: Label = Label.new()
			bang.text = "!"
			bang.theme_type_variation = "Headline"
			bang.add_theme_color_override("font_color", Color(.06, .05, .03))
			bang.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bang.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sign.add_child(bang)
			warning.add_child(sign)
			var words: VBoxContainer = VBoxContainer.new()
			warning.add_child(words)
			var asked: Label = Label.new()
			asked.text = "SESSION  ·  END REQUESTED"
			asked.theme_type_variation = "Eyebrow"
			words.add_child(asked)
			var question: Label = Label.new()
			question.text = "Attempt to log off?"
			question.theme_type_variation = "Headline"
			words.add_child(question)
			_label("You have 1 unresolved SEV-1.\nYour status will be set to: Away (Guilty).\nLeadership will be notified that you “stepped away”.", 0, "Subhead")
			_space(12)
			_entry("Log Off Anyway", "Quit the game", quit_game)
			_entry("Stay", "Back", go_back)
		"report":
			var incident: Node = session.get_node("Incident")
			var won: bool = incident.stage == incident.Stage.RESOLVED
			_label("POSTMORTEM  ·  INC-001  ·  BLAMELESS FORMAT  ·  v1 (final) (2)", 0, "Eyebrow")
			_label("Incident 001 — %s" % ("Resolved" if won else "Reopened"), 0, "Headline")
			# Actions first: the document can be long, the way out never is.
			var actions: HBoxContainer = HBoxContainer.new()
			actions.add_theme_constant_override("separation", 10)
			box.add_child(actions)
			for entry: Array in [["Restart Incident", restart_incident], ["Back to Desk", main_menu], ["Attempt to Log Off", open_logoff]]:
				var button: Button = _button(entry[0], entry[1])
				button.reparent(actions)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			report_subtitle = _label("", 17)
			report_subtitle.custom_minimum_size.y = 52
			_label("IMPACT", 0, "Eyebrow")
			_report_meter("Tech debt at close", incident.run.debt, incident.run.debt_limit, Color(1, .55, .25), incident.run.severity())
			_report_meter("Peak Burnout", incident.run.peak_burnout, incident.run.burnout_limit, Color(1, .4, .3), incident.run.burnout_title(incident.run.peak_burnout))
			_report_meter("Threats reconciled", incident.enemies_defeated, maxi(incident.enemies_defeated, 12), Color(.4, .9, .85), "of the incident")
			_label("TIMELINE", 0, "Eyebrow")
			var events: PackedStringArray = []
			for entry: Array in incident.timeline:
				events.append("%02d:%02d   %s" % [int(entry[0]) / 60, int(entry[0]) % 60, entry[1]])
			_label("\n".join(events) if not events.is_empty() else "No events recorded.", 13, "MonoLabel").add_theme_color_override("font_color", Color(.78, .88, .9))
			_label("DETAILS", 0, "Eyebrow")
			_label(incident.report.replace("\n\n", "\n"), 13, "MonoLabel")
			_stamp("BLAMELESS" if won else "REOPENED", Color(.35, .95, .65) if won else Color(1, .45, .3), .7, Vector2(-250, 330), -.12)
			_stamp("ASSIGNED: YOU", Color(1, .32, .2), 1.9, Vector2(-310, 470), .09)
		"controls":
			_label("WIKI  ·  LAST UPDATED: NEVER  ·  3 PEOPLE FOUND THIS HELPFUL", 0, "Eyebrow")
			_label("Onboarding Docs", 0, "Headline")
			# Two key columns leave room for the field notes and Back on one page.
			var grid: GridContainer = GridContainer.new()
			grid.columns = 4
			grid.add_theme_constant_override("h_separation", 18)
			grid.add_theme_constant_override("v_separation", 6)
			box.add_child(grid)
			for entry: Array in KEYS:
				var caps: HBoxContainer = HBoxContainer.new()
				caps.custom_minimum_size.x = 140
				caps.add_theme_constant_override("separation", 6)
				for key_name: String in entry[0]:
					caps.add_child(_keycap(key_name))
				grid.add_child(caps)
				var what: Label = Label.new()
				what.text = entry[1]
				what.add_theme_font_size_override("font_size", 15)
				what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				what.custom_minimum_size.x = 270
				what.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				grid.add_child(what)
			_space(6)
			_label("FIELD NOTES FROM THE PREVIOUS ON-CALL ENGINEER (LEFT THE COMPANY)", 0, "Eyebrow")
			# Two columns so every note and the Back button fit on one page.
			var notes: GridContainer = GridContainer.new()
			notes.columns = 2
			notes.add_theme_constant_override("h_separation", 28)
			notes.add_theme_constant_override("v_separation", 4)
			box.add_child(notes)
			for note: String in FIELD_NOTES:
				var line: Label = Label.new()
				line.text = "—  " + note
				line.theme_type_variation = "Caption"
				line.add_theme_font_size_override("font_size", 14)
				line.add_theme_color_override("font_color", Color(.8, .86, .88))
				line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				line.custom_minimum_size.x = 420
				notes.add_child(line)
			_button("Back", go_back)
		"settings":
			_label("DEVICE POLICY  ·  HR IS NOT NOTIFIED", 0, "Eyebrow")
			_label("Corporate Policy", 0, "Headline")
			_slider("Master volume", "master", 0, 1, .05)
			_slider("Effects & office ambience", "effects", 0, 1, .05)
			_slider("Voice volume", "voice", 0, 1, .05)
			_slider("Music volume", "music", 0, 1, .05)
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


func _keycap(text: String) -> PanelContainer:
	var cap: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(.12, .15, .17)
	style.border_color = Color(.32, .4, .44)
	style.set_border_width_all(1)
	style.border_width_bottom = 3
	style.set_corner_radius_all(5)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	cap.add_theme_stylebox_override("panel", style)
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = "MonoLabel"
	label.add_theme_font_size_override("font_size", 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_child(label)
	cap.custom_minimum_size.x = 34
	return cap


func _report_meter(title: String, value: int, limit: int, color: Color, note: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var name_label: Label = Label.new()
	name_label.text = title
	name_label.custom_minimum_size.x = 170
	name_label.add_theme_font_size_override("font_size", 14)
	row.add_child(name_label)
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maxi(limit, 1)
	bar.value = value
	bar.custom_minimum_size = Vector2(200, 10)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var back: StyleBoxFlat = StyleBoxFlat.new()
	back.bg_color = Color(.1, .12, .14)
	back.set_corner_radius_all(3)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	var number: Label = Label.new()
	number.text = "%d  %s" % [value, note]
	number.theme_type_variation = "MonoLabel"
	number.add_theme_font_size_override("font_size", 13)
	row.add_child(number)


## A rubber stamp that lands on the postmortem after a beat, with a thump.
func _stamp(text: String, color: Color, delay: float, at: Vector2, tilt: float) -> void:
	var stamp: Label = Label.new()
	stamp.text = text
	stamp.theme_type_variation = "Headline"
	stamp.add_theme_font_size_override("font_size", 46)
	stamp.add_theme_color_override("font_color", color)
	stamp.add_theme_constant_override("outline_size", 3)
	stamp.add_theme_color_override("font_outline_color", color)
	stamp.position = Vector2(surface.size.x + at.x, at.y)
	stamp.rotation = tilt
	stamp.pivot_offset = Vector2(120, 30)
	stamp.modulate.a = 0.0
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(stamp)
	stamps.append(stamp)
	var land: Tween = stamp.create_tween()
	land.tween_interval(delay)
	land.tween_callback(func() -> void:
		stamp.scale = Vector2.ONE * 2.2
		_play(preload("res://assets/audio/sfx/heavy_impact.ogg")))
	land.tween_property(stamp, "modulate:a", .9, .08)
	land.parallel().tween_property(stamp, "scale", Vector2.ONE, .14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
