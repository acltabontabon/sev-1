extends Control
## The special moves as an icon bar, bottom centre: one tile per move with its key, a
## dark sweep and seconds while it cools down, a flash when it is back, and the ultimate
## filling with FOCUS. Icons are drawn here (no image assets) in each move's colour.

const SLOT: float = 60.0
const GAP: float = 10.0
## [key, icon, cooldown property on special_moves (empty: the ultimate), colour]
const MOVES: Array = [
	["C", "reply_all", "wave_cooldown", Color(.45, .95, 1)],
	["X", "dash", "dash_cooldown", Color(1, .85, .35)],
	["Z", "circle", "spin_cooldown", Color(1, .5, .18)],
	["G", "machine", "counter_cooldown", Color(.45, 1, .6)],
	["V", "rollback", "", Color(.62, .5, 1)],
]
const FLASH_SECONDS: float = .4

var specials: Node
## Per move: the cooldown's full length (it varies: a landed counter resets faster than a
## whiff), the remaining seconds last frame, and the ready flash.
var peaks: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var last: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var flashes: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var clock: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(MOVES.size() * SLOT + (MOVES.size() - 1) * GAP, SLOT)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -custom_minimum_size.x * .5
	offset_right = custom_minimum_size.x * .5
	offset_top = -SLOT - 32
	offset_bottom = -32


func _process(delta: float) -> void:
	if specials == null or not is_visible_in_tree():
		return
	clock += delta
	for index in range(MOVES.size()):
		var left: float = remaining(index)
		if left > last[index] + .01:
			peaks[index] = left
		elif last[index] > 0.0 and left <= 0.0:
			flashes[index] = FLASH_SECONDS
		last[index] = left
		flashes[index] = maxf(0.0, flashes[index] - delta)
	queue_redraw()


## Seconds until the move is usable; for the ultimate, the FOCUS still missing (0..1).
func remaining(index: int) -> float:
	var property: String = MOVES[index][2]
	if property.is_empty():
		return 1.0 - clampf(specials.focus / 100.0, 0.0, 1.0)
	return specials.get(property)


func ready_now(index: int) -> bool:
	return remaining(index) <= 0.0


func _draw() -> void:
	if specials == null:
		return
	var font: Font = get_theme_font("font", "Label")
	for index in range(MOVES.size()):
		var move: Array = MOVES[index]
		var box: Rect2 = Rect2(Vector2(index * (SLOT + GAP), 0), Vector2(SLOT, SLOT))
		var centre: Vector2 = box.get_center()
		var tint: Color = move[3]
		var ultimate: bool = str(move[2]).is_empty()
		var left: float = remaining(index)
		var ready: bool = left <= 0.0
		var pulse: float = .5 + .5 * sin(clock * 6.0) if ultimate and ready else 0.0
		_panel(box, Color(.05, .06, .08, .82), tint if ready else Color(.3, .33, .38), 2.0 + pulse * 1.5)
		if ultimate:
			# FOCUS rises from the bottom of the tile.
			var filled: float = (1.0 - left) * (SLOT - 6)
			draw_rect(Rect2(box.position.x + 3, box.end.y - 3 - filled, SLOT - 6, filled), Color(tint, .38 + pulse * .2))
		_icon(move[1], centre + Vector2(0, -2), SLOT * .3, tint if ready else Color(.62, .66, .72))
		if not ready and not ultimate:
			# The unrecovered share sweeps away clockwise from twelve o'clock.
			var share: float = clampf(left / maxf(peaks[index], .01), 0.0, 1.0)
			_pie(centre, SLOT * .72, share, Color(0, 0, 0, .58))
			var count: String = "%.1f" % left if left < 1.0 else str(ceili(left))
			_text(font, count, centre + Vector2(0, 7), 20, Color(1, 1, 1, .95))
		if flashes[index] > 0.0:
			var t: float = 1.0 - flashes[index] / FLASH_SECONDS
			_panel(box.grow(2.0 + t * 8.0), Color(0, 0, 0, 0), Color(tint, 1.0 - t), 3.0)
		# Keycap in the corner.
		var cap: Rect2 = Rect2(box.end - Vector2(17, 17), Vector2(15, 15))
		_panel(cap, Color(.9, .92, .95, .92), Color(0, 0, 0, 0), 0.0)
		_text(font, move[0], cap.get_center() + Vector2(0, 4.5), 11, Color(.06, .07, .09))


func _panel(box: Rect2, fill: Color, border: Color, width: float) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(int(width))
	style.set_corner_radius_all(7 if box.size.x > 30 else 3)
	style.anti_aliasing = true
	draw_style_box(style, box)


func _pie(centre: Vector2, radius: float, share: float, color: Color) -> void:
	if share <= 0.0:
		return
	var points: PackedVector2Array = [centre]
	var steps: int = maxi(2, ceili(40 * share))
	for step in range(steps + 1):
		var angle: float = -PI * .5 + TAU * (1.0 - share) + TAU * share * step / steps
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	# Clip to the tile by drawing only inside it: the radius reaches the corners.
	if share >= 1.0:
		draw_colored_polygon(_square(centre, SLOT * .5 - 3), color)
		return
	for inside: PackedVector2Array in Geometry2D.intersect_polygons(points, _square(centre, SLOT * .5 - 3)):
		if inside.size() >= 3:
			draw_colored_polygon(inside, color)


func _square(centre: Vector2, half: float) -> PackedVector2Array:
	return [centre + Vector2(-half, -half), centre + Vector2(half, -half), centre + Vector2(half, half), centre + Vector2(-half, half)]


func _text(font: Font, text: String, baseline_centre: Vector2, size: int, color: Color) -> void:
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string_outline(font, baseline_centre - Vector2(width * .5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(0, 0, 0, color.a * .7))
	draw_string(font, baseline_centre - Vector2(width * .5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _arrowhead(tip: Vector2, direction: Vector2, size: float, color: Color) -> void:
	var back: Vector2 = -direction.normalized() * size
	var side: Vector2 = Vector2(-back.y, back.x) * .65
	draw_colored_polygon([tip, tip + back + side, tip + back - side], color)


## Each move's glyph, about 2r across, centred on c.
func _icon(kind: String, c: Vector2, r: float, color: Color) -> void:
	var w: float = maxf(2.0, r * .16)
	match kind:
		"reply_all":
			# The reply-all arrow: two heads pointing back, one tail curling down.
			var y: float = c.y - r * .25
			_arrowhead(Vector2(c.x - r * .95, y), Vector2.LEFT, r * .5, color)
			_arrowhead(Vector2(c.x - r * .4, y), Vector2.LEFT, r * .5, color)
			draw_line(Vector2(c.x - r * .5, y), Vector2(c.x + r * .2, y), color, w * 1.2, true)
			draw_arc(Vector2(c.x + r * .2, y + r * .75), r * .75, -PI * .5, 0.0, 16, color, w * 1.2, true)
		"dash":
			# Speed lines and a hard chevron: someone else's problem, fast.
			for row: float in [-.45, 0.0, .45]:
				var length: float = r * (.75 if row == 0.0 else .5)
				draw_line(c + Vector2(-r * .95, r * row), c + Vector2(-r * .95 + length, r * row), color, w, true)
			draw_polyline([c + Vector2(-r * .05, -r * .75), c + Vector2(r * .8, 0), c + Vector2(-r * .05, r * .75)], color, w * 1.3, true)
		"circle":
			# A loop that comes back round to where it started.
			var radius: float = r * .78
			var finish: float = PI * 1.38
			draw_arc(c, radius, -PI * .3, finish, 28, color, w * 1.2, true)
			var tangent: Vector2 = Vector2(-sin(finish), cos(finish))
			_arrowhead(c + Vector2(cos(finish), sin(finish)) * radius + tangent * r * .22, tangent, r * .5, color)
		"machine":
			# A laptop with a green check: works on mine.
			var screen: Rect2 = Rect2(c + Vector2(-r * .78, -r * .8), Vector2(r * 1.56, r * 1.1))
			draw_rect(screen, color, false, w)
			draw_polyline([c + Vector2(-r, r * .55), c + Vector2(r, r * .55), c + Vector2(r * .8, r * .78), c + Vector2(-r * .8, r * .78), c + Vector2(-r, r * .55)], color, w, true)
			draw_polyline([c + Vector2(-r * .38, -r * .25), c + Vector2(-r * .08, r * .05), c + Vector2(r * .42, -r * .5)], color, w * 1.2, true)
		"rollback":
			# Rewind.
			for offset: float in [-.05, .75]:
				var tip: Vector2 = c + Vector2(r * (offset - .8), 0)
				draw_colored_polygon([tip, tip + Vector2(r * .85, -r * .7), tip + Vector2(r * .85, r * .7)], color)
