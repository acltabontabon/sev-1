extends SceneTree
## Author the shared SEV-1 interface theme and font variations. Run after import:
## sh tools/godot.sh --headless --path . --script tools/build_ui_theme.gd
## Corporate software, exaggerated: calm ink panels, mono metadata, one alarm color.

const OUT: String = "res://game/ui/"
const INK: Color = Color(.018, .026, .034, .94)
const RAISED: Color = Color(.045, .062, .078, .96)
const LINE: Color = Color(.17, .25, .29)
const TEXT: Color = Color(.89, .93, .94)
const MUTED: Color = Color(.56, .64, .67)
const CYAN: Color = Color(.45, .9, .95)
const ALARM: Color = Color(1, .3, .17)


func _initialize() -> void:
	var display: FontFile = load("res://assets/fonts/barlow_condensed_bold.ttf")
	var display_semi: FontFile = load("res://assets/fonts/barlow_condensed_semibold.ttf")
	var body: FontVariation = _variation("res://assets/fonts/inter_variable.ttf", 440, 0, "font_body.tres")
	var strong: FontVariation = _variation("res://assets/fonts/inter_variable.ttf", 640, 0, "font_strong.tres")
	var mono: FontVariation = _variation("res://assets/fonts/jetbrains_mono_variable.ttf", 520, 1, "font_mono.tres")
	var theme: Theme = Theme.new()
	theme.default_font = body
	theme.default_font_size = 19
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, .55))
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_constant("line_spacing", "Label", 3)
	_label(theme, "DisplayTitle", display, 168, TEXT)
	_label(theme, "Headline", display_semi, 44, TEXT)
	_label(theme, "Subhead", strong, 22, TEXT)
	_label(theme, "Eyebrow", mono, 14, MUTED)
	_label(theme, "Caption", body, 15, MUTED)
	_label(theme, "MonoLabel", mono, 15, TEXT)
	_label(theme, "AlarmLabel", display_semi, 30, ALARM)
	theme.set_stylebox("panel", "PanelContainer", _box(INK, LINE, 1, 4, 30))
	theme.set_type_variation("Card", "PanelContainer")
	theme.set_stylebox("panel", "Card", _box(RAISED, LINE, 1, 6, 14))
	for type: String in ["Button", "OptionButton", "CheckButton"]:
		theme.set_font("font", type, strong)
		theme.set_font_size("font_size", type, 18)
		theme.set_color("font_color", type, TEXT)
		theme.set_color("font_hover_color", type, Color.WHITE)
		theme.set_color("font_focus_color", type, Color.WHITE)
		theme.set_color("font_pressed_color", type, CYAN)
		theme.set_stylebox("normal", type, _box(Color(.06, .085, .1, .9), LINE, 1, 4, 12))
		theme.set_stylebox("hover", type, _box(Color(.09, .13, .15, .95), Color(.3, .45, .5), 1, 4, 12))
		theme.set_stylebox("pressed", type, _box(Color(.04, .07, .08, 1), CYAN, 1, 4, 12))
		theme.set_stylebox("focus", type, _box(Color(0, 0, 0, 0), CYAN, 2, 4, 12))
	# Menu entries read as part of the world: no boxes, an alarm bar marks focus.
	theme.set_type_variation("MenuEntry", "Button")
	theme.set_font("font", "MenuEntry", display_semi)
	theme.set_font_size("font_size", "MenuEntry", 34)
	theme.set_color("font_color", "MenuEntry", Color(.78, .84, .86))
	theme.set_color("font_hover_color", "MenuEntry", Color.WHITE)
	theme.set_color("font_focus_color", "MenuEntry", Color.WHITE)
	theme.set_color("font_pressed_color", "MenuEntry", ALARM)
	var clear: StyleBoxEmpty = StyleBoxEmpty.new()
	clear.set_content_margin_all(2)
	clear.content_margin_left = 18
	var marked: StyleBoxFlat = _box(Color(1, .3, .17, .08), ALARM, 0, 0, 2)
	marked.border_width_left = 4
	# Focus slides the entry right; the alarm bar stays on the original edge.
	marked.content_margin_left = 32
	for state: String in ["normal", "disabled"]:
		theme.set_stylebox(state, "MenuEntry", clear)
	for state: String in ["hover", "pressed", "focus"]:
		theme.set_stylebox(state, "MenuEntry", marked)
	theme.set_type_variation("MenuSub", "Label")
	theme.set_font("font", "MenuSub", mono)
	theme.set_font_size("font_size", "MenuSub", 13)
	theme.set_color("font_color", "MenuSub", MUTED)
	theme.set_stylebox("slider", "HSlider", _box(Color(.1, .14, .16), LINE, 0, 3, 3))
	var fill: StyleBoxFlat = _box(CYAN.darkened(.25), CYAN, 0, 3, 3)
	theme.set_stylebox("grabber_area", "HSlider", fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
	theme.set_stylebox("panel", "PopupMenu", _box(RAISED, LINE, 1, 4, 8))
	theme.set_font("font", "PopupMenu", body)
	theme.set_stylebox("panel", "TooltipPanel", _box(RAISED, LINE, 1, 4, 10))
	theme.set_font("font", "TooltipLabel", body)
	var result: Error = ResourceSaver.save(theme, OUT + "sev1_theme.tres")
	print("Theme saved: ", error_string(result))
	quit(0 if result == OK else 1)


func _variation(path: String, weight: int, spacing: int, file: String) -> FontVariation:
	var font: FontVariation = FontVariation.new()
	font.base_font = load(path)
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	font.spacing_glyph = spacing
	ResourceSaver.save(font, OUT + file)
	return load(OUT + file)


func _label(theme: Theme, name: String, font: Font, size: int, color: Color) -> void:
	theme.set_type_variation(name, "Label")
	theme.set_font("font", name, font)
	theme.set_font_size("font_size", name, size)
	theme.set_color("font_color", name, color)


func _box(fill: Color, border: Color, width: int, radius: int, margin: float) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	box.content_margin_top = margin * .6
	box.content_margin_bottom = margin * .6
	box.anti_aliasing = true
	return box
