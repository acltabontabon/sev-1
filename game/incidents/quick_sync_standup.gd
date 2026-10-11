extends Node3D
## A bounded, skippable stand-up before the optional ambush. Local prerecorded speech;
## no gameplay timer or camera survives the scene or an incident restart.

const STEPS: Array = [
	["standup_facilitator", 0], ["standup_yesterday", 1], ["standup_point", -1],
	["standup_react", 2], ["standup_snap", 0],
]
var incident: Node3D
var camera: Camera3D
var speech: AudioStreamPlayer
var captions: CanvasLayer
var caption: Label
var step: int = -1
var left: float = 0.0
var finished: bool = false


func _ready() -> void:
	incident.player.narrative_hold = true
	incident.presentation.voice.clear()
	incident.main.get_node("HUD").hide()
	for host: Node3D in incident.sync_hosts:
		host.set_process(false)
		host.line.hide()
	camera = Camera3D.new()
	camera.fov = 58
	add_child(camera)
	speech = AudioStreamPlayer.new()
	speech.bus = &"Voice"
	speech.volume_db = -3
	add_child(speech)
	captions = CanvasLayer.new()
	captions.layer = 24
	add_child(captions)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 100
	panel.offset_right = -100
	panel.offset_top = -118
	panel.offset_bottom = -24
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(.015, .025, .035, .94)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	captions.add_child(panel)
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_override("font", preload("res://assets/fonts/inter_variable.ttf"))
	caption.add_theme_font_size_override("font_size", 22)
	panel.add_child(caption)
	_next()


func _next() -> void:
	step += 1
	if step >= STEPS.size():
		finish()
		return
	var entry: Dictionary = incident.presentation.voice.lines[STEPS[step][0]]
	caption.text = "%s: %s\nTAB · skip stand-up" % [entry.character, entry.subtitle]
	captions.visible = incident.presentation.voice.subtitles_enabled
	var speaker: Node3D = incident.player if STEPS[step][1] == -1 else incident.sync_hosts[STEPS[step][1]]
	for host: Node3D in incident.sync_hosts:
		host.animator.play("ual/talking" if host == speaker else "ual/phone", .2)
	var eye: Vector3 = speaker.global_position + Vector3.UP * 1.15
	camera.global_position = Vector3(clampf(eye.x - 2.8, 19.6, 29.5), 2.3, clampf(eye.z + 3.2, -13.0, -3.3))
	if speaker == incident.player:
		camera.global_position.x = clampf(eye.x + 3.0, 19.6, 29.5)
	camera.look_at(eye)
	camera.current = true
	var toward: Vector3 = camera.global_position - speaker.global_position
	if speaker != incident.player:
		speaker.rotation.y = atan2(toward.x, toward.z)
	else:
		incident.player.visual.rotation.y = atan2(-toward.x, -toward.z)
	speech.stream = load(entry.audio)
	left = speech.stream.get_length() + .35
	if DisplayServer.get_name() != "headless":
		speech.play()


func _process(delta: float) -> void:
	if finished:
		return
	left -= delta
	if left <= 0:
		_next()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		finish()
		get_viewport().set_input_as_handled()


func finish() -> void:
	if finished:
		return
	finished = true
	speech.stop()
	_restore()
	incident.standup_scene = null
	incident.actors.erase(self)
	incident._begin_quick_sync()
	queue_free()


func cancel() -> void:
	if finished:
		return
	finished = true
	speech.stop()
	_restore()


func _restore() -> void:
	incident.player.narrative_hold = false
	incident.player.get_node("CameraRig/SpringArm3D/Camera3D").current = true
	incident.main.get_node("HUD").show()
	for host: Node3D in incident.sync_hosts:
		if is_instance_valid(host):
			host.set_process(true)


func _exit_tree() -> void:
	if not finished and is_instance_valid(incident):
		_restore()
