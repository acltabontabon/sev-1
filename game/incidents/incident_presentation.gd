extends CanvasLayer
## Authored Incident 001 beats only. Gameplay owns stages, damage and choices.
const DESK_SCREEN: Script = preload("res://game/ui/desk_screen.gd")
const CHARACTER = preload("res://game/player/character_presentation.gd")
const RECORD_VISUAL: PackedScene = preload("res://game/enemies/record_visual.tscn")
const SEAT: Vector3 = Vector3(-2.5, .05, 10.27)
const MONITOR: Vector3 = Vector3(-2.5, 1.26, 9.19)
const FACE: Vector3 = Vector3(-2.5, 1.48, 10.2)
const OPENING_LENGTH: float = 36.0
## Opening shots: start, camera from, camera to, look from, look to, field of view.
## Each shot eases from its first pose to its second until the next shot cuts in.
const SHOTS: Array = [
	[0.0, Vector3(3.6, 2.7, 14.8), Vector3(2.6, 2.4, 14.0), Vector3(-2.3, 1.0, 9.8), Vector3(-2.4, 1.1, 9.7), 46.0],
	[4.4, Vector3(-1.62, 1.78, 10.95), Vector3(-1.78, 1.7, 10.62), MONITOR + Vector3(.12, 0, 0), MONITOR + Vector3(.08, 0, 0), 36.0],
	[8.4, Vector3(-2.02, 1.8, 8.72), Vector3(-2.2, 1.74, 8.92), FACE, FACE + Vector3(0, .02, 0), 40.0],
	[11.6, Vector3(-2.3, 1.42, 10.32), Vector3(-2.38, 1.36, 10.02), MONITOR, MONITOR, 33.0],
	[13.4, Vector3(-2.5, 1.27, 9.95), Vector3(-2.5, 1.27, 9.82), MONITOR, MONITOR, 42.0],
	[16.9, Vector3(-2.12, 1.68, 9.02), Vector3(-2.24, 1.62, 9.18), FACE, FACE, 36.0],
	[18.6, Vector3(-2.14, 1.24, 9.98), Vector3(-2.18, 1.22, 9.84), Vector3(-2.3, 1.13, 9.19), Vector3(-2.3, 1.12, 9.19), 34.0],
	[21.4, Vector3(-2.15, 1.68, 8.98), Vector3(-2.26, 1.62, 9.18), FACE, FACE + Vector3(0, -.03, 0), 38.0],
	[26.2, Vector3(-1.1, 1.85, 11.7), Vector3(-1.35, 1.95, 11.0), Vector3(-3.0, 2.0, -14.5), Vector3(-3.2, 2.1, -14.5), 46.0],
	[28.0, Vector3(-1.55, .95, -8.0), Vector3(-1.95, 1.05, -8.9), Vector3(-4.1, 1.75, -14.6), Vector3(-4.1, 1.45, -13.8), 44.0],
	[30.4, Vector3(-.75, 1.05, 11.35), Vector3(-.95, 1.15, 11.05), Vector3(-2.45, 1.35, 10.2), Vector3(-2.45, 1.5, 10.25), 44.0],
	[32.4, Vector3(-2.25, 1.55, 12.4), Vector3(-2.1, 2.25, 13.5), Vector3(-2.6, 1.5, 6.0), Vector3(-2.6, 1.3, 4.0), 55.0],
]
## Timed beats, fired once each as the opening clock crosses them.
const BEATS: Array = [
	[.5, "say", "opening"], [4.6, "post", "friday"], [4.9, "say", "friday"],
	[8.4, "pose", CHARACTER.Pose.RELAX], [8.6, "say", "relief"], [11.4, "pose", CHARACTER.Pose.TYPING],
	[13.0, "click", ""], [13.4, "alarm", ""], [13.6, "say", "alert"],
	[16.9, "pose", CHARACTER.Pose.ALERT], [17.0, "acknowledged", ""], [18.7, "post", "eta"], [18.9, "say", "eta"], [20.3, "typing", ""],
	[21.5, "post", "leadership"], [21.5, "say", "leadership"], [24.2, "pose", CHARACTER.Pose.SLUMP],
	[24.7, "say", "start"], [26.2, "pose", CHARACTER.Pose.ALERT], [26.3, "flicker", ""],
	[28.0, "emerge", ""], [28.6, "boom", ""], [30.5, "pose", CHARACTER.Pose.ARMED],
]
const POSTS: Dictionary = {
	"friday": ["People Ops", "Happy Friday, team! Enjoy your well-deserved weekend!", Color(.78, .62, 1), "16:59"],
	"eta": ["Management", "Hi! Just checking if we have an ETA.", Color(1, .62, .78), "17:00"],
	"leadership": ["Management", "Leadership is already asking for updates.", Color(1, .62, .78), "17:00"],
}
var incident: Node3D
var voice: Node
# Compatibility views for the existing narrative regression harness.
var seen: Dictionary:
	get: return voice.seen
var queue: Array[String]:
	get: return voice.queue
var current_line: String:
	get: return voice.current_line
var line_left: float:
	get: return voice.line_left
var opening_seen: bool = false
## Set by the front end from device preferences; the first full viewing cannot be skipped.
var skip_unlocked: bool = false
var boss_seen: bool = false
var short_opening: bool = false
var boss_length: float = 6
var camera: Camera3D
var panel: PanelContainer
var caption: Label
var title: Label
var hint: Label
var timecode: Label
var card: VBoxContainer
var letterbox: Array[ColorRect] = []
var fade: ColorRect
var ambient: AudioStreamPlayer
var cue: AudioStreamPlayer
var stings: Array[AudioStreamPlayer] = []
var fragments: Array[MeshInstance3D] = []
var monitors: Array[MeshInstance3D] = []
var screen_material: StandardMaterial3D
var desk: Node3D
var emerging: Node3D
var beat: int = 0
var shake: float = 0.0
var pools: Array[Light3D] = []
var pool_energy: Array[float] = []
var dark: Material = preload("res://game/rooms/office/black.tres")
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var corridor_lights: Array[OmniLight3D] = []
var corridor_leds: Array[MeshInstance3D] = []
var alert_material: Material = preload("res://game/rooms/office/alert.tres")


func _ready() -> void:
	incident = get_parent()
	voice = incident.voice
	layer = 4
	camera = Camera3D.new()
	camera.fov = 55
	incident.add_child(camera)
	for side in [0, 1]:
		var bar: ColorRect = ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if side == 0 else Control.PRESET_BOTTOM_WIDE)
		bar.hide()
		add_child(bar)
		letterbox.append(bar)
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size", 19)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(caption)
	_caption_layout(false)
	title = Label.new()
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -450
	title.offset_right = 450
	title.offset_top = 45
	title.offset_bottom = 150
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = "Headline"
	title.add_theme_font_size_override("font_size", 34)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	hint = Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hint.offset_left = -330
	hint.offset_right = -28
	hint.offset_top = 18
	hint.offset_bottom = 44
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.theme_type_variation = "Eyebrow"
	hint.text = "TAB — SKIP"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	timecode = Label.new()
	timecode.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	timecode.offset_left = 40
	timecode.offset_right = 640
	timecode.offset_top = 22
	timecode.offset_bottom = 46
	timecode.theme_type_variation = "Eyebrow"
	timecode.add_theme_font_size_override("font_size", 16)
	timecode.hide()
	add_child(timecode)
	card = VBoxContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.offset_left = -500
	card.offset_right = 500
	card.offset_top = -170
	card.offset_bottom = 170
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for entry: Array in [["INCIDENT 001  ·  THE MISSING TRANSACTION", "Eyebrow", 0], ["SEV-1", "DisplayTitle", 190], ["Works on My Machine", "Subhead", 30]]:
		var label: Label = Label.new()
		label.text = entry[0]
		label.theme_type_variation = entry[1]
		if entry[2] > 0:
			label.add_theme_font_size_override("font_size", entry[2])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(label)
	card.hide()
	add_child(card)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.hide()
	add_child(fade)
	ambient = AudioStreamPlayer.new()
	ambient.bus = &"Effects"
	ambient.stream = preload("res://assets/audio/office_air.wav")
	ambient.volume_db = -28
	add_child(ambient)
	cue = AudioStreamPlayer.new()
	cue.bus = &"Effects"
	cue.volume_db = -20
	add_child(cue)
	for index in range(3):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"Effects"
		add_child(player)
		stings.append(player)
	screen_material = StandardMaterial3D.new()
	screen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Only workstation screen surfaces; geometry and navigation remain untouched.
	for workstation in incident.room.get_children():
		if "Workstation" in workstation.name:
			for mesh in workstation.find_children("*", "MeshInstance3D", true, false):
				if str(mesh.name).begins_with("Code"):
					monitors.append(mesh)
	for mesh in monitors:
		mesh.material_override = screen_material
	desk = DESK_SCREEN.new()
	desk.name = "DeskScreen"
	desk.position = Vector3(0, 1.26, -.192)
	incident.room.get_node("YourWorkstation").add_child(desk)
	for index in range(6):
		pools.append(incident.room.get_node("CeilingPool%d" % index))
		pool_energy.append(pools[index].light_energy)
	for index in range(4):
		corridor_lights.append(incident.room.get_node("CorridorLight%d" % index))
	for rack: Node in incident.room.get_children():
		if str(rack.name).begins_with("CorridorRack"):
			corridor_leds.append(rack.get_node("Leds"))
	emerging = RECORD_VISUAL.instantiate()
	var menace: OmniLight3D = OmniLight3D.new()
	menace.position = Vector3(0, 1.4, .8)
	menace.light_color = Color(1, .15, .08)
	menace.light_energy = 2.5
	menace.omni_range = 4.5
	emerging.add_child(menace)
	incident.add_child(emerging)
	emerging.hide()
	var fragment_material: StandardMaterial3D = StandardMaterial3D.new()
	fragment_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fragment_material.albedo_color = Color(.3, .8, .85)
	for index in range(8):
		var fragment: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(.35, .08, .18)
		fragment.mesh = box
		fragment.material_override = fragment_material
		fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		incident.add_child(fragment)
		fragment.hide()
		fragments.append(fragment)


func _caption_layout(cinematic: bool) -> void:
	# Film subtitles inside the letterbox during the opening; a side card in play.
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(.018, .035, .045, 0 if cinematic else .95)
	style.border_color = Color(.3, .75, .8)
	style.border_width_left = 0 if cinematic else 3
	style.set_content_margin_all(12)
	style.content_margin_left = 18
	panel.add_theme_stylebox_override("panel", style)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if cinematic else HORIZONTAL_ALIGNMENT_LEFT
	caption.add_theme_font_size_override("font_size", 24 if cinematic else 19)
	caption.add_theme_constant_override("outline_size", 6 if cinematic else 0)
	caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, .85))
	if cinematic:
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		panel.offset_left = -480
		panel.offset_right = 480
		panel.offset_top = -168
		panel.offset_bottom = -72
	else:
		panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		panel.offset_left = -454
		panel.offset_right = -24
		panel.offset_top = -252
		panel.offset_bottom = -132


func reset_story() -> void:
	release_camera()
	short_opening = opening_seen
	voice.clear(true)
	panel.hide()
	title.hide()
	hint.hide()
	ambient.stop()
	cue.stop()
	beat = 0
	shake = 0
	_end_opening()
	_restore_corridor()
	desk.reset_screen()
	desk.set_live(true)
	var character: Node3D = incident.player.get_node("Visual/Character")
	if short_opening:
		incident.player.position = Vector3(-1.8, .05, 10.8)
		incident.player.visual.rotation.y = .35
	else:
		incident.player.position = SEAT
		incident.player.visual.rotation.y = 0
		character.story_pose = CHARACTER.Pose.TYPING
		character.sit = 1.0
	set_screens(Color(.12, .42, .38))


func _restore_lights() -> void:
	for index in range(pools.size()):
		pools[index].light_energy = pool_energy[index]
		incident.room.get_node("Diffuser%d" % index).material_override = null


func _restore_corridor() -> void:
	for light in corridor_lights:
		light.light_color = Color(.55, .75, 1)
		light.light_energy = 1.6
	for led in corridor_leds:
		led.material_override = null


func set_screens(color: Color) -> void:
	screen_material.albedo_color = color


func say(id: String, _priority: bool = false) -> void:
	voice.request(id)


func sound(path: String) -> void:
	if DisplayServer.get_name() != "headless":
		cue.stream = load(path)
		cue.play()


## Short one-off effects on a small rotating pool, so stings never cut each other off.
func sting(stream: AudioStream, volume: float = -10.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var player: AudioStreamPlayer = stings.pop_front()
	player.stream = stream
	player.volume_db = volume
	player.play()
	stings.append(player)


func release_camera() -> void:
	incident.player.narrative_hold = false
	incident.player.get_node("Visual/Character").story_pose = 0
	incident.main.get_node("HUD").visible = true
	if camera != null and camera.current:
		incident.player.get_node("CameraRig/SpringArm3D/Camera3D").make_current()


func opening_duration() -> float:
	return 3.0 if short_opening else OPENING_LENGTH


func declare_incident() -> void:
	if incident.alert_played:
		return
	incident.alert_played = true
	incident.light_target = 2.3
	incident._dashboard("THREE SYSTEMS\nDISAGREE", "CRITICAL INCIDENT / SEV-1")
	set_screens(Color(.55, .08, .035))
	desk.alarm(true)
	if DisplayServer.get_name() != "headless":
		incident.get_node("AlertSound").play()


func skip() -> void:
	if incident.terminal() or incident.modal_pending():
		return
	if incident.stage == incident.Stage.ALERT:
		opening_seen = true
		declare_incident()
		incident._enter(incident.Stage.ENCOUNTER_ONE)
	elif incident.stage == incident.Stage.BOSS and not is_instance_valid(incident.active_enemy):
		voice.clear()
		boss_seen = true
		incident.boss_triggered = true
		incident.spawn_delay = 0
		incident._spawn()


func stage_changed() -> void:
	release_camera()
	voice.clear()
	match incident.stage:
		incident.Stage.ENCOUNTER_ONE:
			opening_seen = true
			declare_incident()
			_end_opening()
		incident.Stage.INVESTIGATION:
			say("investigate")
		incident.Stage.ENCOUNTER_TWO:
			say("evidence_confirmed")
			say("contain")
			set_screens(Color(.65, .12, .04))
		incident.Stage.BOSS:
			say("gate_open")
			boss_length = 1.5 if boss_seen else 6.0
			incident.light_target = 3.7
			set_screens(Color(.45, .12, .3))
			sting(preload("res://assets/audio/sfx/door_open.ogg"), -4)
		incident.Stage.RESOLVED, incident.Stage.FAILED:
			say("victory" if incident.stage == incident.Stage.RESOLVED else "defeat")
			say("postmortem")
			ambient.stop()
			set_screens(Color(.12, .42, .38) if incident.stage == incident.Stage.RESOLVED else Color(.25, .05, .025))
			sound("res://assets/audio/resolved.wav" if incident.stage == incident.Stage.RESOLVED else "res://assets/audio/boss_arrival.wav")


## The engineer crossed into the vault: the arrival clock starts here.
func vault_entered() -> void:
	voice.clear()
	say("variance_intro")
	sound("res://assets/audio/boss_arrival.wav")


func used(key: String) -> void:
	var streams: Dictionary = {"coffee": preload("res://assets/audio/sfx/ui_confirm.ogg"), "vending": preload("res://assets/audio/sfx/ui_error.ogg"), "microwave": preload("res://assets/audio/sfx/ui_error.ogg"), "poster": preload("res://assets/audio/sfx/chat_ping_soft.ogg")}
	sting(streams[key], -8)


## Environmental storytelling that runs during play: the gate, the corridor, the sparks.
func _environment(delta: float) -> void:
	var gate: Node3D = incident.room.get_node("VaultGate")
	var open: bool = incident.stage == incident.Stage.BOSS
	gate.position.y = move_toward(gate.position.y, 5.9 if open else 2.0, delta * 2.2)
	var z: float = incident.player.global_position.z
	if open:
		# Racks fail as the engineer passes them; the light ahead turns red last.
		for index in range(corridor_lights.size()):
			var light: OmniLight3D = corridor_lights[index]
			var passed: bool = z < light.position.z + 2.5
			light.light_color = light.light_color.lerp(Color(1, .12, .08) if passed else Color(.55, .75, 1), delta * 3.0)
			light.light_energy = move_toward(light.light_energy, .7 if passed else 1.6, delta * 2.0)
		for led in corridor_leds:
			led.material_override = alert_material if led.global_position.z > z - 1.5 and z < -16.5 else null
		if z < -21.5:
			say("deployment")
	if z < -14 and incident.player.global_position.x > 3:
		for index in range(2):
			var flicker: bool = rng.randf() < .18
			incident.room.get_node("SparkLight%d" % index).light_energy = rng.randf_range(1.2, 3.0) if flicker else 0.0
			incident.room.get_node("Spark%d" % index).visible = flicker


func _end_opening() -> void:
	# However the opening ends, play starts in a clean, lit, readable office.
	emerging.hide()
	for fragment in fragments:
		fragment.hide()
	card.hide()
	timecode.hide()
	fade.hide()
	for bar in letterbox:
		bar.hide()
	_restore_lights()
	_caption_layout(false)
	desk.show_logoff(false)
	desk.set_live(false)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB and not get_tree().paused:
		if incident.stage == incident.Stage.ALERT and not short_opening and not skip_unlocked:
			return
		skip()
		get_viewport().set_input_as_handled()


func _fire(entry: Array) -> void:
	var character: Node3D = incident.player.get_node("Visual/Character")
	match entry[1]:
		"say":
			say(entry[2])
		"post":
			var post: Array = POSTS[entry[2]]
			desk.post(post[0], post[1], post[2], post[3])
			sting(preload("res://assets/audio/sfx/chat_ping.ogg"), -9)
		"pose":
			character.story_pose = entry[2]
		"click":
			sting(preload("res://assets/audio/sfx/ui_confirm.ogg"), -12)
		"alarm":
			declare_incident()
			sting(preload("res://assets/audio/sfx/computer_noise.ogg"), -20)
			shake = .6
		"acknowledged":
			desk.alarm_compact()
		"typing":
			desk.set_typing("Leadership is typing…")
		"flicker":
			sting(preload("res://assets/audio/sfx/light_relay.ogg"), -8)
		"emerge":
			emerging.show()
			sting(preload("res://assets/audio/sfx/glitch_a.ogg"), -6)
		"boom":
			shake = 1.0
			sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -4)
			sting(preload("res://assets/audio/sfx/low_boom.ogg"), -6)


func _opening(time: float, delta: float) -> void:
	incident.player.narrative_hold = true
	incident.main.get_node("HUD").visible = false
	while beat < BEATS.size() and time >= BEATS[beat][0]:
		_fire(BEATS[beat])
		beat += 1
	# Camera: authored shot, eased within its duration; the last second hands over to play.
	var index: int = 0
	while index + 1 < SHOTS.size() and time >= SHOTS[index + 1][0]:
		index += 1
	var shot: Array = SHOTS[index]
	var end: float = SHOTS[index + 1][0] if index + 1 < SHOTS.size() else OPENING_LENGTH
	var weight: float = smoothstep(0, 1, clampf((time - shot[0]) / (end - shot[0]), 0, 1))
	camera.fov = shot[5]
	camera.position = shot[1].lerp(shot[2], weight)
	camera.look_at(shot[3].lerp(shot[4], weight))
	shake = maxf(0, shake - delta * 1.6)
	if shake > 0:
		camera.rotation += Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), 0) * .012 * shake
	if time > OPENING_LENGTH - 1.0:
		var target: Camera3D = incident.player.get_node("CameraRig/SpringArm3D/Camera3D")
		var handover: float = smoothstep(OPENING_LENGTH - 1.0, OPENING_LENGTH, time)
		camera.global_transform = camera.global_transform.interpolate_with(target.global_transform, handover)
		camera.fov = lerpf(camera.fov, target.fov, handover)
	camera.make_current()
	# Frame: fade from black, letterbox in, out again for the handover.
	fade.visible = time < 1.4
	fade.color.a = 1.0 - smoothstep(.2, 1.4, time)
	var bars: float = 66.0 * smoothstep(0, 1.0, time) * (1.0 - smoothstep(OPENING_LENGTH - 1.2, OPENING_LENGTH - .2, time))
	for side in [0, 1]:
		letterbox[side].show()
		letterbox[side].offset_top = 0.0 if side == 0 else -bars
		letterbox[side].offset_bottom = bars if side == 0 else 0.0
	# Diegetic clock: 4:59 PM runs out exactly when the pager fires.
	var seconds: int = 41 + int(minf(time, 13.39) * 18.0 / 13.4)
	var clock: String = "16:59:%02d" % seconds if time < 13.4 else "17:00:%02d" % int(time - 13.4)
	timecode.visible = time > 1.0 and time < 32.4
	timecode.text = "FRIDAY  ·  " + clock + "  ·  PAYMENTS PLATFORM"
	desk.set_clock("FRI " + clock.left(5))
	desk.show_logoff(time >= 11.6 and time < 13.4, smoothstep(11.8, 12.9, time), time >= 13.0)
	# Lights die from the desk toward Operations: a bounded flicker, then dim pools.
	for order in range(6):
		var light: int = [1, 0, 3, 2, 4, 5][order]
		var start: float = 26.3 + order * .22
		if time >= start and time < OPENING_LENGTH - 1.0:
			var lit: bool = time < start + .5 and fmod(time - start, .14) < .06
			pools[light].light_energy = pool_energy[light] * (1.0 if lit else .12)
			incident.room.get_node("Diffuser%d" % light).material_override = null if lit else dark
	if time >= OPENING_LENGTH - 1.0:
		_restore_lights()
	if time >= 26.8 and time < 28.8:
		var states: Array[String] = ["SUCCESS", "FAILED", "NOT FOUND"]
		var flip: int = int(time * 9.0) % 3
		incident.room.get_node("Critical").text = states[flip]
		incident.room.get_node("Critical").modulate = [Color(.3, .95, .7), Color(1, .3, .12), Color(1, .8, .3)][flip]
		incident.room.get_node("Impossible").text = "LEDGER: %s" % states[(flip + 1) % 3]
		incident.room.get_node("ETA").text = "PAYMENTS: %s" % states[(flip + 2) % 3]
		if fmod(time, .25) < delta:
			sting(preload("res://assets/audio/sfx/glitch_b.ogg"), -14)
	elif time >= 28.8 and incident.room.get_node("Critical").text != "THREE SYSTEMS\nDISAGREE":
		incident._dashboard("THREE SYSTEMS\nDISAGREE", "CRITICAL INCIDENT / SEV-1")
	# Something steps out of the production dashboard: visual only, never an actor.
	if emerging.visible:
		var rise: float = smoothstep(28.0, 30.2, time)
		emerging.position = Vector3(-4.1 + rng.randf_range(-.06, .06) * (1.0 - rise), lerpf(.6, .05, rise), lerpf(-15.9, -13.5, rise))
		emerging.rotation.y = PI
		emerging.scale = Vector3.ONE * lerpf(.75, 1.3, rise)
		for part in range(fragments.size()):
			var angle: float = part * TAU / 8 + time * 2.0
			var radius: float = lerpf(.2, 2.6, smoothstep(28.0, 29.6, time))
			fragments[part].position = Vector3(-4.1, 2.6, -15.2) + Vector3(cos(angle) * radius, sin(angle * 1.5) * radius * .5, absf(sin(angle)) * radius * .6)
			fragments[part].rotation = Vector3(time * 3.0, angle, 0)
			fragments[part].visible = time < 30.4
		if time >= 32.4:
			emerging.hide()
	# Title card fades in over the rising shot.
	card.visible = time >= 32.6 and time < OPENING_LENGTH - .4
	card.modulate.a = smoothstep(32.6, 33.2, time) * (1.0 - smoothstep(OPENING_LENGTH - 1.2, OPENING_LENGTH - .4, time))


func _process(delta: float) -> void:
	for fragment in fragments:
		fragment.visible = false
	var visible_play: bool = not get_tree().paused and not incident.terminal() and not incident.modal_pending()
	panel.visible = visible_play and line_left > 0
	title.visible = false
	hint.visible = false
	if not visible_play:
		return
	if not ambient.playing and DisplayServer.get_name() != "headless":
		ambient.play()
	_environment(delta)
	var time: float = incident.stage_time
	if incident.stage == incident.Stage.ALERT:
		if short_opening:
			declare_incident()
			say("start")
			incident.main.get_node("HUD").visible = true
		else:
			_caption_layout(true)
			hint.visible = skip_unlocked
			_opening(time, delta)
	elif incident.stage == incident.Stage.BOSS and incident.boss_triggered and incident.boss_time < boss_length + 2:
		time = incident.boss_time
		title.show()
		title.text = "DISCREPANCY CONVERGING" if time < boss_length - 2 else "THE VARIANCE\nDifference detected. Explanation unavailable."
		hint.visible = not is_instance_valid(incident.active_enemy)
		if hint.visible:
			var center: Vector3 = incident.arrival_site() + Vector3.UP * 1.5
			for index in range(fragments.size()):
				var angle: float = index * TAU / 8 + time
				var radius: float = lerpf(2.0, .15, clampf(time / boss_length, 0, 1))
				fragments[index].position = center + Vector3(cos(angle) * radius, sin(angle * 2) * .6, sin(angle) * radius)
				fragments[index].rotation = Vector3(time, angle, 0)
				fragments[index].show()
		if is_instance_valid(incident.active_enemy):
			boss_seen = true
			title.text += "\n%d / %d" % [incident.active_enemy.health, incident.active_enemy.max_health]
			say("boss", true)
	if incident.stage == incident.Stage.ENCOUNTER_TWO and time > 18: say("visibility")
	if incident.stage == incident.Stage.BOSS and incident.boss_time > 22: say("rca")
	caption.text = voice.subtitle
	panel.visible = not voice.subtitle.is_empty()
