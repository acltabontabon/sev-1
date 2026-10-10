extends CanvasLayer

var external_menu: bool = false
var hit_left: float = 0.0
var hurt_left: float = 0.0
var damage_flash_enabled: bool = true
var shake_strength: float = 0.0
var vitals: PanelContainer
## "What next": a compass arrow toward the next step and one plain sentence.
var guide: HBoxContainer
var guide_arrow: Label
var guide_text: Label
var minimap: Control
var focus_bar: ProgressBar
var focus_value: Label
var focus_full: bool = false
## Anime cut-in: a slanted strip with the move's name, sliding through.
var cut_in: PanelContainer
var cut_in_text: Label
## Kill streak banner: DOUBLE MERGE, TRIPLE MERGE, … slams in on the right and fades.
var streak: VBoxContainer
var streak_title: Label
var streak_note: Label
var health_bar: ProgressBar
var health_value: Label
var burnout_bar: ProgressBar
var burnout_value: Label
var buff: Label
var boss_box: VBoxContainer
var boss_bar: ProgressBar
var boss_state: Label
var notice: PanelContainer
var notice_text: Label
var evidence: VBoxContainer
var debt_bar: ProgressBar
var debt_value: Label
var banner: PanelContainer
var banner_text: Label
var last_stage: int = -1
var last_debt: int = 0
var last_burnout: int = 0
const EVIDENCE: Array = [
	["CORE LEDGER", "SUCCESS", "Signed receipt: the money was saved.", Color(.35, .95, .65)],
	["LOAN MANAGEMENT", "FAILED", "Still waiting for a payment confirmation.", Color(1, .4, .3)],
	["PAYMENT PROCESSING", "NOT FOUND", "Delivery log stops before arrival.", Color(1, .75, .3)]]
var last_message: String = ""
var message_age: float = 99.0
const STATUS: Array[String] = ["NEW", "TRIAGE", "INVESTIGATING", "CONTAINING", "ESCALATED TO: YOU", "RESOLVED", "REOPENED"]
@onready var comfort: HBoxContainer = $CapturePrompt/Panel/Padding/VBox/Comfort
@onready var player: CharacterBody3D = %Player
@onready var enemy: CharacterBody3D = %Enemy
@onready var camera_rig: Node3D = %Player/CameraRig
@onready var prompt: Control = $CapturePrompt
@onready var status: Label = $Margin/VBox/Status


func _ready() -> void:
	shake_strength = camera_rig.impulse_degrees
	comfort.get_node("Shake").toggled.connect(_set_shake)
	comfort.get_node("Flash").toggled.connect(_set_flash)
	if get_parent().has_node("Incident"):
		var backdrop: StyleBoxFlat = StyleBoxFlat.new()
		backdrop.bg_color = Color(.025, .045, .055, .96)
		$CapturePrompt/Panel.add_theme_stylebox_override("panel", backdrop)
	camera_rig.capture_changed.connect(_on_capture_changed)
	player.health_changed.connect(_on_health_changed)
	enemy.health_changed.connect(_on_health_changed)
	player.hit_confirmed.connect(_on_hit)
	player.hurt.connect(_on_hurt)
	if get_parent().has_node("Incident"):
		var debt: Label = Label.new()
		debt.name = "Debt"
		$Margin/VBox.add_child(debt)
		var burnout: Label = Label.new()
		burnout.name = "Burnout"
		$Margin/VBox.add_child(burnout)
		_build_incident_hud()
	refresh()


func _bar(fill: Color, width: float) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, 9)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var back: StyleBoxFlat = StyleBoxFlat.new()
	back.bg_color = Color(.08, .1, .12, .9)
	back.set_corner_radius_all(2)
	var front: StyleBoxFlat = StyleBoxFlat.new()
	front.bg_color = fill
	front.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", front)
	return bar


func _row(parent: Container, caption: String, bar: ProgressBar) -> Label:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var name_label: Label = Label.new()
	name_label.text = caption
	name_label.theme_type_variation = "Eyebrow"
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.custom_minimum_size.x = 56
	row.add_child(name_label)
	row.add_child(bar)
	var value: Label = Label.new()
	value.theme_type_variation = "MonoLabel"
	value.add_theme_font_size_override("font_size", 11)
	row.add_child(value)
	return value


## Incident HUD: a ticket header, a vitals card, a boss bar and a transient notice.
## Existing labels are restyled and reused so the run still reads them by name.
func _build_incident_hud() -> void:
	$Margin/VBox/Title.theme_type_variation = "Eyebrow"
	$Margin/VBox/Title.remove_theme_font_size_override("font_size")
	$Margin/VBox/Title.add_theme_color_override("font_color", Color(1, .55, .35))
	status.theme_type_variation = "Subhead"
	status.remove_theme_font_size_override("font_size")
	status.add_theme_font_size_override("font_size", 18)
	status.remove_theme_color_override("font_color")
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$Margin/VBox/Health.hide()
	$Margin/VBox/AttackState.hide()
	$Margin.offset_right = 560
	vitals = PanelContainer.new()
	vitals.theme_type_variation = "Card"
	vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	# Compact: the fight is the picture; vitals read at a glance from the corner.
	vitals.offset_left = 20
	vitals.offset_right = 20
	vitals.offset_top = -20
	vitals.offset_bottom = -20
	vitals.grow_horizontal = Control.GROW_DIRECTION_END
	vitals.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(vitals)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	vitals.add_child(column)
	health_bar = _bar(Color(.4, .9, .85), 100)
	health_value = _row(column, "YOU", health_bar)
	burnout_bar = _bar(Color(1, .7, .3), 100)
	burnout_value = _row(column, "BURNOUT", burnout_bar)
	debt_bar = _bar(Color(1, .55, .25), 100)
	debt_value = _row(column, "DEBT", debt_bar)
	focus_bar = _bar(Color(.62, .5, 1), 100)
	focus_value = _row(column, "FOCUS", focus_bar)
	_build_banner()
	for node_name: String in ["Debt", "Burnout"]:
		var label: Label = $Margin/VBox.get_node(node_name)
		label.reparent(column)
		label.theme_type_variation = "MonoLabel"
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(.62, .68, .72))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 240
	_build_cut_in()
	_build_streak()
	player.specials.called.connect(_on_move_called)
	minimap = preload("res://game/ui/minimap.gd").new()
	minimap.name = "Minimap"
	minimap.incident = get_parent().get_node("Incident")
	add_child(minimap)
	buff = Label.new()
	buff.theme_type_variation = "Subhead"
	buff.add_theme_font_size_override("font_size", 13)
	buff.add_theme_color_override("font_color", Color(.55, 1, .7))
	column.add_child(buff)
	guide = HBoxContainer.new()
	guide.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	guide.offset_left = -360
	guide.offset_right = 360
	guide.offset_top = 112
	guide.alignment = BoxContainer.ALIGNMENT_CENTER
	guide.add_theme_constant_override("separation", 10)
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(guide)
	guide_arrow = Label.new()
	guide_arrow.text = "▲"
	guide_arrow.add_theme_font_size_override("font_size", 24)
	guide_arrow.add_theme_color_override("font_color", Color(1, .7, .35))
	guide_arrow.custom_minimum_size = Vector2(28, 28)
	guide_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guide_arrow.pivot_offset = Vector2(14, 14)
	guide.add_child(guide_arrow)
	guide_text = Label.new()
	guide_text.theme_type_variation = "Subhead"
	guide_text.add_theme_font_size_override("font_size", 17)
	guide_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, .85))
	guide_text.add_theme_constant_override("outline_size", 6)
	guide.add_child(guide_text)
	boss_box = VBoxContainer.new()
	boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_box.offset_left = -260
	boss_box.offset_right = 260
	boss_box.offset_top = 28
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(boss_box)
	var boss_name: Label = Label.new()
	boss_name.text = "THE VARIANCE"
	boss_name.theme_type_variation = "Headline"
	boss_name.add_theme_font_size_override("font_size", 30)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_name)
	boss_bar = _bar(Color(.7, .45, 1), 520)
	boss_box.add_child(boss_bar)
	boss_state = Label.new()
	boss_state.theme_type_variation = "Eyebrow"
	boss_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_state)
	notice = PanelContainer.new()
	notice.theme_type_variation = "Card"
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	notice.offset_left = -330
	notice.offset_right = 330
	notice.offset_top = -150
	notice.offset_bottom = -70
	notice.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(notice)
	notice_text = Label.new()
	notice_text.theme_type_variation = "MonoLabel"
	notice_text.add_theme_font_size_override("font_size", 14)
	notice_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_child(notice_text)
	_build_evidence()
	$Controls.theme_type_variation = "Eyebrow"
	$Controls.remove_theme_font_size_override("font_size")
	$Controls.add_theme_font_size_override("font_size", 12)
	# Two lines in the gap between the vitals card (up to ~560 px wide) and the minimap.
	$Controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Controls.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	$Controls.offset_left = -730
	$Controls.offset_right = -232
	$Controls.offset_bottom = -10


func _set_shake(enabled: bool) -> void:
	camera_rig.impulse_degrees = shake_strength if enabled else 0.0


func _set_flash(enabled: bool) -> void:
	damage_flash_enabled = enabled
	hurt_left = 0.0
	$DamageFlash.color.a = 0.0


func _on_capture_changed(_active: bool) -> void:
	refresh()


func _on_health_changed(_value: int) -> void:
	refresh()


func refresh() -> void:
	var incident: Node = get_parent().get_node_or_null("Incident")
	if incident != null and incident.is_node_ready():
		_refresh_incident(incident)
		return
	prompt.visible = not camera_rig.controls_active
	status.text = "OFFICE AFTER HOURS   /   LIVE" if camera_rig.controls_active else "OFFICE AFTER HOURS   /   PAUSED"
	$Margin/VBox/Health.text = "YOU  %d / %d     |     INCIDENT  %d / %d" % [player.health, player.max_health, enemy.health, enemy.max_health]
	if player.health <= 0:
		status.text = "YOU ARE OFFLINE  /  R TO RETRY"
		$CapturePrompt/Panel/Padding/VBox/Text.text = "YOU ARE OFFLINE\n\nPress R to reset the encounter.\nThen click to resume."
	elif enemy.health <= 0:
		status.text = "INCIDENT RESOLVED  /  R TO RUN IT BACK"
		$CapturePrompt/Panel/Padding/VBox/Text.text = "INCIDENT RESOLVED\n\nPress R for another round.\nClick to keep exploring."
	else:
		$CapturePrompt/Panel/Padding/VBox/Text.text = "FRIDAY 16:59  /  CLICK TO BEGIN\n\nLMB or F: three-hit chain. Press again near recovery.\nQ or right mouse: dodge. Move to choose direction.\nNo movement input: dodge backward.\n\nWatch the orange warning. Cyan means invulnerable.\nR resets both fighters. Escape pauses."


func _on_hit() -> void:
	hit_left = 0.18
	$HitFeedback.text = "HIT  −%d" % player.melee.effective_damage()


func _on_hurt() -> void:
	hurt_left = 0.2 if damage_flash_enabled else 0.0


func _process(delta: float) -> void:
	message_age += delta
	if get_parent().has_node("Incident"):
		refresh()
	hit_left = maxf(0, hit_left - delta)
	hurt_left = maxf(0, hurt_left - delta)
	$HitFeedback.visible = hit_left > 0
	$DamageFlash.color.a = hurt_left * 0.75
	if get_parent().has_node("Incident") and get_parent().get_node("Incident").terminal():
		$Margin/VBox/AttackState.text = "R TO RESTART INCIDENT"
	elif player.health <= 0:
		$Margin/VBox/AttackState.text = "R TO RESTART"
	elif player.dodging:
		$Margin/VBox/AttackState.text = "DODGE  /  INVULNERABLE" if player.dodge_is_invulnerable() else "DODGE  /  RECOVERY"
	elif player.melee.attacking:
		var phase: String = "WIND-UP" if player.melee.elapsed < player.melee.windup else ("STRIKE" if player.melee.is_active() else "RECOVERY")
		var queue_text: String = "  /  NEXT QUEUED" if player.combo_buffer_left > 0 else ""
		$Margin/VBox/AttackState.text = "%d / 3  %s  /  %s%s" % [player.combo_index + 1, player.combo[player.combo_index].title, phase, queue_text]
	else:
		$Margin/VBox/AttackState.text = "READY  /  LMB OR F   •   Q OR RMB TO DODGE"


func _build_cut_in() -> void:
	cut_in = PanelContainer.new()
	cut_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strip: StyleBoxFlat = StyleBoxFlat.new()
	strip.bg_color = Color(.02, .02, .04, .82)
	strip.border_color = Color(.62, .5, 1)
	strip.border_width_top = 3
	strip.border_width_bottom = 3
	strip.content_margin_left = 60
	strip.content_margin_right = 60
	strip.content_margin_top = 6
	strip.content_margin_bottom = 6
	cut_in.add_theme_stylebox_override("panel", strip)
	cut_in_text = Label.new()
	cut_in_text.theme_type_variation = "DisplayTitle"
	cut_in_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cut_in_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut_in.add_child(cut_in_text)
	cut_in.hide()
	add_child(cut_in)


func _build_streak() -> void:
	streak = VBoxContainer.new()
	streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	streak.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	streak.offset_left = -520
	streak.offset_right = -60
	streak.offset_top = -150
	streak.offset_bottom = -60
	streak.alignment = BoxContainer.ALIGNMENT_CENTER
	streak_title = Label.new()
	streak_title.theme_type_variation = "DisplayTitle"
	streak_title.add_theme_font_size_override("font_size", 52)
	streak_title.add_theme_color_override("font_color", Color(1, .82, .35))
	streak_title.add_theme_constant_override("outline_size", 10)
	streak_title.add_theme_color_override("font_outline_color", Color(.2, .05, 0, .9))
	streak_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	streak.add_child(streak_title)
	streak_note = Label.new()
	streak_note.theme_type_variation = "MonoLabel"
	streak_note.add_theme_font_size_override("font_size", 14)
	streak_note.add_theme_color_override("font_color", Color(1, .9, .7))
	streak_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	streak.add_child(streak_note)
	streak.hide()
	add_child(streak)


func show_streak(title: String, count: int) -> void:
	streak_title.text = title
	streak_note.text = "%d KILLS  ·  STREAK FOCUS BONUS" % count
	streak.show()
	streak.modulate.a = 1.0
	streak.pivot_offset = streak.size * Vector2(1, .5)
	streak.scale = Vector2.ONE * 1.6
	var pop: Tween = streak.create_tween()
	pop.set_ignore_time_scale(true)
	pop.tween_property(streak, "scale", Vector2.ONE, .14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_interval(1.2)
	pop.tween_property(streak, "modulate:a", 0.0, .35)
	pop.tween_callback(streak.hide)


## The move's name crosses the screen as it is shouted: a wide slanted strip for the
## ultimate, a quick slash of text for the others. Runs on real time (slow motion too).
func _on_move_called(title: String, ultimate: bool) -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	cut_in_text.text = title
	cut_in_text.add_theme_font_size_override("font_size", 72 if ultimate else 40)
	cut_in_text.add_theme_color_override("font_color", Color(.85, .8, 1) if ultimate else Color(1, .97, .9))
	(cut_in.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(.02, .02, .04, .82 if ultimate else 0.0)
	(cut_in.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(.62, .5, 1, 1.0 if ultimate else 0.0)
	cut_in.size = Vector2(view.x * 1.3, 0)
	cut_in.reset_size()
	cut_in.size.x = view.x * 1.3
	cut_in.pivot_offset = cut_in.size * .5
	cut_in.rotation = deg_to_rad(-6.0)
	var y: float = view.y * (.42 if ultimate else .3)
	cut_in.position = Vector2(-view.x * 1.4, y)
	cut_in.modulate.a = 1.0
	cut_in.show()
	var slide: Tween = cut_in.create_tween()
	slide.set_ignore_time_scale(true)
	slide.tween_property(cut_in, "position:x", -view.x * .15, .12).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	slide.tween_property(cut_in, "position:x", -view.x * .1, .55 if ultimate else .35)
	slide.tween_property(cut_in, "position:x", view.x * 1.2, .12).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	slide.tween_callback(cut_in.hide)


## A full-width incident banner for the moments the whole office should hear.
func _build_banner() -> void:
	banner = PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = 0
	banner.offset_bottom = 54
	add_child(banner)
	banner_text = Label.new()
	banner_text.theme_type_variation = "Headline"
	banner_text.add_theme_font_size_override("font_size", 26)
	banner_text.add_theme_color_override("font_color", Color.WHITE)
	banner_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_text)
	banner.hide()


func flash_banner(text: String, color: Color, seconds: float = 3.6) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(color, .92)
	style.set_content_margin_all(10)
	style.border_color = color.lightened(.4)
	style.border_width_bottom = 3
	banner.add_theme_stylebox_override("panel", style)
	banner_text.text = text
	banner.show()
	banner.modulate.a = 1.0
	banner.position.y = -60
	var slide: Tween = banner.create_tween()
	slide.tween_property(banner, "position:y", 0.0, .25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slide.tween_interval(seconds)
	slide.tween_property(banner, "modulate:a", 0.0, .5)
	slide.tween_callback(banner.hide)


func _pulse(control: Control) -> void:
	control.pivot_offset = control.size * .5
	var beat: Tween = control.create_tween()
	beat.tween_property(control, "scale", Vector2(1.0, 1.6), .08)
	beat.tween_property(control, "scale", Vector2.ONE, .25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## The investigation as a board of three system cards: status first, then the fact.
func _build_evidence() -> void:
	evidence = VBoxContainer.new()
	evidence.mouse_filter = Control.MOUSE_FILTER_IGNORE
	evidence.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	evidence.offset_left = -420
	evidence.offset_right = 420
	evidence.offset_top = -250
	evidence.offset_bottom = -44
	evidence.add_theme_constant_override("separation", 8)
	add_child(evidence)
	var title: Label = Label.new()
	title.text = "EVIDENCE  ·  WHICH SYSTEM NEVER RECEIVED THE PAYMENT?  ·  PRESS 1 · 2 · 3"
	title.theme_type_variation = "Eyebrow"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(.75, .9, .95))
	evidence.add_child(title)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	evidence.add_child(row)
	for index in range(3):
		var entry: Array = EVIDENCE[index]
		var card: PanelContainer = PanelContainer.new()
		card.theme_type_variation = "Card"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style: StyleBoxFlat = (ThemeDB.get_project_theme().get_stylebox("panel", "Card") as StyleBoxFlat).duplicate()
		style.border_color = entry[3]
		style.border_width_top = 4
		card.add_theme_stylebox_override("panel", style)
		row.add_child(card)
		var column: VBoxContainer = VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		card.add_child(column)
		var system: Label = Label.new()
		system.text = "%d   %s" % [index + 1, entry[0]]
		system.theme_type_variation = "Eyebrow"
		column.add_child(system)
		var status_label: Label = Label.new()
		status_label.text = entry[1]
		status_label.theme_type_variation = "Headline"
		status_label.add_theme_font_size_override("font_size", 34)
		status_label.add_theme_color_override("font_color", entry[3])
		column.add_child(status_label)
		var fact: Label = Label.new()
		fact.text = entry[2]
		fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fact.add_theme_font_size_override("font_size", 15)
		column.add_child(fact)
	evidence.hide()


func _refresh_incident(incident: Node) -> void:
	var open_seconds: int = maxi(0, int(incident.elapsed - 13.4))
	$Margin/VBox/Title.text = "INC-001  ·  SEV-1  ·  %s  ·  OPEN %02d:%02d" % [STATUS[incident.stage], open_seconds / 60, open_seconds % 60]
	status.text = incident.objective
	var progress: String = incident.encounter_status()
	if not progress.is_empty():
		status.text += "\n" + progress
	if incident.stage == incident.Stage.INVESTIGATION and incident.inspected and not incident.near_console():
		status.text = "Return to the OPERATIONS marker to select a record."
	$Margin/VBox/Health.text = "YOU  %d / %d" % [player.health, player.max_health]
	if is_instance_valid(incident.active_enemy):
		var foe: CharacterBody3D = incident.active_enemy
		$Margin/VBox/Health.text += "     |     %s  %d / %d" % ["THE VARIANCE" if incident.stage == incident.Stage.BOSS else "RECORD", foe.health, foe.max_health]
	$Controls.text = "E USE   LMB COMBO   Q DODGE   R RESTART   ESC PAUSE\nC REPLY ALL   X BLAME   Z CIRCLE   G COUNTER   V ULT"
	$Controls.offset_top = -46
	if incident.message != last_message:
		last_message = incident.message
		message_age = 0.0
	notice_text.text = incident.message
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	health_value.text = "%d / %d" % [player.health, player.max_health]
	burnout_bar.max_value = incident.run.burnout_limit
	burnout_bar.value = incident.run.burnout
	burnout_value.text = "%d  %s" % [incident.run.burnout, incident.run.burnout_title()]
	debt_bar.max_value = incident.run.debt_limit
	debt_bar.value = incident.run.debt
	debt_value.text = "%d  %s" % [incident.run.debt, incident.run.severity()]
	var specials: Node = player.specials
	focus_bar.value = specials.focus
	var skills: Array[String] = []
	for entry: Array in [["C", specials.wave_cooldown], ["X", specials.dash_cooldown], ["Z", specials.spin_cooldown], ["G", specials.counter_cooldown]]:
		skills.append("%s %s" % [entry[0], "%.1f" % entry[1] if entry[1] > 0 else "✓"])
	focus_value.text = ("V ROLLBACK READY" if specials.ultimate_ready() else "%d%%" % roundi(specials.focus)) + "  ·  " + "  ".join(skills)
	focus_value.add_theme_color_override("font_color", Color(.8, .7, 1) if specials.ultimate_ready() else Color(.75, .8, .85))
	if specials.ultimate_ready() and not focus_full:
		_pulse(focus_bar)
	focus_full = specials.ultimate_ready()
	if incident.run.debt != last_debt:
		last_debt = incident.run.debt
		_pulse(debt_bar)
	if incident.run.burnout != last_burnout:
		last_burnout = incident.run.burnout
		_pulse(burnout_bar)
	if incident.stage != last_stage:
		var previous: int = last_stage
		last_stage = incident.stage
		if previous != -1:
			# The ticket header slides in fresh whenever the incident changes status.
			$Margin.modulate.a = 0.0
			$Margin.position.x = -40
			var slide: Tween = $Margin.create_tween().set_parallel()
			slide.tween_property($Margin, "modulate:a", 1.0, .35)
			slide.tween_property($Margin, "position:x", 32.0, .35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		match incident.stage:
			incident.Stage.ENCOUNTER_ONE:
				flash_banner("SEV-1 DECLARED   ·   INC-001 PAYMENTS   ·   PAGING: YOU", Color(.72, .08, .05))
			incident.Stage.INVESTIGATION:
				flash_banner("DISCREPANCY CONFIRMED   ·   INVESTIGATE AT OPERATIONS", Color(.1, .32, .4), 2.6)
			incident.Stage.ENCOUNTER_TWO:
				flash_banner("CONTAINMENT AUTHORIZED   ·   OWNER: YOU", Color(.62, .25, .05), 2.6)
			incident.Stage.BOSS:
				flash_banner("ESCALATED TO: YOU   ·   PRODUCTION CORE OPEN   ·   GO NORTH", Color(.4, .1, .55), 3.2)
	(burnout_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = [Color(.55, .85, 1), Color(1, .72, .3), Color(1, .38, .25)][incident.run.burnout_band()]
	buff.text = incident.buff_text()
	buff.visible = not buff.text.is_empty()
	var boss: CharacterBody3D = incident.boss
	boss_box.visible = is_instance_valid(boss) and boss.health > 0
	if boss_box.visible:
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.health
		boss_state.text = "OPEN — STRIKE NOW" if boss.exposed else "SHIELDED — EVADE"
	var debt_label: Label = find_child("Debt", true, false)
	var burnout_label: Label = find_child("Burnout", true, false)
	debt_label.text = "Debt effect: enemies pursue +%d%% faster" % roundi((incident.run.pressure() - 1) * 100)
	var run: Node = incident.run
	burnout_label.text = "Burnout: your damage +%d%% · risk +%d%%   %s" % [roundi(run.burnout_offense() * 100), roundi(run.burnout_risk() * 100), run.modifier_summary()]
	burnout_label.modulate = [Color(.75, .85, .9), Color(1, .85, .55), Color(1, .65, .5)][run.burnout_band()]
	if not incident.buff_text().is_empty():
		burnout_label.text += "  ·  " + incident.buff_text()
	# Effect lines only appear once there is an effect to read.
	debt_label.visible = incident.run.pressure() > 1.001
	burnout_label.visible = run.burnout > 0 or not incident.buff_text().is_empty() or not run.modifier_summary().begins_with("Damage 100% • Taken 100% • Dodge recovery 100%")
	if incident.challenge_result == "Active":
		burnout_label.text += "  ·  Committed ETA %d:%02d" % [int(ceil(incident.challenge_left)) / 60, int(ceil(incident.challenge_left)) % 60]
	elif incident.corporate_choice == 0:
		burnout_label.text += "  ·  " + incident.challenge_result
	prompt.visible = (not camera_rig.controls_active or incident.terminal()) and not incident.modal_pending()
	if external_menu:
		prompt.visible = false
	comfort.visible = not incident.terminal()
	$Margin.visible = camera_rig.controls_active and not incident.terminal() and not incident.modal_pending()
	if incident.stage == incident.Stage.ALERT or (incident.stage == incident.Stage.BOSS and incident.boss_triggered and incident.boss_time < incident.presentation.boss_length + 2):
		$Margin.visible = false
	$Controls.visible = $Margin.visible
	vitals.visible = $Margin.visible
	if not $Margin.visible:
		banner.hide()
	evidence.visible = $Margin.visible and incident.stage == incident.Stage.INVESTIGATION and incident.inspected and incident.near_console()
	vitals.visible = vitals.visible and not evidence.visible
	notice.visible = $Margin.visible and not evidence.visible and not incident.message.is_empty() and message_age < 7.0
	boss_box.visible = boss_box.visible and $Margin.visible
	_refresh_guide(incident)
	$CapturePrompt/Panel/Padding/VBox/Text.add_theme_font_size_override("font_size", 17 if incident.terminal() else 20)
	$CapturePrompt/Panel/Padding/VBox/Text.text = incident.report if incident.terminal() else "FRIDAY, 4:59 PM\nOne payment. Three systems. Nobody agrees.\n\nClick to begin / resume\nWASD move • Mouse aim • LMB/F three-hit combo\nQ / right mouse dodge • E inspect operations\n\nWatch orange warnings. Strike during recovery.\nR restarts the entire incident. TAB skips introductions."
	if not incident.terminal() and incident.elapsed > 0:
		$CapturePrompt/Panel/Padding/VBox/Text.text += "\n\n" + run.modifier_summary() + "\n" + run.burnout_notice


func _refresh_guide(incident: Node) -> void:
	var step: Dictionary = incident.next_step()
	guide.visible = $Margin.visible and not step.is_empty() and not evidence.visible
	if not guide.visible:
		return
	var point: Vector3 = step.point
	guide_arrow.visible = point.is_finite()
	var text: String = "NEXT  ·  " + step.text
	if point.is_finite():
		var to: Vector3 = point - player.global_position
		to.y = 0
		var view: Basis = player.camera_rig.global_basis
		var forward: Vector3 = -view.z
		forward.y = 0
		var right: Vector3 = view.x
		right.y = 0
		# Screen rotation is clockwise: positive when the step lies to the right.
		guide_arrow.rotation = atan2(to.dot(right.normalized()), to.dot(forward.normalized()))
		text += "  ·  %d m" % roundi(to.length())
	guide_text.text = text


func configure_release_ui() -> void:
	external_menu = true
