extends Control
## One expiring radio caption at a time, separate from interactive conversations.
## Each spoken line arrives as a card from its sender's channel; the engineer's own
## lines are said out loud, so they get a different, unboxed treatment.

const LIMIT: int = 1
const LINGER: float = 2.2
## Speaker: initials, color, channel, small print.
const SENDERS: Dictionary = {
	"MANAGEMENT": ["MG", Color(1, .62, .78), "#inc-001-war-room", "Seen by 14  ·  0 replies"],
	"LEADERSHIP": ["LD", Color(1, .8, .35), "#leadership-updates", "Pinned by Leadership"],
	"PEOPLE OPERATIONS": ["PO", Color(.78, .62, 1), "#general", "248 members"],
	"MONITORING / SEV-1": ["!!", Color(1, .32, .22), "#alerts-prod", "Severity: 1  ·  Paging: you"],
	"INCIDENT CHANNEL": ["IC", Color(.45, .85, .95), "#inc-001-war-room", "11 people are viewing"],
	"PRODUCTION SYSTEM": ["PS", Color(1, .45, .25), "#alerts-prod", "Automated message"],
	"THE VARIANCE": ["??", Color(.7, .45, 1), "#unknown-channel", "This user does not exist"],
	"POSTMORTEM AI": ["AI", Color(.65, .7, .75), "#postmortems", "Blameless by default"],
	"FACILITIES": ["FA", Color(.6, .8, .6), "#facilities", "Ticket auto-closed"],
	"CALENDAR": ["31", Color(.45, .65, 1), "Calendar", "Organizer: Leadership"],
	"PRODUCT": ["PM", Color(1, .6, .3), "#product-roadmap", "Added to backlog"],
	"STATUS PAGE": ["SP", Color(.35, .95, .6), "status.public", "Last updated: optimistically"],
}
var cards: Array[Control] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -452
	offset_right = -36
	offset_top = 120
	offset_bottom = 640


func clear() -> void:
	# Detach now so a restart never briefly holds the previous run's cards.
	for card: Node in get_children():
		remove_child(card)
		card.queue_free()
	cards.clear()


## Adds a card; returns it so callers (and tests) can inspect what was shown.
func post(character: String, text: String, seconds: float, time: String) -> Control:
	var card: Control = _engineer_card(text) if character == "ENGINEER" else _chat_card(character, text, time)
	card.set_meta("expires", seconds + LINGER)
	add_child(card)
	cards.push_front(card)
	while cards.size() > LIMIT:
		var oldest: Control = cards.pop_back()
		oldest.queue_free()
	_layout()
	card.modulate.a = 0.0
	card.position.x += 60
	var enter: Tween = card.create_tween().set_parallel()
	enter.tween_property(card, "modulate:a", 1.0, .2)
	enter.tween_property(card, "position:x", card.position.x - 60, .25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return card


func _chat_card(character: String, text: String, _time: String) -> Control:
	var sender: Array = SENDERS.get(character, [character.left(2), Color(.6, .7, .75), "#general", ""])
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = "Card"
	panel.custom_minimum_size.x = 400
	panel.size.x = 400
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = (get_theme_stylebox("panel", "Card") as StyleBoxFlat).duplicate()
	style.border_color = sender[1].darkened(.35)
	style.border_width_left = 3
	panel.add_theme_stylebox_override("panel", style)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var avatar: PanelContainer = PanelContainer.new()
	var badge: StyleBoxFlat = StyleBoxFlat.new()
	badge.bg_color = sender[1]
	badge.set_corner_radius_all(6)
	avatar.add_theme_stylebox_override("panel", badge)
	avatar.custom_minimum_size = Vector2(38, 38)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var initials: Label = Label.new()
	initials.text = sender[0]
	initials.theme_type_variation = "Subhead"
	initials.add_theme_font_size_override("font_size", 15)
	initials.add_theme_color_override("font_color", Color(.03, .04, .05))
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(initials)
	row.add_child(avatar)
	var body: VBoxContainer = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 2)
	row.add_child(body)
	var head: Label = Label.new()
	head.text = _title(character)
	head.theme_type_variation = "Eyebrow"
	head.add_theme_color_override("font_color", sender[1].lightened(.2))
	head.clip_text = true
	head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.custom_minimum_size.x = 300
	head.size_flags_horizontal = Control.SIZE_FILL
	body.add_child(head)
	var purpose: Label = Label.new()
	purpose.name = "Purpose"
	purpose.text = "RADIO · NO REPLY NEEDED"
	purpose.theme_type_variation = "Eyebrow"
	purpose.add_theme_font_size_override("font_size", 12)
	body.add_child(purpose)
	var message: Label = Label.new()
	message.name = "Message"
	message.text = text
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.x = 300
	message.add_theme_font_size_override("font_size", 17)
	body.add_child(message)
	return panel


## The engineer is not typing; he is muttering. No box, just a voice at the edge.
func _engineer_card(text: String) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size.x = 400
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var who: Label = Label.new()
	who.text = "YOU  (OUT LOUD)"
	who.theme_type_variation = "Eyebrow"
	who.add_theme_color_override("font_color", Color(.45, .9, .85))
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(who)
	var message: Label = Label.new()
	message.name = "Message"
	message.text = "“%s”" % text
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	message.custom_minimum_size.x = 400
	message.theme_type_variation = "Subhead"
	message.add_theme_font_size_override("font_size", 20)
	message.add_theme_constant_override("outline_size", 6)
	message.add_theme_color_override("font_outline_color", Color(0, 0, 0, .8))
	box.add_child(message)
	return box


func _title(character: String) -> String:
	return character.capitalize() if character != "MONITORING / SEV-1" else "Monitoring"


func _layout() -> void:
	var y: float = 0.0
	for card: Control in cards:
		card.position = Vector2(0, y)
		y += card.get_combined_minimum_size().y + 10


func tick(delta: float) -> void:
	for card: Control in cards.duplicate():
		var left: float = card.get_meta("expires") - delta
		card.set_meta("expires", left)
		if left <= 0 and not card.has_meta("leaving"):
			card.set_meta("leaving", true)
			var leave: Tween = card.create_tween()
			leave.tween_property(card, "modulate:a", 0.0, .35)
			leave.tween_callback(func() -> void:
				cards.erase(card)
				card.queue_free()
				_layout())
