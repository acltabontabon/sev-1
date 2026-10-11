extends CanvasLayer
## A rigged corporate survey. Reads real combat events; never owns input or time.
## One bounded receipt per rollback, held behind cinematics and discarded at run end.
const PAPER: Color = Color(.93, .89, .79)
const INK: Color = Color(.13, .18, .19)
const STAMP: Color = Color(.6, .12, .08)
const RESPONSE_SECONDS: float = 10.0
var incident: Node
var player: CharacterBody3D
var pending: bool = false
var active: bool = false
var completed: bool = false
var rating: int = 0
var delay: float = 0.0
var age: float = 0.0
var hold: float = 0.0
var hit_gap: float = 0.0
var punch: float = 0.0
var receipt: PanelContainer
var heading: Label
var detail: Label
var stars: Label
var verdict: Label
var small_print: Label
var stamp_sound: AudioStreamPlayer


func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_ALWAYS
	incident = get_parent()
	player = incident.player
	player.specials.rollback_completed.connect(_request)
	player.hit_confirmed.connect(_on_hit)
	receipt = PanelContainer.new()
	receipt.name = "SatisfactionReceipt"
	receipt.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	receipt.offset_left = -338
	receipt.offset_right = -28
	receipt.offset_top = 245
	receipt.offset_bottom = 455
	receipt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper: StyleBoxFlat = StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.border_color = STAMP
	paper.border_width_top = 5
	paper.shadow_color = Color(0, 0, 0, .3)
	paper.shadow_size = 5
	paper.set_content_margin_all(15)
	receipt.add_theme_stylebox_override("panel", paper)
	add_child(receipt)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	receipt.add_child(column)
	_label(column, "SYNERGEX  /  PEOPLE ANALYTICS", 11)
	heading = _label(column, "ROLLBACK SUCCESSFUL.", 22)
	heading.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_semibold.ttf"))
	detail = _label(column, "Mandatory satisfaction survey", 14)
	stars = _label(column, "", 27)
	stars.add_theme_color_override("font_color", STAMP)
	verdict = _label(column, "", 18)
	verdict.add_theme_color_override("font_color", STAMP)
	small_print = _label(column, "", 12)
	small_print.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	small_print.custom_minimum_size.x = 278
	stamp_sound = AudioStreamPlayer.new()
	stamp_sound.stream = preload("res://assets/audio/sfx/ui_confirm.ogg")
	stamp_sound.bus = &"Effects"
	stamp_sound.volume_db = -12
	add_child(stamp_sound)
	reset()


func _label(parent: Node, text: String, size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", preload("res://assets/fonts/inter_variable.ttf"))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func reset() -> void:
	pending = false
	active = false
	completed = false
	rating = 0
	age = 0.0
	hold = 0.0
	delay = 0.0
	hit_gap = 0.0
	punch = 0.0
	if receipt != null:
		receipt.hide()
		stamp_sound.stop()


func _request() -> void:
	if incident.terminal():
		return
	reset()
	pending = true
	delay = .9


func _blocked() -> bool:
	return get_tree().paused or incident.modal_pending() or incident.dialogue.is_open() or player.narrative_hold \
		or not incident.presentation.beat_shot.is_empty() or not player.camera_rig.controls_active


func _process(delta: float) -> void:
	if not pending and not active:
		return
	if incident.terminal() or player.health <= 0:
		reset()
		return
	# Dialogue, menus and cinematic beats never compete with the receipt.
	if _blocked():
		receipt.hide()
		return
	var real_delta: float = delta / maxf(Engine.time_scale, .01)
	if pending:
		delay -= real_delta
		if delay > 0:
			return
		pending = false
		active = true
		heading.text = "ROLLBACK SUCCESSFUL."
		detail.text = "Mandatory satisfaction survey"
		verdict.text = "HOW DID WE DO?"
		small_print.text = "Keep fighting. Each hit counts as positive feedback."
		_refresh_stars()
	receipt.show()
	hit_gap = maxf(0.0, hit_gap - real_delta)
	punch = maxf(0.0, punch - real_delta * 4.0)
	receipt.pivot_offset = receipt.size * .5
	receipt.scale = Vector2.ONE * (1.0 + .035 * punch)
	receipt.rotation = -.015 * punch
	if completed:
		hold -= real_delta
		receipt.modulate.a = clampf(hold * 2.0, 0.0, 1.0)
		if hold <= 0:
			reset()
	else:
		receipt.modulate.a = 1.0
		age += real_delta
		if age >= RESPONSE_SECONDS:
			_complete(true)


func _on_hit() -> void:
	if not active or completed or _blocked() or hit_gap > 0.0:
		return
	rating = mini(5, rating + 1)
	hit_gap = .3
	punch = 1.0
	_refresh_stars()
	if DisplayServer.get_name() != "headless":
		stamp_sound.pitch_scale = .85 + rating * .07
		stamp_sound.play()
	if rating == 5:
		_complete(false)


func _refresh_stars() -> void:
	stars.text = "★ ".repeat(rating) + "☆ ".repeat(5 - rating)


func _complete(silence: bool) -> void:
	completed = true
	rating = 5
	_refresh_stars()
	punch = 1.0
	hold = 4.0
	heading.text = "100% SATISFACTION."
	detail.text = "Another leadership success."
	verdict.text = "APPROVED BY YOU*"
	small_print.text = "*No response recorded. Consent assumed." if silence else "*Violence interpreted as enthusiasm."
