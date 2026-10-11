extends Node
## Own the application screens; Incident retains sole ownership of the run.
const INCIDENT: PackedScene = preload("res://game/incidents/missing_transaction.tscn")
const CHAPTER_PROGRESS: Script = preload("res://game/release/chapter_progress.gd")
const PREFERENCES: Script = preload("res://game/release/preferences.gd")
const BACKDROP: PackedScene = preload("res://game/release/menu_backdrop.tscn")
## The campaign's six circles (docs/game_design.md). Only Circle I, Incident 001, is built;
## the rest are listed honestly as not yet playable, never as unlockable.
const CIRCLES: Array[String] = ["The Reconciliation Abyss", "The Process Purgatory", "The Priority Paradox", "The Shared Environment", "The Assumption Engine", "Production: The Final Incident"]
const NUMERALS: Array[String] = ["I", "II", "III", "IV", "V", "VI"]
## Each description stays on one line so both columns and the field notes fit at 720p.
const KEYS: Array = [
	[["W", "A", "S", "D"], "Move, relative to the camera"], [["MOUSE"], "Look  ·  wheel zooms"],
	[["SHIFT"], "Sprint"], [["SPACE"], "Jump"],
	[["LMB", "F"], "Attack  ·  press late to chain three hits"],
	[["Q", "RMB"], "Dodge  ·  no direction dodges back"],
	[["C", "MMB"], "Reply All  ·  crescent through a line"],
	[["X"], "Blame Shift  ·  dash slash, +30% damage"],
	[["Z"], "Circle Back  ·  fire whirlwind"],
	[["G"], "Works On My Machine  ·  counter"],
	[["V"], "Force Rollback  ·  ultimate at full FOCUS"],
	[["E"], "Talk  ·  use objects"],
	[["1", "2", "3"], "Choose replies and upgrades"],
	[["TAB"], "Skip a scene you have seen"],
	[["R"], "Restart the incident"], [["ESC"], "Pause  ·  back"]]
const FIELD_NOTES: Array[String] = [
	"Monsters start as coworkers. Follow ▼ to the one acting strange.",
	"Monsters chase only what they see. Sneak attacks deal double.",
	"Orange arc: an attack is coming. Dodge, then hit the recovery.",
	"Bugs die in one hit. Break the Blocker's cast or take it out first.",
	"Meeting zones arm after a countdown. Hit Scope Creep before it grows.",
	"The Variance only takes damage while OPEN. Trust the solid ◆."]
## The default window (project.godot) shrinks to fit smaller displays, never below this.
const MIN_WINDOW: Vector2i = Vector2i(960, 540)
var progress: RefCounted = CHAPTER_PROGRESS.new()
var completion_attempted: bool = false
var progress_notice: String = ""
var preferences: RefCounted = PREFERENCES.new()
var session: Node3D
var backdrop: Node3D
var page: String = "main"
var return_page: String = "main"
var overlay: CanvasLayer
var surface: ColorRect
var vignette: TextureRect
var panel: PanelContainer
var scroll: ScrollContainer
var box: VBoxContainer
var footer: Label
var save_notice: Label
## Dialog pages size the panel to their content and keep it centered.
var fit_dialog: bool = false
var report_subtitle: Label
var ui_sound: AudioStreamPlayer
var quiet: bool = false
var stamps: Array[Label] = []
var previous_frame_limit: int = 0
var applied_frame_limit: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	previous_frame_limit = Engine.max_fps
	if "--release-smoke" in OS.get_cmdline_user_args():
		preferences.path = "user://smoke_nonexistent.cfg"
	# Isolate automated/preview sessions from the player's chapter save.
	if preferences.path != "user://settings.cfg":
		progress.path = preferences.path + ".chapters.json"
	progress.load_progress()
	preferences.load_settings()
	_fit_window()
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
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	# Wrapped labels settle their height a frame late; refit so dialogs never keep a stale size.
	panel.minimum_size_changed.connect(func() -> void:
		if fit_dialog:
			_center_panel.call_deferred())
	surface.add_child(panel)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	footer = Label.new()
	footer.text = "v%s  ·  EARLY BUILD" % ProjectSettings.get_setting("application/config/version")
	footer.theme_type_variation = "Eyebrow"
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.offset_left = 72
	footer.offset_right = 600
	footer.offset_top = -44
	footer.offset_bottom = -22
	surface.add_child(footer)
	ui_sound = AudioStreamPlayer.new()
	ui_sound.bus = &"Effects"
	ui_sound.volume_db = -12
	add_child(ui_sound)
	_open_backdrop()
	show_page("main")
	if "--release-smoke" in OS.get_cmdline_user_args():
		add_child(load("res://game/release/release_smoke.gd").new())


## Title pages float over the live desk; the report is a document on the right;
## every other page is a centered dialog sized to its content at the given width.
func _layout(mode: String, width: float = 0.0) -> void:
	var title_page: bool = mode == "title"
	vignette.visible = title_page
	footer.visible = page == "main"
	fit_dialog = mode == "dialog"
	box.custom_minimum_size.x = width
	# Dialogs grow to fit their content; the title and report scroll if they must.
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if fit_dialog else ScrollContainer.SCROLL_MODE_SHOW_NEVER
	# Paused or reporting, the incident stays visible behind frosted glass.
	surface.color = Color(0, 0, 0, 0) if title_page else Color(.005, .01, .015, .62)
	surface.material.set_shader_parameter("blur", 0.0 if title_page else (1.2 if mode == "report" else 3.5))
	surface.material.set_shader_parameter("tint", Color(.01, .015, .02, 0.0 if title_page else (.35 if mode == "report" else .66)))
	if title_page:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		panel.offset_left = 72
		panel.offset_right = 72 + 640
		panel.offset_top = 64
		panel.offset_bottom = -64
	elif mode == "report":
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
		_center_panel()


func _center_panel() -> void:
	# Zero offsets at the center anchor; the minimum size then grows it evenly both ways.
	if fit_dialog:
		panel.offset_left = 0
		panel.offset_right = 0
		panel.offset_top = 0
		panel.offset_bottom = 0


## The default 1600×900 window is in display points: macOS Retina screens report pixels
## at 2×, so it is scaled up there, then kept 16:9 within 90% of a smaller display.
func _fit_window() -> void:
	if DisplayServer.get_name() == "headless" or DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var screen: int = DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return
	var scale: float = maxf(DisplayServer.screen_get_scale(screen), 1.0)
	var minimum: Vector2i = Vector2i(Vector2(MIN_WINDOW) * scale)
	DisplayServer.window_set_min_size(minimum)
	var wanted: Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/window_width_override"), ProjectSettings.get_setting("display/window/size/window_height_override")) * scale
	var fit: float = minf(1.0, minf(usable.size.x * .9 / wanted.x, usable.size.y * .9 / wanted.y))
	var window: Vector2i = Vector2i((wanted * fit).round()).max(minimum)
	if window != DisplayServer.window_get_size():
		DisplayServer.window_set_size(window)
		DisplayServer.window_set_position(usable.position + (usable.size - window) / 2)


func _header(eyebrow: String, headline: String) -> void:
	_label(eyebrow, 0, "Eyebrow")
	_label(headline, 0, "Headline")


func _section(text: String, parent: Container) -> void:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = "Eyebrow"
	parent.add_child(label)


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


## A large menu entry with an optional small status tag beside it.
func _entry(text: String, action: Callable, tag: String = "", parent: Container = null) -> Button:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	(box if parent == null else parent).add_child(row)
	var button: Button = _button(text, action)
	button.reparent(row)
	button.theme_type_variation = "MenuEntry"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 48
	button.mouse_entered.connect(button.grab_focus)
	if not tag.is_empty():
		var sub: Label = Label.new()
		sub.text = tag.to_upper()
		sub.theme_type_variation = "MenuSub"
		sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sub)
	return button


## Save problems appear only when something needs the player's attention.
func _progress_notices() -> void:
	for notice: String in [progress.load_notice, progress_notice]:
		if not notice.is_empty():
			_label(notice, 0, "Caption")
	if not progress_notice.is_empty():
		_entry("Retry Save", retry_progress_save)


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
	match page:
		"main", "campaign": _layout("title")
		"report": _layout("report")
		"settings": _layout("dialog", 860)
		"controls": _layout("dialog", 900)
		"credits": _layout("dialog", 720)
		"logoff", "tester_unlock": _layout("dialog", 560)
		_: _layout("dialog", 320)
	for stamp: Label in stamps:
		stamp.queue_free()
	stamps.clear()
	quiet = true
	match page:
		"main":
			var logo: Label = _label("SEV-1", 128, "DisplayTitle")
			logo.add_theme_constant_override("line_spacing", -30)
			var bar: ColorRect = ColorRect.new()
			bar.color = Color(1, .3, .17)
			bar.custom_minimum_size = Vector2(132, 5)
			bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			box.add_child(bar)
			_label("Works on My Machine", 26, "Subhead")
			_space(28)
			_entry("Play", func() -> void: show_page("campaign"))
			_entry("Settings", open_settings)
			_entry("Controls", open_controls)
			_entry("Credits", func() -> void: show_page("credits"))
			_entry("Quit", open_logoff)
			_progress_notices()
		"campaign":
			_header("SIX CIRCLES OF CORPORATE HELL", "Campaign")
			_space(6)
			var circles: GridContainer = GridContainer.new()
			circles.columns = 2
			circles.add_theme_constant_override("h_separation", 6)
			circles.add_theme_constant_override("v_separation", 2)
			box.add_child(circles)
			for index: int in CIRCLES.size():
				var numeral: Label = Label.new()
				numeral.text = NUMERALS[index]
				numeral.theme_type_variation = "Eyebrow"
				numeral.custom_minimum_size.x = 30
				numeral.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				circles.add_child(numeral)
				if index == 0:
					_entry(CIRCLES[0], start_incident, "Incident 001  ·  Cleared" if progress.stage_one_completed else "Incident 001", circles)
				else:
					# Not yet built: shown so the scope is honest, never focusable.
					var locked: Label = Label.new()
					locked.text = CIRCLES[index]
					locked.theme_type_variation = "Headline"
					locked.add_theme_font_size_override("font_size", 34)
					var inset: StyleBoxEmpty = StyleBoxEmpty.new()
					inset.content_margin_left = 18
					locked.add_theme_stylebox_override("normal", inset)
					locked.custom_minimum_size.y = 48
					locked.modulate.a = .3
					circles.add_child(locked)
			_space(4)
			_label("Only Circle I is playable in this build. Circles II–VI are not built yet.", 0, "Caption")
			_progress_notices()
			_space(10)
			if not progress.stage_one_completed:
				_entry("Cleared Circle I in an older build?", func() -> void: show_page("tester_unlock")).add_theme_font_size_override("font_size", 22)
			_entry("Back", func() -> void: show_page("main"))
		"tester_unlock":
			_header("EARLIER TESTERS", "Record Circle I as cleared")
			_label("Finished Incident 001 in an older build? Record it here so this device remembers it. Nothing unfinished is unlocked.", 0, "Caption")
			_space(6)
			_entry("Mark Circle I Cleared", unlock_stage_one)
			_entry("Back", func() -> void: show_page("campaign"))
		"pause":
			_header("INCIDENT ON HOLD", "Paused")
			_space(6)
			_entry("Resume", resume_incident)
			_entry("Restart", restart_incident)
			_entry("Controls", open_controls)
			_entry("Settings", open_settings)
			_entry("Main Menu", main_menu)
			_entry("Quit", open_logoff)
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
			var question: Label = Label.new()
			question.text = "Attempt to log off?"
			question.theme_type_variation = "Headline"
			question.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			warning.add_child(question)
			_label("You have 1 unresolved SEV-1.\nYour status will be set to: Away (Guilty).", 0, "Caption")
			_space(6)
			# The safe choice takes focus first.
			_entry("Stay", go_back)
			_entry("Log Off", quit_game)
		"report":
			var incident: Node = session.get_node("Incident")
			var won: bool = incident.stage == incident.Stage.RESOLVED
			_label("POSTMORTEM  ·  INC-001  ·  BLAMELESS FORMAT  ·  v1 (final) (2)", 0, "Eyebrow")
			_label("Incident 001 — %s" % ("Resolved" if won else "Reopened"), 0, "Headline")
			if won:
				_label("Circle I cleared. Progress saved." if progress.stage_one_completed else progress_notice, 0, "Caption")
			# Actions first: the document can be long, the way out never is.
			var actions: HBoxContainer = HBoxContainer.new()
			actions.add_theme_constant_override("separation", 10)
			box.add_child(actions)
			for entry: Array in [["Replay" if won else "Retry", restart_incident], ["Main Menu", main_menu], ["Quit", open_logoff]]:
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
			_header("ONBOARDING DOCS  ·  LAST UPDATED: NEVER", "Controls")
			var grid: GridContainer = GridContainer.new()
			grid.columns = 4
			grid.add_theme_constant_override("h_separation", 16)
			grid.add_theme_constant_override("v_separation", 8)
			box.add_child(grid)
			for entry: Array in KEYS:
				var caps: HBoxContainer = HBoxContainer.new()
				caps.custom_minimum_size.x = 136
				caps.add_theme_constant_override("separation", 6)
				for key_name: String in entry[0]:
					caps.add_child(_keycap(key_name))
				grid.add_child(caps)
				var what: Label = Label.new()
				what.text = entry[1]
				what.add_theme_font_size_override("font_size", 15)
				what.custom_minimum_size.x = 286
				what.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				grid.add_child(what)
			_space(4)
			_label("FIELD NOTES FROM THE PREVIOUS ON-CALL ENGINEER", 0, "Eyebrow")
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
				line.custom_minimum_size.x = 436
				notes.add_child(line)
			_space(4)
			_button("Back", go_back)
		"settings":
			_header("CORPORATE POLICY  ·  HR IS NOT NOTIFIED", "Settings")
			var columns: HBoxContainer = HBoxContainer.new()
			columns.add_theme_constant_override("separation", 44)
			box.add_child(columns)
			var left: VBoxContainer = VBoxContainer.new()
			var right: VBoxContainer = VBoxContainer.new()
			for column: VBoxContainer in [left, right]:
				column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				column.add_theme_constant_override("separation", 8)
				columns.add_child(column)
			_section("AUDIO", left)
			_slider("Master", "master", 0, 1, .05, left)
			_slider("Effects", "effects", 0, 1, .05, left)
			_slider("Voices", "voice", 0, 1, .05, left)
			_slider("Music", "music", 0, 1, .05, left)
			_toggle("Subtitles", "subtitles", left)
			_section("GAMEPLAY", right)
			_slider("Mouse speed", "sensitivity", .2, 3, .1, right)
			_slider("Camera shake", "shake", 0, 1, .1, right)
			_toggle("Damage flash", "flash", right)
			_section("DISPLAY", right)
			_toggle("Fullscreen", "fullscreen", right)
			var quality: OptionButton = OptionButton.new()
			quality.add_item("Reduced effects")
			quality.add_item("Standard effects")
			quality.selected = preferences.values.quality
			quality.tooltip_text = "Standard adds SSAO, glow and 2× MSAA."
			quality.item_selected.connect(func(index: int) -> void: change_setting("quality", index))
			right.add_child(quality)
			var frames: OptionButton = OptionButton.new()
			frames.add_item("60 FPS  ·  cooler, quieter")
			frames.add_item("120 FPS  ·  smoother")
			frames.selected = 1 if preferences.values.frame_limit == 120 else 0
			frames.item_selected.connect(func(index: int) -> void: change_setting("frame_limit", 120 if index == 1 else 60))
			right.add_child(frames)
			# Silent while saving works; shown only when this device cannot keep the changes.
			save_notice = _label("Could not save settings. Changes apply for this session only.", 15, "Caption")
			save_notice.visible = false
			_space(4)
			_button("Back", go_back)
		"credits":
			_header("LEGAL HAS REVIEWED THIS", "Credits")
			var credits: GridContainer = GridContainer.new()
			credits.columns = 2
			credits.add_theme_constant_override("h_separation", 24)
			credits.add_theme_constant_override("v_separation", 8)
			box.add_child(credits)
			for entry: Array in [
					["GAME", "MayhemProd, with AI-assisted code"],
					["CHARACTERS", "Quaternius; Kay Lousberg (KayKit); greatsword by Lucian Pavel. All CC0"],
					["ENVIRONMENT", "Poly Haven, ambientCG, Innerscene and Kenney. All CC0"],
					["SOUND", "Kenney (CC0); original synthesized effects and music"],
					["VOICES", "Local Kokoro synthesis (Apache-2.0 model)"],
					["TYPE", "Barlow Condensed, Inter, JetBrains Mono, Cinzel (SIL OFL 1.1)"],
					["ENGINE", "Godot Engine (MIT)"]]:
				var role: Label = Label.new()
				role.text = entry[0]
				role.theme_type_variation = "Eyebrow"
				role.custom_minimum_size.x = 120
				credits.add_child(role)
				var names: Label = Label.new()
				names.text = entry[1]
				names.add_theme_font_size_override("font_size", 16)
				names.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				names.custom_minimum_size.x = 560
				credits.add_child(names)
			_space(4)
			_label("Full license notices ship with this build in THIRD_PARTY_NOTICES.txt. No runtime AI, telemetry or online account is used.", 0, "Caption")
			_space(4)
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


func _slider(title: String, key: String, low: float, high: float, step: float, parent: Container) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label: Label = Label.new()
	label.text = title
	label.custom_minimum_size.x = 140
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = preferences.values[key]
	slider.custom_minimum_size.y = 34
	row.add_child(slider)
	var amount: Label = Label.new()
	amount.theme_type_variation = "MonoLabel"
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.custom_minimum_size.x = 52
	amount.text = _amount(key, slider.value)
	row.add_child(amount)
	slider.value_changed.connect(func(value: float) -> void:
		amount.text = _amount(key, value)
		change_setting(key, value))
	parent.add_child(row)


## Mouse speed reads as a multiplier; every other slider is a share of full.
func _amount(key: String, value: float) -> String:
	return "%.1f×" % value if key == "sensitivity" else "%d%%" % roundi(value * 100)


func _toggle(title: String, key: String, parent: Container) -> void:
	var toggle: CheckButton = CheckButton.new()
	toggle.text = title
	toggle.button_pressed = preferences.values[key]
	toggle.toggled.connect(func(value: bool) -> void: change_setting(key, value))
	parent.add_child(toggle)


func change_setting(key: String, value: Variant) -> void:
	preferences.values[key] = value
	preferences.apply(session)
	if preferences.save_settings() != OK and is_instance_valid(save_notice):
		save_notice.visible = true


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


func _save_progress() -> void:
	completion_attempted = true
	var result: Error = progress.complete_stage_one()
	progress_notice = "" if result == OK else "Could not save Stage One completion. Retry Save from the main menu before quitting."


func _record_completion() -> void:
	if session != null and not completion_attempted:
		var incident: Node = session.get_node("Incident")
		if incident.stage == incident.Stage.RESOLVED:
			_save_progress()


func unlock_stage_one() -> void:
	_save_progress()
	show_page("campaign")


func retry_progress_save() -> void:
	_save_progress()
	show_page(page)


func start_incident() -> void:
	if session != null:
		return
	completion_attempted = false
	_close_backdrop()
	session = INCIDENT.instantiate()
	add_child(session)
	session.get_node("Incident").presentation.finale_finished.connect(func() -> void: main_menu.call_deferred())
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
	_record_completion()
	completion_attempted = false
	session.reset_encounter()
	preferences.apply(session)
	resume_incident()


func main_menu() -> void:
	_record_completion()
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
	_record_completion()
	get_tree().paused = false
	get_tree().quit()


## Rendering budgets only: simulation, animation and audio retain their normal timing.
func frame_budget(focused: bool) -> int:
	if not focused:
		return 15
	if not page.is_empty() or get_tree().paused:
		return 30
	return int(preferences.values.frame_limit)


func _update_frame_budget() -> void:
	# Fixed-frame headless checks must not acquire wall-clock waits.
	if DisplayServer.get_name() == "headless":
		return
	var limit: int = frame_budget(DisplayServer.window_is_focused())
	if limit != applied_frame_limit:
		Engine.max_fps = limit
		applied_frame_limit = limit


func _exit_tree() -> void:
	if applied_frame_limit >= 0 and Engine.max_fps == applied_frame_limit:
		Engine.max_fps = previous_frame_limit


func _process(_delta: float) -> void:
	_update_frame_budget()
	_record_completion()
	if is_instance_valid(report_subtitle) and session != null:
		report_subtitle.text = session.get_node("Incident/Voice").subtitle
	if session != null:
		var story: CanvasLayer = session.get_node("Incident").presentation
		if story.opening_seen and not preferences.values.opening_seen:
			preferences.values.opening_seen = true
			preferences.save_settings()
		if session.get_node("Incident").stage == session.get_node("Incident").Stage.RESOLVED and story.finale_completed:
			main_menu()
			return
	if session != null and page.is_empty():
		var incident: Node = session.get_node("Incident")
		if incident.terminal():
			if not session.get_node("Player/CameraRig").controls_active:
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
			"credits", "campaign": show_page("main")
			"tester_unlock": show_page("campaign")
	elif not page.is_empty() and event.is_action_pressed("reset_player"):
		get_viewport().set_input_as_handled()
		if session != null and page in ["pause", "report"] and not event.is_echo():
			restart_incident()
