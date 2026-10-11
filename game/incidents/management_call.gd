extends Node3D
## A management call interrupts the engineer. Existing local voices, no puzzle or fight.
const CHARACTER = preload("res://game/player/rigged_engineer.gd")
var incident: Node3D
var active: bool = false
var completed: bool = false
var reveal_spoken: bool = false
var clock: float = 0.0
var beat: int = 0
var camera: Camera3D
var overlay: CanvasLayer
var call_card: PanelContainer
var caller: Label
var connection: Label
var participants: Label
var caption: Label
var manager: Dictionary = {}
var manager_pause: float = 0.0
var saved_position: Vector3
var saved_facing: float = 0.0


func _ready() -> void:
	incident = get_parent()
	camera = Camera3D.new()
	camera.near = .08
	add_child(camera)
	overlay = CanvasLayer.new()
	overlay.layer = 15
	add_child(overlay)
	for bottom in [false, true]:
		var bar: ColorRect = ColorRect.new()
		bar.color = Color.BLACK
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if bottom else Control.PRESET_TOP_WIDE)
		bar.offset_top = -112 if bottom else 0
		bar.offset_bottom = 0 if bottom else 52
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bar)
	call_card = PanelContainer.new()
	call_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	call_card.offset_left = -390
	call_card.offset_right = -32
	call_card.offset_top = 82
	call_card.offset_bottom = 260
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(.018, .028, .033, .96)
	style.border_color = Color(.28, .7, .68)
	style.border_width_left = 3
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	call_card.add_theme_stylebox_override("panel", style)
	overlay.add_child(call_card)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	call_card.add_child(column)
	_label(column, "SYNERGIZE  /  VOICE CALL", 13, Color(.45, .7, .72))
	caller = _label(column, "MORGAN", 32, Color(.94, .96, .96))
	connection = _label(column, "Management · Incoming call", 17, Color(.7, .8, .81))
	participants = _label(column, "4 missed calls", 15, Color(1, .64, .42))
	caption = Label.new()
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_left = 80
	caption.offset_right = -80
	caption.offset_top = -99
	caption.offset_bottom = -14
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 23)
	overlay.add_child(caption)
	reset()


func _label(parent: Control, text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func reset() -> void:
	if active:
		_release(false)
	active = false
	completed = false
	reveal_spoken = false
	clock = 0
	beat = 0
	overlay.hide()


func start() -> void:
	if active or completed:
		return
	active = true
	incident.inspected = true
	saved_position = incident.player.global_position
	saved_facing = incident.player.visual.rotation.y
	incident.player.melee.cancel()
	incident.player.clear_combo()
	incident.player.narrative_hold = true
	incident.player.get_node("Visual/Character").story_pose = CHARACTER.Pose.ARMED
	incident.main.get_node("HUD").hide()
	incident.presentation.feed.hide()
	incident.presentation.beat_shot = "management_call"
	incident.voice.clear()
	incident.presentation.sequence.clear()
	# The briefing is local to this run; retries may replay it.
	for id: String in ["handoff_find", "handoff_eta"]:
		incident.voice.seen.erase(id)
	manager = incident.coworkers.person("Manager")
	if not manager.is_empty():
		manager_pause = manager.pause
		manager.pause = 120.0
		incident.coworkers._play(manager, "ual/phone", .2, true)
	incident.objective = "Request containment"
	incident.console_marker.text = ""
	caller.text = "MORGAN"
	connection.text = "Containment authorization"
	participants.text = "NEXT · Stop the delivery outbreak"
	caption.text = "PAYMENT DELIVERY FAILED — MANAGEMENT IS CALLING\nTAB — skip"
	call_card.modulate.a = 1
	overlay.show()
	incident.presentation.sting(preload("res://assets/audio/sfx/chat_ping.ogg"), -3)
	incident.log_event("Management called for an incident update")
	_hero_shot()


func tick(delta: float) -> void:
	if not active:
		return
	clock += delta
	incident.player.narrative_hold = true
	if beat == 0:
		call_card.modulate.a = .8 + .2 * sin(clock * 9)
		_hero_shot()
		if clock >= .7:
			beat = 1
			call_card.modulate.a = 1
			caller.text = "DELIVERY FAILED"
			connection.text = "Payment missing · Source still active"
			incident.presentation.say("handoff_find")
			reveal_spoken = true
	elif beat == 1:
		_hero_shot()
		if incident.voice.current_line.is_empty() and incident.voice.queue.is_empty():
			beat = 2
			caller.text = "MORGAN"
			connection.text = "Management · Commitment required"
			participants.text = "Your reply changes the next fight"
			incident.presentation.say("handoff_eta")
	else:
		_manager_shot()
		if incident.voice.current_line.is_empty() and incident.voice.queue.is_empty():
			finish()
			return
	var spoken: String = incident.voice.subtitle
	if "\n" in spoken:
		spoken = spoken.substr(spoken.find("\n") + 1)
	var who: String = "YOU" if beat == 1 else "MORGAN"
	caption.text = (who + ": " + spoken if not spoken.is_empty() else "") + "\nTAB — skip"


func _hero_shot() -> void:
	var target: Vector3 = incident.player.global_position + Vector3(0, 1.4, 0)
	var framing: Basis = incident.player.visual.global_basis.orthonormalized()
	_frame(target, target + framing * Vector3(-2.5, .25, -3.3), 44)


func _frame(target: Vector3, spot: Vector3, lens: float) -> void:
	var desired: float = target.distance_to(spot)
	var hit: Dictionary = incident.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(target, spot, 257))
	if not hit.is_empty():
		spot = hit.position + (target - hit.position).normalized() * .25
		var ratio: float = desired / maxf(target.distance_to(spot), .25)
		lens = minf(85, rad_to_deg(2 * atan(tan(deg_to_rad(lens) * .5) * ratio)))
	camera.global_position = spot
	camera.look_at(target)
	camera.fov = lens
	camera.make_current()


func _manager_shot() -> void:
	if manager.is_empty():
		_hero_shot()
		return
	var body: Node3D = manager.body
	var forward: Vector3 = body.global_basis.z.normalized()
	var spot: Vector3 = body.global_position + forward * 3.1 + body.global_basis.x.normalized() * 1.1 + Vector3.UP * 1.65
	_frame(body.global_position + Vector3.UP * 1.25, spot, 46)


func _release(restore_position: bool = true) -> void:
	incident.player.narrative_hold = false
	incident.player.get_node("Visual/Character").story_pose = CHARACTER.Pose.NONE
	if restore_position:
		incident.player.visual.rotation.y = saved_facing
		incident.player.global_position = saved_position
	if not manager.is_empty():
		manager.pause = manager_pause
		manager = {}
	incident.player.get_node("CameraRig/SpringArm3D/Camera3D").make_current()
	incident.main.get_node("HUD").show()
	incident.presentation.feed.show()
	if incident.presentation.beat_shot == "management_call":
		incident.presentation.beat_shot = ""
	incident.voice.clear()
	incident.presentation.sequence.clear()
	overlay.hide()


func finish() -> void:
	if not active:
		return
	active = false
	completed = true
	_release()
	incident.objective = "Reply to Management"
	incident.message = "Delivery is still making monsters. Choose your containment commitment."
	incident.log_event("Management requested an ETA before the missing payment was contained")
	incident._offer_corporate()
