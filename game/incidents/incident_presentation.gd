extends CanvasLayer
## Authored Incident 001 beats only. Gameplay owns stages, damage and choices.
const DESK_SCREEN: Script = preload("res://game/ui/desk_screen.gd")
const FEED: Script = preload("res://game/ui/notification_feed.gd")
const ALERT_SENDERS: Array[String] = ["MONITORING / SEV-1", "PRODUCTION SYSTEM", "STATUS PAGE", "THE VARIANCE"]
const CHARACTER = preload("res://game/player/rigged_engineer.gd")
const RECORD_VISUAL: PackedScene = preload("res://game/enemies/record_visual.tscn")
const SEAT: Vector3 = Vector3(-2.5, .05, 10.27)
const MONITOR: Vector3 = Vector3(-2.5, 1.26, 9.19)
## Where the seated engineer's face is (rigged_engineer.SEATED_OFFSET lifts him onto the cushion).
const FACE: Vector3 = Vector3(-2.5, 1.63, 9.92)
const OPENING_LENGTH: float = 36.0
## Opening shots: start, camera from, camera to, look from, look to, field of view.
## Each shot eases from its first pose to its second until the next shot cuts in.
const SHOTS: Array = [
	[0.0, Vector3(3.6, 2.7, 14.8), Vector3(2.6, 2.4, 14.0), Vector3(-2.3, 1.0, 9.8), Vector3(-2.4, 1.1, 9.7), 46.0],
	[4.4, Vector3(-1.62, 1.95, 10.7), Vector3(-1.78, 1.87, 10.38), MONITOR + Vector3(.12, 0, 0), MONITOR + Vector3(.08, 0, 0), 36.0],
	[8.4, Vector3(-1.98, 1.95, 8.25), Vector3(-2.16, 1.9, 8.45), FACE, FACE + Vector3(0, .02, 0), 42.0],
	[11.6, Vector3(-2.26, 1.55, 9.98), Vector3(-2.36, 1.49, 9.74), MONITOR, MONITOR, 33.0],
	[13.4, Vector3(-2.5, 1.27, 9.95), Vector3(-2.5, 1.27, 9.82), MONITOR, MONITOR, 42.0],
	[16.9, Vector3(-2.08, 1.85, 8.5), Vector3(-2.2, 1.79, 8.68), FACE, FACE, 38.0],
	[18.6, Vector3(-2.12, 1.38, 9.7), Vector3(-2.16, 1.36, 9.58), Vector3(-2.3, 1.13, 9.19), Vector3(-2.3, 1.12, 9.19), 34.0],
	[21.4, Vector3(-2.1, 1.85, 8.45), Vector3(-2.22, 1.79, 8.68), FACE, FACE + Vector3(0, -.03, 0), 40.0],
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
var feed: Control
var pinger: AudioStreamPlayer
var music: AudioStreamPlayer
var music_track: String = ""
const TRACKS: Dictionary = {"tension": preload("res://assets/audio/music/tension_bed.wav"), "boss": preload("res://assets/audio/music/boss_pulse.wav")}
## Short authored camera moments during play: [kind, elapsed]. Never during combat.
var beat_shot: String = ""
var beat_time: float = 0.0
var ending_from: Transform3D
var slowmo_until: int = 0
var vault_lights: Array[OmniLight3D] = []
var vault_energy: Array[float] = []
## Lines that must follow each other without competing for the bounded voice queue.
var sequence: Array[String] = []
var corridor_lights: Array[OmniLight3D] = []
var corridor_leds: Array[MeshInstance3D] = []
var alert_material: Material = preload("res://game/rooms/office/alert.tres")
## Finisher kill cam: a beat of slow motion from a low side angle, then straight back.
const KILLCAM_SECONDS: float = 1.9
var killcam_in_headless: bool = false
var killcam_length: float = KILLCAM_SECONDS
var killcam_punch: Vector3
var killcam_victim: Vector3
var killcam_roll: float = 0.0
var killcam_turn: float = 0.0
var killcam_facing: float = 0.0
var killcam_hero: bool = false
var killcam_ready: int = 0
var killcam_start: int = 0
var killcam_from: Vector3
var killcam_to: Vector3
var killcam_look: Vector3
var killflash: ColorRect
## Outbreak cutscene: the employee being watched, and the camera's dolly ends.
const OUTBREAK_LENGTH: float = 4.1
var outbreak_actor: CharacterBody3D
var outbreak_from: Vector3
var outbreak_to: Vector3
var outbreak_burst: bool = false
var lower_third: VBoxContainer
var lower_kicker: Label
var lower_name: Label
var lower_note: Label


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
	feed = FEED.new()
	add_child(feed)
	pinger = AudioStreamPlayer.new()
	pinger.bus = &"Effects"
	pinger.volume_db = -14
	add_child(pinger)
	voice.line_started.connect(_on_line_started)
	incident.player.specials.called.connect(_on_move_called)
	incident.player.specials.omnislash_step.connect(_on_omnislash_step)
	music = AudioStreamPlayer.new()
	music.bus = &"Music"
	music.volume_db = -60
	add_child(music)
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
	lower_third = VBoxContainer.new()
	lower_third.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	lower_third.offset_left = 72
	lower_third.offset_right = 760
	lower_third.offset_top = -230
	lower_third.offset_bottom = -78
	lower_third.alignment = BoxContainer.ALIGNMENT_END
	lower_third.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lower_third.add_theme_constant_override("separation", 0)
	for entry: Array in [["Eyebrow", 15], ["DisplayTitle", 58], ["Subhead", 22]]:
		var label: Label = Label.new()
		label.theme_type_variation = entry[0]
		label.add_theme_font_size_override("font_size", entry[1])
		label.add_theme_constant_override("outline_size", 8)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, .8))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lower_third.add_child(label)
	lower_kicker = lower_third.get_child(0)
	lower_name = lower_third.get_child(1)
	lower_note = lower_third.get_child(2)
	lower_third.hide()
	add_child(lower_third)
	killflash = ColorRect.new()
	killflash.color = Color(1, 1, 1, 0)
	killflash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	killflash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	killflash.hide()
	add_child(killflash)
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
		vault_lights.append(incident.room.get_node("VaultLight%d" % index))
		vault_energy.append(vault_lights[index].light_energy)
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
	if beat_shot == "killcam":
		_end_killcam()
	AudioServer.playback_speed_scale = 1.0
	beat_shot = ""
	outbreak_actor = null
	lower_third.hide()
	ElementFx.clear_slow_motion()
	slowmo_until = 0
	release_camera()
	short_opening = opening_seen
	voice.clear(true)
	feed.clear()
	sequence.clear()
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
	for index in range(vault_lights.size()):
		vault_lights[index].light_energy = vault_energy[index]
	incident.room.get_node("QuickSyncLight").light_energy = 1.6
	incident.room.get_node("ProjectorGlow").light_energy = 0.0
	for light in corridor_lights:
		light.light_color = Color(.55, .75, 1)
		light.light_energy = 1.6
	for led in corridor_leds:
		led.material_override = null


func set_screens(color: Color) -> void:
	screen_material.albedo_color = color


func say(id: String, _priority: bool = false) -> void:
	voice.request(id)


## Queue lines that belong together (a joke and its reply) so neither is dropped.
func say_sequence(ids: Array[String]) -> void:
	sequence.append_array(ids)


## The ALERT stage (full opening or quick retry) speaks in subtitles, not chat cards.
func in_cinematic() -> bool:
	return incident.stage == incident.Stage.ALERT


func _on_line_started(id: String) -> void:
	var entry: Dictionary = voice.lines[id]
	if in_cinematic() or entry.character == "NARRATOR":
		return
	var minutes: int = maxi(0, int((incident.elapsed - 13.4) / 20.0))
	feed.post(entry.character, entry.subtitle, voice.line_left, "%d:%02d PM" % [5 + minutes / 60, minutes % 60])
	if DisplayServer.get_name() != "headless" and entry.character != "ENGINEER":
		var alert: bool = entry.character in ALERT_SENDERS
		pinger.stream = preload("res://assets/audio/notification.wav") if alert else preload("res://assets/audio/sfx/chat_ping.ogg")
		pinger.pitch_scale = .85 if alert else 1.0
		pinger.play()


const STREAKS: Array[String] = ["", "", "DOUBLE MERGE", "TRIPLE MERGE", "QUAD DEPLOY", "MASS LAYOFF"]


## The kill itself: the body's label becomes a stamped death notice that slams in, a
## shock ring and flash where it fell, a crunch; streaks go to the HUD banner.
func kill_pop(actor: CharacterBody3D, stamp: String, minor: bool, streak: int) -> void:
	var at: Vector3 = actor.global_position
	var red: Color = Color(1, .3, .24)
	ElementFx.shockwave(actor, at + Vector3.UP * .05, Color(1, .95, .9), 1.4 if minor else 2.6, .3)
	ElementFx.flash(actor, at + Vector3.UP, Color(1, .9, .8), 2.0 if minor else 4.0, 4.0, .18)
	var label: Label3D = actor.label
	if minor or label == null or not label.visible:
		ElementFx.glyphs(actor, at + Vector3.UP * 1.4, red, [stamp], .7, 0.0)
	else:
		label.text = stamp
		label.modulate = red
		label.outline_modulate = Color(.15, 0, 0)
		var base: Vector3 = Vector3.ONE
		label.scale = base * 2.6
		var slam: Tween = label.create_tween()
		slam.set_ignore_time_scale(true)
		slam.tween_property(label, "scale", base * .9, .12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		slam.tween_property(label, "scale", base, .1)
	sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -14.0 if minor else -4.0)
	if not minor:
		sting(preload("res://assets/audio/sfx/glitch_b.ogg"), -12)
	if streak >= 2:
		var title: String = STREAKS[mini(streak, STREAKS.size() - 1)]
		if streak > STREAKS.size() - 1:
			title = "RESTRUCTURING ×%d" % streak
		incident.main.get_node("HUD").show_streak(title, streak)


## The omnislash: a hard cut to a fresh angle on every blink, framing the engineer and
## the cut. The return to the centre ends it; the slam's kill cam follows.
var omni_last_ms: int = 0


func _on_omnislash_step(at: Vector3, target: Vector3, index: int) -> void:
	if DisplayServer.get_name() == "headless" and not killcam_in_headless:
		return
	if index >= incident.player.specials.OMNI_SLASHES:
		if beat_shot == "omnislash":
			beat_shot = ""
			killflash.hide()
		return
	if not beat_shot.is_empty() and beat_shot != "omnislash":
		return
	beat_shot = "omnislash"
	omni_last_ms = Time.get_ticks_msec()
	var middle: Vector3 = (at + target) * .5 + Vector3.UP * 1.0
	var line: Vector3 = Vector3(target.x - at.x, 0, target.z - at.z)
	line = line.normalized() if line.length() > .1 else Vector3.FORWARD
	# Alternate sides, heights and distances so every cut reads as a new shot.
	var height: float = [.2, 1.6, -.3, 1.1, .5, 2.0, -.1][index % 7]
	var reach: float = [3.4, 4.2, 2.8, 3.8, 3.0, 4.6, 3.2][index % 7]
	var spot: Vector3 = middle
	# Alternate sides; skip angles that pass through a wall or a bystander's body.
	for attempt in range(6):
		var sign: float = (1.0 if (index + attempt) % 2 == 0 else -1.0)
		var turn: float = attempt * .5
		var side: Vector3 = line.cross(Vector3.UP).normalized().rotated(Vector3.UP, turn) * sign
		spot = middle + side * reach - line * (.6 if index % 3 == 0 else -.4) + Vector3.UP * height
		var hit: Dictionary = incident.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(middle, spot, 1))
		if not hit.is_empty():
			spot = hit.position + (middle - hit.position).normalized() * .3
		if not _blocks_view(spot, middle):
			break
	camera.global_position = spot
	camera.look_at(middle)
	camera.rotate_object_local(Vector3.BACK, deg_to_rad([6.0, -9.0, 4.0, -5.0, 10.0, -7.0, 3.0][index % 7]))
	camera.fov = 44.0
	camera.make_current()
	killflash.visible = true
	killflash.color = Color(.85, .8, 1, .18)
	incident.main.get_node("HUD").visible = false
	for side_bar in [0, 1]:
		letterbox[side_bar].visible = true
		letterbox[side_bar].offset_top = 0.0 if side_bar == 0 else -54.0
		letterbox[side_bar].offset_bottom = 54.0 if side_bar == 0 else 0.0


func _omnislash_shot() -> void:
	camera.make_current()
	incident.main.get_node("HUD").visible = false
	killflash.color.a = maxf(0.0, killflash.color.a - .02)
	# Safety: never strand the camera if the sequence stops early (reset, death).
	if Time.get_ticks_msec() - omni_last_ms > 900 or not incident.player.specials.omnislashing():
		beat_shot = ""
		killflash.hide()
		for bar in letterbox:
			bar.hide()
		release_camera()


## The ultimate's slam gets its own kill cam, on the engineer.
func _on_move_called(title: String, ultimate: bool) -> void:
	if ultimate and title.begins_with("GIT RESET"):
		var player: Node3D = incident.player
		kill_cam(player.global_position, player.global_position + player.camera_rig.global_basis.z * 4.0, true, 2.4)


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
	if beat_shot == "ending":
		beat_shot = ""
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
	if beat_shot == "outbreak":
		incident.end_outbreak()
		beat_time = maxf(beat_time, OUTBREAK_LENGTH - .5)
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
	sequence.clear()
	match incident.stage:
		incident.Stage.ENCOUNTER_ONE:
			opening_seen = true
			declare_incident()
			_end_opening()
			say_sequence(["status_ok", "status_except"])
		incident.Stage.INVESTIGATION:
			say("investigate")
		incident.Stage.ENCOUNTER_TWO:
			var reply: String = ["mgmt_commit", "mgmt_estimate", "mgmt_escalate"][clampi(incident.corporate_choice, 0, 2)]
			say_sequence(["not_found", "evidence_confirmed", reply])
			set_screens(Color(.65, .12, .04))
		incident.Stage.BOSS:
			say("gate_open")
			boss_length = 1.5 if boss_seen else 6.0
			incident.light_target = 3.7
			set_screens(Color(.45, .12, .3))
			sting(preload("res://assets/audio/sfx/door_open.ogg"), -4)
		incident.Stage.RESOLVED, incident.Stage.FAILED:
			if incident.stage == incident.Stage.RESOLVED:
				say_sequence(["victory_thanks", "victory", "postmortem", "postmortem_owner"])
			else:
				say_sequence(["defeat", "postmortem", "postmortem_owner"])
			ambient.stop()
			set_screens(Color(.12, .42, .38) if incident.stage == incident.Stage.RESOLVED else Color(.25, .05, .025))
			sound("res://assets/audio/resolved.wav" if incident.stage == incident.Stage.RESOLVED else "res://assets/audio/boss_arrival.wav")


const INTRODUCTIONS: Dictionary = {"blocker": "blocker_intro", "invite": "invite_intro", "scope": "scope_intro"}


## First sighting of a kind this run: a name card above it and one line of voice.
func introduce(kind: String, actor: Node3D) -> void:
	if INTRODUCTIONS.has(kind):
		say(INTRODUCTIONS[kind])
	elif kind == "record" and incident.stage == incident.Stage.ENCOUNTER_ONE:
		say("enemy")
	if kind != "record" and beat_shot != "outbreak":
		slow_beat()
	var card: Label3D = Label3D.new()
	card.text = "%s\n%s" % [actor.title, actor.motto]
	card.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	card.font = preload("res://assets/fonts/barlow_condensed_bold.ttf")
	card.font_size = 56
	card.pixel_size = .004
	card.outline_size = 12
	card.modulate = Color(1, .92, .8)
	card.position.y = 3.2
	card.no_depth_test = true
	actor.add_child(card)
	var fade: Tween = card.create_tween()
	fade.tween_property(card, "position:y", 3.6, 2.4)
	fade.parallel().tween_interval(2.0)
	fade.tween_property(card, "modulate:a", 0.0, .8)
	fade.tween_callback(card.queue_free)


func meeting_booked() -> void:
	sting(preload("res://assets/audio/sfx/chat_ping_soft.ogg"), -6)


## Quick Sync: doors shut, the lights go out, the projector becomes the only light.
func quick_sync(active: bool) -> void:
	incident.room.get_node("QuickSyncLight").light_energy = 0.0 if active else 1.6
	incident.room.get_node("ProjectorGlow").light_energy = 2.2 if active else 0.0
	sting(preload("res://assets/audio/sfx/door_close.ogg") if active else preload("res://assets/audio/sfx/door_open.ogg"), -4)
	say("quick_sync_start" if active else "quick_sync_end")


## The engineer crossed into the vault: the arrival clock starts here.
func vault_entered() -> void:
	voice.clear()
	say("variance_intro")
	sound("res://assets/audio/boss_arrival.wav")
	beat_shot = "vault"
	beat_time = 0.0


## A wave is due: cut to one employee as the ticket lands, watch them turn, hand back.
## Every other employee in the wave turns at the same moment, wherever they are.
const TRIGGERS: Dictionary = {"talk": "CONVERSATION ESCALATED", "hover": "YOU HOVERED. THEY NOTICED.", "timeout": "THEY GOT TIRED OF WAITING"}


func outbreak(actor: CharacterBody3D, area: String, reason: String = "") -> void:
	if not is_instance_valid(actor) or (not beat_shot.is_empty() and beat_shot != "outbreak"):
		return
	beat_shot = "outbreak"
	beat_time = 0.0
	outbreak_burst = false
	outbreak_actor = actor
	# Frame from the engineer's side when the view is clear, so the geography reads.
	var eye: Vector3 = actor.global_position + Vector3.UP * 1.1
	var toward: Vector3 = incident.player.global_position - actor.global_position
	toward.y = 0
	toward = toward.normalized() if toward.length() > .1 else Vector3.BACK
	var space: PhysicsDirectSpaceState3D = actor.get_world_3d().direct_space_state
	var chosen: Vector3 = toward
	for step in range(12):
		var angle: float = ceili(step / 2.0) * PI / 6.0 * (1.0 if step % 2 == 0 else -1.0)
		var direction: Vector3 = toward.rotated(Vector3.UP, angle)
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(eye, eye + direction * 5.8 + Vector3.UP * 1.1, 1)
		query.exclude = [actor.get_rid()]
		if space.intersect_ray(query).is_empty() and not _crowds_shot(eye, eye + direction * 5.4, actor):
			chosen = direction
			break
	# The employee turns to the camera as the ticket lands; the monster keeps that facing.
	if actor.disguised():
		actor.host.rotation.y = atan2(chosen.x, chosen.z)
		actor.visual.rotation.y = actor.host.rotation.y + PI
	# A wide, slightly high frame: the employee, their surroundings, often the engineer.
	var reach: float = 5.4
	var probe: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(eye, eye + chosen * 5.8 + Vector3.UP * 1.1, 1)
	probe.exclude = [actor.get_rid()]
	var blocked: Dictionary = space.intersect_ray(probe)
	if not blocked.is_empty():
		reach = maxf(2.4, eye.distance_to(blocked.position) - .4)
	outbreak_from = eye + chosen * reach + Vector3.UP * (reach * .2)
	outbreak_to = eye + chosen * (reach - 1.0) + Vector3.UP * (reach * .13)
	camera.global_position = outbreak_from
	camera.look_at(eye)
	var who: Dictionary = actor.host.identity if actor.disguised() and "identity" in actor.host else {}
	var minutes: int = maxi(0, int((incident.elapsed - 13.4) / 20.0))
	lower_kicker.text = "%d:%02d PM  ·  %s%s" % [5 + minutes / 60, minutes % 60, area.to_upper() if not area.is_empty() else "THE FLOOR", ("  ·  " + TRIGGERS[reason]) if TRIGGERS.has(reason) else ""]
	lower_kicker.add_theme_color_override("font_color", Color(.6, .85, .9))
	lower_name.text = "%s  ·  %s" % [who.get("name", "OVERTIME"), who.get("team", "Payments Platform")]
	lower_name.add_theme_color_override("font_color", Color(.94, .96, 1))
	lower_note.text = who.get("quip", "Still online.")
	lower_note.add_theme_color_override("font_color", Color(.75, .8, .85))
	sting(preload("res://assets/audio/sfx/chat_ping.ogg"), -6)


## Talking: who the camera is covering and the shot it last used.
var talk_speaker: Node3D
var talk_standing: bool = true


func begin_dialogue(speaker: Node3D, standing: bool) -> void:
	talk_speaker = speaker
	talk_standing = standing
	incident.main.get_node("HUD").visible = false
	dialogue_camera("them", 0.0, 1)


## Shot / reverse shot, always from the same side of the pair: an establishing two-shot
## to open, then over the engineer's shoulder or a close single on whoever is talking,
## and a reverse over the speaker's shoulder when the engineer answers. Each line drifts
## in slowly; walls pull the camera in.
func dialogue_camera(who: String, time: float, line: int) -> void:
	if not is_instance_valid(talk_speaker):
		return
	var from: Vector3 = incident.player.global_position
	var to: Vector3 = talk_speaker.global_position
	var toward: Vector3 = Vector3(to.x - from.x, 0, to.z - from.z)
	toward = toward.normalized() if toward.length() > .1 else Vector3.FORWARD
	var side: Vector3 = toward.cross(Vector3.UP).normalized()
	var mine: Vector3 = from + Vector3.UP * 1.3
	var theirs: Vector3 = to + Vector3.UP * (1.2 if talk_standing else .95)
	var spot: Vector3
	var look: Vector3
	var lens: float = 44.0
	if who == "you":
		spot = to + toward * 2.3 + side * 1.35
		spot.y = to.y + 1.75
		look = mine - Vector3.UP * .4
		lens = 40.0
	elif line == 1 and time < 1.6:
		var middle: Vector3 = (from + to) * .5
		spot = middle + side * 3.0 - toward * .4 + Vector3.UP * 1.55
		look = (mine + theirs) * .5 - Vector3.UP * .45
		lens = 46.0
	elif line % 2 == 1:
		spot = from - toward * 2.1 + side * 1.15 + Vector3.UP * 1.75
		look = theirs.lerp(mine, .3) - Vector3.UP * .55
	else:
		spot = from + toward * .45 + side * .5 + Vector3.UP * 1.3
		look = theirs - Vector3.UP * .3
		lens = 38.0
	spot = look + (spot - look) * (1.0 - .08 * smoothstep(0.0, 5.0, time))
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(look, spot, 1)
	var hit: Dictionary = incident.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		spot = hit.position + (look - hit.position).normalized() * .25
	camera.global_position = spot
	camera.look_at(look)
	camera.fov = lens
	camera.make_current()


## A finisher, in three beats on real time: an instant of near-freeze punched in on the
## kill (tilted, flash, boom); then the hero shot: a low angle in front of the engineer,
## who has turned his back on it with the keyboard on his shoulder while it comes apart
## behind him in slow motion (sound slows too); then a blend back to the gameplay camera.
## `force` ignores the cooldown (last kills, the boss, the ultimate).
func kill_cam(subject: Vector3, from: Vector3, force: bool = false, length: float = KILLCAM_SECONDS) -> bool:
	if DisplayServer.get_name() == "headless" and not killcam_in_headless:
		return false
	if not beat_shot.is_empty() or incident.modal_pending() or incident.terminal() and not force:
		return false
	var now: int = Time.get_ticks_msec()
	if not force and now < killcam_ready:
		return false
	killcam_ready = now + 9000
	killcam_length = length
	var player: CharacterBody3D = incident.player
	var hero: Vector3 = player.global_position
	var axis: Vector3 = Vector3(subject.x - hero.x, 0, subject.z - hero.z)
	if axis.length() < .5:
		# The kill is the engineer himself (the ultimate): face the camera's way.
		axis = -player.camera_rig.global_basis.z
		axis.y = 0
	axis = axis.normalized() if axis.length() > .01 else Vector3.FORWARD
	var head: Vector3 = hero + Vector3.UP * 1.2
	var space: PhysicsDirectSpaceState3D = incident.get_world_3d().direct_space_state
	var sides: Array = [1.0, -1.0] if rng.randf() < .5 else [-1.0, 1.0]
	var side: Vector3 = axis.cross(Vector3.UP).normalized() * sides[0]
	for sign: float in sides:
		var across: Vector3 = axis.cross(Vector3.UP).normalized() * sign
		var spot: Vector3 = head - axis * 3.4 + across * 1.3 - Vector3.UP * .5
		if space.intersect_ray(PhysicsRayQueryParameters3D.create(head, spot, 1)).is_empty():
			side = across
			break
	killcam_victim = subject + Vector3.UP * 1.0
	killcam_punch = killcam_victim - axis * 2.8 + side * 1.7 + Vector3.UP * .45
	killcam_from = head - axis * 3.4 + side * 1.3 - Vector3.UP * .5
	killcam_to = head - axis * 2.7 + side * 1.0 - Vector3.UP * .42
	killcam_look = hero + Vector3.UP * 1.0 + axis * .6
	killcam_roll = deg_to_rad(8.0) * sides[0]
	killcam_turn = atan2(axis.x, axis.z)
	killcam_facing = player.visual.rotation.y
	beat_shot = "killcam"
	killcam_start = now
	killcam_hero = false
	ElementFx.release_freeze()
	sting(preload("res://assets/audio/sfx/low_boom.ogg"), -5)
	return true


func _killcam_shot() -> void:
	var t: float = (Time.get_ticks_msec() - killcam_start) / 1000.0
	var length: float = killcam_length
	var player: CharacterBody3D = incident.player
	var character: Node3D = player.get_node("Visual/Character")
	if t >= length:
		_end_killcam()
		return
	incident.main.get_node("HUD").visible = false
	player.narrative_hold = true
	player.invulnerable_left = maxf(player.invulnerable_left, .3)
	var rig: Camera3D = player.get_node("CameraRig/SpringArm3D/Camera3D")
	var scale: float
	if t < .16:
		# Beat 1: the impact, all but frozen.
		scale = .03
		camera.global_position = killcam_punch
		camera.look_at(killcam_victim)
		camera.rotate_object_local(Vector3.BACK, killcam_roll)
		camera.fov = 40.0
	else:
		if not killcam_hero:
			# Cut to the hero: he has already turned his back on it.
			killcam_hero = true
			player.visual.rotation.y = killcam_turn
			character.story_pose = CHARACTER.Pose.COOL
			sting(preload("res://assets/audio/sfx/whoosh_slice.ogg"), -6)
		var u: float = smoothstep(.16, length - .45, t)
		scale = lerpf(.07, .4, u)
		camera.global_position = killcam_from.lerp(killcam_to, u)
		camera.look_at(killcam_look)
		camera.rotate_object_local(Vector3.BACK, killcam_roll * .5 * (1.0 - u))
		camera.fov = lerpf(50.0, 44.0, u)
		var handover: float = smoothstep(length - .45, length, t)
		if handover > 0:
			camera.global_transform = camera.global_transform.interpolate_with(rig.global_transform, handover)
			camera.fov = lerpf(camera.fov, rig.fov, handover)
			scale = lerpf(scale, 1.0, handover)
			# He turns back and shoulders the blade while the camera comes home.
			character.story_pose = 0
			player.visual.rotation.y = lerp_angle(killcam_turn, killcam_facing, handover)
	ElementFx.slow_motion(&"killcam", scale)
	AudioServer.playback_speed_scale = clampf(scale * 2.2, .5, 1.0)
	camera.make_current()
	killflash.visible = t < .22
	killflash.color.a = maxf(0.0, .3 - t * 1.6)
	var bars: float = 54.0 * smoothstep(0.0, .1, t) * (1.0 - smoothstep(length - .3, length, t))
	for side in [0, 1]:
		letterbox[side].visible = bars > .5
		letterbox[side].offset_top = 0.0 if side == 0 else -bars
		letterbox[side].offset_bottom = bars if side == 0 else 0.0


func _end_killcam() -> void:
	beat_shot = ""
	ElementFx.slow_motion(&"killcam", 1.0)
	AudioServer.playback_speed_scale = 1.0
	killflash.hide()
	for bar in letterbox:
		bar.hide()
	if killcam_hero:
		incident.player.visual.rotation.y = killcam_facing
	killcam_hero = false
	release_camera()


## True when someone (coworker, host or monster; none have camera collision) stands
## between the camera and the action, or the camera would sit inside them.
func _blocks_view(spot: Vector3, focus: Vector3) -> bool:
	var bodies: Array[Node3D] = []
	if incident.coworkers != null:
		for someone: Dictionary in incident.coworkers.people:
			bodies.append(someone.body)
	for host: Node3D in incident.hosts + incident.sync_hosts:
		if is_instance_valid(host):
			bodies.append(host)
	for other: CharacterBody3D in incident.alive + incident.sync_alive + incident.bugs:
		if is_instance_valid(other) and other.health > 0:
			bodies.append(other)
	for body in bodies:
		var at: Vector3 = body.global_position + Vector3.UP * 1.0
		if at.distance_to(focus) < 1.3:
			continue
		var closest: Vector3 = Geometry3D.get_closest_point_to_segment(at, spot, focus)
		if at.distance_to(closest) < .7:
			return true
	return false


## True when a bystander (no collision, so rays miss them) would stand in the shot.
func _crowds_shot(from: Vector3, to: Vector3, actor: Node3D) -> bool:
	var bodies: Array[Node3D] = []
	if incident.coworkers != null:
		for someone: Dictionary in incident.coworkers.people:
			bodies.append(someone.body)
	for other: CharacterBody3D in incident.alive + incident.sync_alive:
		if other != actor and is_instance_valid(other):
			bodies.append(other)
	var a: Vector2 = Vector2(from.x, from.z)
	var b: Vector2 = Vector2(to.x, to.z)
	for body in bodies:
		var at: Vector2 = Vector2(body.global_position.x, body.global_position.z)
		if at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)) < .75 and at.distance_to(a) > .5:
			return true
	return false


## Evidence opens: a short push onto the wall where three systems disagree.
func evidence_shot() -> void:
	if beat_shot.is_empty() and not incident.modal_pending():
		beat_shot = "evidence"
		beat_time = 0.0
		camera.global_transform = incident.player.get_node("CameraRig/SpringArm3D/Camera3D").global_transform


func _beats(delta: float) -> void:
	if beat_shot.is_empty():
		return
	beat_time += delta
	var rig: Camera3D = incident.player.get_node("CameraRig/SpringArm3D/Camera3D")
	match beat_shot:
		"omnislash":
			_omnislash_shot()
		"killcam":
			_killcam_shot()
		"outbreak":
			_outbreak_shot(delta, rig)
		"evidence":
			if incident.modal_pending() or incident.stage != incident.Stage.INVESTIGATION or beat_time > 2.6:
				beat_shot = ""
				release_camera()
				return
			incident.player.narrative_hold = true
			var close: Transform3D = Transform3D(Basis.looking_at(Vector3(0, .1, -1)), Vector3(-1.7, 2.3, -11.6))
			var weight: float = smoothstep(0, .9, beat_time) * (1.0 - smoothstep(2.0, 2.6, beat_time))
			camera.global_transform = rig.global_transform.interpolate_with(close, weight)
			camera.fov = lerpf(rig.fov, 50.0, weight)
			camera.make_current()
		"vault":
			# Arrival without taking control: lights fail in order, a frame, a surge.
			var arrive: float = boss_length
			for index in range(vault_lights.size()):
				var out: bool = beat_time > .3 + index * .35 and beat_time < arrive
				vault_lights[index].light_energy = vault_energy[index] * (.05 if out else (2.2 if beat_time < arrive + .6 else 1.0))
			var bars: float = 44.0 * smoothstep(0, .5, beat_time) * (1.0 - smoothstep(arrive + .8, arrive + 1.4, beat_time))
			for side in [0, 1]:
				letterbox[side].visible = bars > .5
				letterbox[side].offset_top = 0.0 if side == 0 else -bars
				letterbox[side].offset_bottom = bars if side == 0 else 0.0
			var ledger: Array[String] = ["SUCCESS", "FAILED", "NOT FOUND"]
			for index in range(3):
				incident.room.get_node("LedgerText%d" % index).text = ledger[(index + int(beat_time * 6.0)) % 3] if beat_time < arrive else ledger[index]
			if is_instance_valid(incident.boss) and beat_time - delta < arrive + .05 and beat_time >= arrive + .05:
				incident.player.camera_rig.add_impulse(1.0)
			if beat_time > arrive + 1.6:
				beat_shot = ""
				for bar in letterbox:
					bar.hide()


func _outbreak_shot(delta: float, rig: Camera3D) -> void:
	var actor: CharacterBody3D = outbreak_actor
	if not is_instance_valid(actor) or beat_time >= OUTBREAK_LENGTH or incident.modal_pending():
		beat_shot = ""
		outbreak_actor = null
		lower_third.hide()
		for bar in letterbox:
			bar.hide()
		release_camera()
		return
	var burst: float = incident.OUTBREAK_BURST
	incident.player.narrative_hold = true
	incident.player.invulnerable_left = maxf(incident.player.invulnerable_left, .3)
	incident.main.get_node("HUD").visible = false
	feed.visible = false
	hint.visible = true
	lower_third.visible = beat_time > .25 and beat_time < OUTBREAK_LENGTH - .5
	lower_third.modulate.a = smoothstep(.25, .6, beat_time) * (1.0 - smoothstep(OUTBREAK_LENGTH - 1.0, OUTBREAK_LENGTH - .5, beat_time))
	if not outbreak_burst and (beat_time >= burst or not actor.disguised()):
		outbreak_burst = true
		shake = 1.0
		sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -4)
		sting(preload("res://assets/audio/sfx/low_boom.ogg"), -8)
		ElementFx.freeze(self, .1, .05)
		lower_kicker.text = "TICKET REASSIGNED"
		lower_kicker.add_theme_color_override("font_color", Color(1, .5, .35))
		lower_name.text = actor.title
		lower_name.add_theme_color_override("font_color", Color(1, .42, .3))
		lower_note.text = actor.motto
	# Before: a slow push onto the employee. After: back off to fit the monster.
	var height: float = MonsterRig.KINDS[actor.rig_kind].height if actor.rig != null else 2.0
	var eye: Vector3 = actor.global_position + Vector3.UP * (1.1 if not outbreak_burst else lerpf(1.1, height * .6, smoothstep(burst, burst + .5, beat_time)))
	var spot: Vector3
	if beat_time < burst:
		spot = outbreak_from.lerp(outbreak_to, smoothstep(0.0, burst, beat_time))
	else:
		var back: Vector3 = outbreak_from + (outbreak_from - eye).normalized() * maxf(0.0, height - 2.0) + Vector3.UP * .3
		spot = outbreak_to.lerp(back, smoothstep(burst, burst + .7, beat_time))
	camera.global_position = spot
	camera.look_at(eye)
	camera.fov = 50.0
	if beat_time > burst - .9 and beat_time < burst:
		camera.rotation += Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), 0) * .004
	shake = maxf(0, shake - delta * 2.0)
	if shake > 0:
		camera.rotation += Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), 0) * .014 * shake
	# The last half second hands back to the gameplay camera.
	var handover: float = smoothstep(OUTBREAK_LENGTH - .6, OUTBREAK_LENGTH, beat_time)
	if handover > 0:
		camera.global_transform = camera.global_transform.interpolate_with(rig.global_transform, handover)
		camera.fov = lerpf(camera.fov, rig.fov, handover)
	camera.make_current()
	var bars: float = 56.0 * smoothstep(0, .35, beat_time) * (1.0 - smoothstep(OUTBREAK_LENGTH - .6, OUTBREAK_LENGTH, beat_time))
	for side in [0, 1]:
		letterbox[side].visible = bars > .5
		letterbox[side].offset_top = 0.0 if side == 0 else -bars
		letterbox[side].offset_bottom = bars if side == 0 else 0.0


## Terminal: the camera leaves the engineer slowly while the postmortem is read.
func _ending(delta: float) -> void:
	if not incident.terminal() or beat_shot == "killcam":
		return
	if beat_shot != "ending":
		beat_shot = "ending"
		beat_time = 0.0
		ending_from = incident.player.get_node("CameraRig/SpringArm3D/Camera3D").global_transform
		for bar in letterbox:
			bar.hide()
	beat_time += delta
	var won: bool = incident.stage == incident.Stage.RESOLVED
	var at: Vector3 = incident.player.global_position
	var away: Vector3 = ending_from.origin - at
	away.y = 0
	away = away.normalized() if not away.is_zero_approx() else Vector3.BACK
	var orbit: Vector3 = away.rotated(Vector3.UP, beat_time * (.05 if won else -.035))
	var goal: Vector3 = at + orbit * (7.5 if won else 3.4) + Vector3.UP * (4.2 if won else 1.2)
	var weight: float = smoothstep(0, 4.0, beat_time)
	camera.global_position = ending_from.origin.lerp(goal, weight)
	camera.look_at(at + Vector3.UP * (1.0 if won else .6))
	camera.fov = 52.0
	camera.make_current()


func slow_beat() -> void:
	if DisplayServer.get_name() != "headless":
		ElementFx.slow_motion(&"first_sighting", .35)
		slowmo_until = Time.get_ticks_msec() + 350


func _music(delta: float) -> void:
	var desired: String = "tension"
	var level: float = -11.0
	if incident.terminal():
		desired = ""
	elif incident.stage == incident.Stage.ALERT:
		desired = "tension" if short_opening or incident.stage_time > 32.0 else ""
	elif incident.stage == incident.Stage.BOSS and incident.boss_triggered:
		desired = "boss"
		level = -9.0
	elif incident.stage == incident.Stage.INVESTIGATION:
		level = -17.0
	if get_tree().paused and not incident.terminal():
		level -= 8.0
	if DisplayServer.get_name() == "headless":
		music_track = desired
		return
	if desired != music_track:
		music.volume_db = move_toward(music.volume_db, -60.0, delta * 45.0)
		if music.volume_db <= -55.0:
			music_track = desired
			music.stop()
			if not desired.is_empty():
				music.stream = TRACKS[desired]
				music.play()
	else:
		music.volume_db = move_toward(music.volume_db, level, delta * 12.0)


func used(key: String) -> void:
	var streams: Dictionary = {"coffee": preload("res://assets/audio/sfx/ui_confirm.ogg"), "vending": preload("res://assets/audio/sfx/ui_error.ogg"), "microwave": preload("res://assets/audio/sfx/ui_error.ogg"), "poster": preload("res://assets/audio/sfx/chat_ping_soft.ogg")}
	sting(streams[key], -8)


## Environmental storytelling that runs during play: the gate, the corridor, the sparks.
func _environment(delta: float) -> void:
	# The public status page stays green and keeps improving while everything is red.
	var uptime: Label3D = incident.room.get_node("Uptime")
	if incident.alert_played:
		uptime.text = "STATUS PAGE: ALL SYSTEMS OPERATIONAL  ·  UPTIME 99.9%02d%%" % (90 + int(incident.elapsed / 7.0) % 10)
	else:
		uptime.text = "UPTIME 99.999%"
	var gate: Node3D = incident.room.get_node("VaultGate")
	var open: bool = incident.stage == incident.Stage.BOSS
	gate.position.y = move_toward(gate.position.y, 5.9 if open else 2.0, delta * 2.2)
	var z: float = incident.player.global_position.z
	var at: Vector3 = incident.player.global_position
	if at.x > 18.8 and at.z > 3.7 and at.z < 12.8:
		say("pantry_found")
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
	if slowmo_until > 0 and Time.get_ticks_msec() >= slowmo_until:
		slowmo_until = 0
		ElementFx.slow_motion(&"first_sighting", 1.0)
	_music(delta)
	_ending(delta)
	for fragment in fragments:
		fragment.visible = false
	if not sequence.is_empty() and voice.current_line.is_empty() and voice.queue.is_empty() and not voice.suspended:
		say(sequence.pop_front())
	# A finisher plays out even over the end of the incident (the boss's last blow).
	if beat_shot == "killcam" and not get_tree().paused and (incident.terminal() or incident.modal_pending()):
		_killcam_shot()
	var visible_play: bool = not get_tree().paused and not incident.terminal() and not incident.modal_pending()
	panel.visible = visible_play and line_left > 0
	feed.visible = visible_play
	if visible_play:
		feed.tick(delta)
	title.visible = false
	hint.visible = false
	if not visible_play:
		return
	if not ambient.playing and DisplayServer.get_name() != "headless":
		ambient.play()
	_environment(delta)
	_beats(delta)
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
			say("boss", true)
	if incident.stage == incident.Stage.ENCOUNTER_TWO and time > 10: say("contain")
	if incident.stage == incident.Stage.ENCOUNTER_TWO and time > 18: say("visibility")
	if incident.player.dodging and incident.stage in [incident.Stage.ENCOUNTER_ONE, incident.Stage.ENCOUNTER_TWO, incident.Stage.BOSS]:
		say("first_dodge")
	if incident.stage == incident.Stage.BOSS and incident.boss_time > 22: say("rca")
	caption.text = voice.subtitle
	# Film subtitles belong to the cinematic; in play, speech arrives as chat cards.
	panel.visible = not voice.subtitle.is_empty() and in_cinematic()
