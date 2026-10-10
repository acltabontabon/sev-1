extends CanvasLayer
## Authored Incident 001 beats only. Gameplay owns stages, damage and choices.
const DESK_SCREEN: Script = preload("res://game/ui/desk_screen.gd")
const FEED: Script = preload("res://game/ui/notification_feed.gd")
const ALERT_SENDERS: Array[String] = ["MONITORING / SEV-1", "PRODUCTION SYSTEM", "STATUS PAGE", "THE VARIANCE"]
const CHARACTER = preload("res://game/player/rigged_engineer.gd")
const VARIANCE = preload("res://game/incidents/variance.gd")
const ALL_HANDS: Script = preload("res://game/incidents/all_hands.gd")
const DUEL: Script = preload("res://game/incidents/duel.gd")
const RECORD_VISUAL: PackedScene = preload("res://game/enemies/record_visual.tscn")
const SEAT: Vector3 = Vector3(-2.5, .05, 10.27)
const MONITOR: Vector3 = Vector3(-2.5, 1.26, 9.19)
## Where the seated engineer's face is (rigged_engineer.SEATED_OFFSET lifts him onto the cushion).
const FACE: Vector3 = Vector3(-2.5, 1.63, 9.92)
const OPENING_LENGTH: float = 50.5
## Opening shots: start, camera from, camera to, look from, look to, field of view, and
## optionally an end field of view (or "dolly": the lens widens as the camera closes so
## the face holds its size while the room warps), then a dutch roll in degrees.
## Each shot eases from its first pose to its second until the next shot cuts in.
const SHOTS: Array = [
	# Establishing: high over the dark office, 4:59 on a Friday.
	[0.0, Vector3(4.0, 5.2, -12.0), Vector3(2.0, 4.6, -5.0), Vector3(-1.0, .5, 8.0), Vector3(-2.0, .8, 9.0), 64.0, 60.0],
	[4.3, Vector3(-9.5, 3.4, -9.0), Vector3(-9.0, 2.6, -1.5), Vector3(-6.0, .8, 2.0), Vector3(-5.0, .9, 6.0), 56.0, 52.0],
	# (8.6–16.6 s: the night shift, one freeze-frame each; see CREW.)
	# Down to the one desk still lit.
	[16.6, Vector3(1.6, 4.2, 3.0), Vector3(-.7, 2.25, 13.1), Vector3(-2.5, .9, 6.0), Vector3(-2.5, 1.25, 9.6), 58.0, 46.0],
	[22.6, Vector3(-1.62, 1.95, 10.7), Vector3(-1.78, 1.87, 10.38), MONITOR + Vector3(.12, 0, 0), MONITOR + Vector3(.08, 0, 0), 36.0],
	[25.5, Vector3(-1.98, 1.95, 8.25), Vector3(-2.16, 1.9, 8.45), FACE, FACE + Vector3(0, .02, 0), 42.0],
	[28.5, Vector3(-2.26, 1.55, 9.98), Vector3(-2.36, 1.49, 9.74), MONITOR, MONITOR, 33.0],
	# The click. Everything goes red.
	[29.1, Vector3(-2.5, 1.27, 9.95), Vector3(-2.5, 1.27, 9.84), MONITOR, MONITOR, 42.0, 42.0, -6.0],
	[29.8, Vector3(-4.2, 1.15, 12.9), Vector3(-4.6, 1.0, 12.3), Vector3(-7.4, 1.3, -6.0), Vector3(-7.6, 1.2, -6.0), 50.0, 50.0, 12.0],
	# Every ping at once: the lens widens as it closes on him.
	[30.8, Vector3(-1.8743, 1.9429, 7.8342), Vector3(-2.2867, 1.7367, 9.2089), FACE, FACE, 26.0, "dolly"],
	[35.6, Vector3(-1.82, 1.28, 9.5), Vector3(-1.92, 1.32, 9.62), FACE + Vector3(0, .02, 0), FACE, 38.0, 32.0, -7.0],
	# Black. Then the power goes, row by row.
	[37.6, Vector3(-1.1, 1.85, 11.7), Vector3(-1.35, 1.95, 11.0), Vector3(-3.0, 2.0, -14.5), Vector3(-3.2, 2.1, -14.5), 46.0],
	# The night shift, in the dark, all looking at you.
	[39.6, Vector3(-3.2, 1.45, 4.6), Vector3(-3.5, 1.4, 3.0), Vector3(-8.0, 1.0, -2.6), Vector3(-8.0, 1.0, -3.4), 56.0, 50.0, -3.0],
	# From behind his chair, down the aisle: the flicker.
	[41.6, Vector3(-1.75, 1.55, 11.9), Vector3(-1.78, 1.55, 11.75), Vector3(-1.6, 1.3, -6.0), Vector3(-1.6, 1.3, -6.0), 50.0, 46.0],
	# Behind you.
	[43.6, Vector3(-2.32, 1.6, 8.95), Vector3(-2.38, 1.6, 9.12), FACE + Vector3(0, .25, 0), FACE + Vector3(0, .3, 0), 44.0, 38.0, 4.0],
	[44.75, Vector3(-2.32, 1.6, 8.95), Vector3(-2.32, 1.6, 8.95), FACE, FACE, 44.0],
	# The lights slam back on. He stands. Title.
	[45.9, Vector3(-.75, 1.05, 11.35), Vector3(-.95, 1.15, 11.05), Vector3(-2.45, 1.35, 10.2), Vector3(-2.45, 1.5, 10.25), 44.0],
	[47.3, Vector3(-2.25, 1.55, 12.4), Vector3(-2.1, 2.25, 13.5), Vector3(-2.6, 1.5, 6.0), Vector3(-2.6, 1.3, 4.0), 55.0],
]
## Timed beats, fired once each as the opening clock crosses them.
const BEATS: Array = [
	[.5, "say", "doc_office"], [8.8, "say", "doc_shift"], [14.1, "say", "doc_chose"], [17.6, "say", "doc_engineer"],
	[22.5, "post", "friday"], [22.6, "say", "friday"],
	[25.5, "pose", CHARACTER.Pose.RELAX], [25.9, "say", "relief"], [28.5, "pose", CHARACTER.Pose.TYPING],
	[28.9, "click", ""], [29.1, "alarm", ""], [29.8, "red_wave", ""],
	[30.8, "pose", CHARACTER.Pose.ALERT], [30.8, "acknowledged", ""], [31.0, "storm", ""], [31.1, "say", "eta"], [31.2, "say", "leadership"],
	[35.8, "say", "start"], [37.2, "blackout", ""],
	[37.7, "flicker", ""], [38.6, "screens", "WHERE IS IT?"], [39.2, "say", "doc_missing"], [39.6, "heads", ""],
	[41.4, "screens", "IT'S HERE."], [43.6, "behind", ""], [44.3, "scream", ""], [45.0, "say", "doc_fascinating"],
	[45.9, "lights", ""], [45.95, "pose", CHARACTER.Pose.ARMED], [47.6, "title", ""],
]
## The night shift, introduced like a heist crew: the camera whips to each, the world
## freezes and drains of colour, and a card slams in.
## [cast name, who, their misery, colour, framing: distance, height above the head, sideways].
const CREW: Array = [
	["SRE", "NADIA", "SRE  ·  ON CALL SINCE 2019", Color(.45, .9, .85), Vector3(1.8, .35, 1.0)],
	["Manager", "MORGAN", "ON A CALL ABOUT THE CALL", Color(1, .62, .78), Vector3(1.9, .15, .9)],
	["Designer", "JUN", "DESIGN  ·  KERNING A CATASTROPHE", Color(1, .7, .3), Vector3(1.9, .15, .9)],
	["Sleeper", "GARY", "ON CALL. TECHNICALLY.", Color(.7, .6, 1), Vector3(2.0, 1.1, 1.4)],
]
const CREW_START: float = 8.6
## The fly-in: one continuous move from the city at night, down the tower, through the
## lit window and over the desks (Catmull-Rom through these [position, look-at] points).
const FLY: Array = [
	[Vector3(-210, 52, 110), Vector3(-14, 6, 0)],
	[Vector3(-165, 38, 82), Vector3(-14, 5, 0)],
	[Vector3(-118, 25, 54), Vector3(-14, 4, 0)],
	[Vector3(-74, 13, 28), Vector3(-14, 3.4, .5)],
	[Vector3(-40, 5.5, 10), Vector3(-14, 3.2, 1.0)],
	[Vector3(-21, 3.3, 3.0), Vector3(-10, 3.0, 1.5)],
	[Vector3(-15.5, 3.1, 1.8), Vector3(-6, 2.6, 2.0)],
	[Vector3(-11.5, 3.0, 1.2), Vector3(-2, 1.8, 3.0)],
	[Vector3(-7.0, 3.6, 2.0), Vector3(2, 1.2, 4.0)],
]
const CREW_EACH: float = 2.0
## The notification storm: more than anyone could read, and that is the point.
const STORM: Array = [
	["Management", "any update?", Color(1, .62, .78)], ["Leadership", "Is this related to the outage?", Color(1, .75, .4)],
	["VP Engineering", "Let's not panic. ETA?", Color(.6, .8, 1)], ["People Ops", "Reminder: Wellness Week starts Monday!", Color(.78, .62, 1)],
	["Management", "+1 on the ETA", Color(1, .62, .78)], ["Product", "is checkout affected? asking for a friend", Color(.5, 1, .7)],
	["Leadership", "Can we just roll forward?", Color(1, .75, .4)], ["Legal", "Please do not put anything in writing.", Color(.85, .85, .85)],
	["Management", "quick sync?", Color(1, .62, .78)], ["Sales", "customer says it's down. is it down?", Color(1, .5, .45)],
	["Leadership", "Who approved a Friday deploy?", Color(1, .75, .4)], ["Management", "per my last message", Color(1, .62, .78)],
	["VP Engineering", "Board meeting in 10. I need a number.", Color(.6, .8, 1)], ["Management", "ETA??", Color(1, .62, .78)],
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
## Opening state: the red wave down the desks, the strobe, the ping storm.
var wave_start: float = -1.0
var wave_order: Array[MeshInstance3D] = []
var calm_material: StandardMaterial3D
## Whole screen panels for the red wave (the code lines alone barely read at a distance).
var displays: Array[MeshInstance3D] = []
var alarm_display: StandardMaterial3D
var pool_colors: Array[Color] = []
var storm_next: float = -1.0
var storm_index: int = 0
var title_at: float = -1.0
## The crew montage: the card, the drained-colour freeze, and where each shot whips from.
var crew_card: Control
var crew_name: Label
var crew_misery: Label
var crew_bar: ColorRect
var crew_freeze: ColorRect
var crew_from: Transform3D
var crew_shown: int = -1
## Casualty cam: one of the night shift falls; a nearly frozen dramatic cut and their record.
var crew_stamp: Label
var casualty_body: Node3D
## What the casualty cam frames: [focus, camera height from it, distance] (see casualty()).
var casualty_frame: Array = []
var casualty_start: int = 0
var casualty_side: float = 1.0
var casualty_angle: float = 999.0
const CASUALTY_SECONDS: float = 1.45
## The vault, first time: the night shift is already in there, losing, one at a time.
## Each goes down once they have screamed through their beating (or after
## MASSACRE_PATIENCE), then the engineer's entrance, then the fight. Its length is only
## known once the last one falls; until then MASSACRE_LENGTH holds the boss back.
const MASSACRE_LENGTH: float = 60.0
const MASSACRE_FIRST: float = .8
const MASSACRE_GAP: float = .5
const MASSACRE_PATIENCE: float = 5.0
const HERO_WALK: float = 1.9
var massacre_time: float = 0.0
var massacre_last: float = 0.0
## The engineer's entrance, after the last of them: "walk", "grief", "roar", "reply".
var hero_phase: String = ""
var hero_phase_at: float = 0.0
var roar_length: float = 2.2
var roar: AudioStreamPlayer
## The victory ending (see all_hands.gd), while it plays.
var all_hands: Node3D
var all_hands_played: bool = false
## The final blow's cutscene (see duel.gd), while it plays.
var duel_scene: Node3D
## The limbs the duel cut off, lying where they landed until the next run.
var duel_pieces: Array[Node3D] = []
var boss_move_strip: PanelContainer
var boss_move_name: Label
var boss_move_tagline: Label
var casualty_resume: String = ""
var demon_swing: float = 0.0
## The staged monster's leaps between scenes (leap_t -1 when standing).
var leap_t: float = -1.0
var leap_from: Vector3
var leap_to: Vector3
var leap_blown: bool = false
## The wide massacre shot follows the scene in the spotlight.
var massacre_eye: Vector3 = Vector3(14.5, 3.4, -41.0)
var massacre_look: Vector3 = Vector3(9, 1.2, -38)
## The reveal: every screen asks one question, the night shift turns, and the missing
## transaction is seen only in flashes until it is right behind him.
var screen_words: Array[Label3D] = []
var screen_black: StandardMaterial3D
var crew_facing: Dictionary = {}
var demon: MonsterRig
var base_exposure: float = 1.0
const FLASHES: Array = [[41.8, Vector3(-1.2, 0, -12.0)], [42.5, Vector3(-1.5, 0, -3.5)], [43.15, Vector3(-2.0, 0, 4.5)]]
const FLASH_LENGTH: float = .14
const FREEZE_SHADER: String = """shader_type canvas_item;
uniform sampler2D screen: hint_screen_texture, filter_linear;
uniform float amount = 0.0;
uniform vec4 tint: source_color = vec4(1.0);
void fragment() {
	vec3 colour = texture(screen, SCREEN_UV).rgb;
	float grey = dot(colour, vec3(0.299, 0.587, 0.114));
	vec3 drained = mix(colour, vec3(grey) * tint.rgb * 1.15, amount);
	vec2 centre = SCREEN_UV - 0.5;
	float vignette = 1.0 - amount * 0.55 * smoothstep(0.25, 0.75, length(centre));
	COLOR = vec4(drained * vignette, 1.0);
}"""
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
var killcam_style: int = 0
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
	for entry: Array in [["SEV-1", "DisplayTitle", 190], ["Works on My Machine", "Subhead", 30]]:
		var label: Label = Label.new()
		label.text = entry[0]
		label.theme_type_variation = entry[1]
		if entry[2] > 0:
			label.add_theme_font_size_override("font_size", entry[2])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(label)
	card.hide()
	add_child(card)
	crew_freeze = ColorRect.new()
	crew_freeze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crew_freeze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var freeze_shader: Shader = Shader.new()
	freeze_shader.code = FREEZE_SHADER
	crew_freeze.material = ShaderMaterial.new()
	crew_freeze.material.shader = freeze_shader
	crew_freeze.hide()
	add_child(crew_freeze)
	move_child(crew_freeze, 0)
	crew_card = Control.new()
	crew_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	crew_card.offset_left = 90
	crew_card.offset_top = -330
	crew_card.offset_right = 900
	crew_card.offset_bottom = -110
	crew_card.rotation = deg_to_rad(-4.0)
	crew_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crew_bar = ColorRect.new()
	crew_bar.position = Vector2(0, 18)
	crew_bar.size = Vector2(14, 168)
	crew_card.add_child(crew_bar)
	crew_name = Label.new()
	crew_name.position = Vector2(36, 0)
	crew_name.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_bold.ttf"))
	crew_name.add_theme_font_size_override("font_size", 132)
	crew_name.add_theme_constant_override("outline_size", 10)
	crew_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, .7))
	crew_card.add_child(crew_name)
	crew_misery = Label.new()
	crew_misery.position = Vector2(40, 150)
	crew_misery.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_semibold.ttf"))
	crew_misery.add_theme_font_size_override("font_size", 40)
	crew_misery.add_theme_constant_override("outline_size", 6)
	crew_misery.add_theme_color_override("font_outline_color", Color(0, 0, 0, .8))
	crew_misery.add_theme_color_override("font_color", Color(.95, .93, .9))
	crew_card.add_child(crew_misery)
	crew_stamp = Label.new()
	crew_stamp.position = Vector2(420, -40)
	crew_stamp.rotation = deg_to_rad(-14.0)
	crew_stamp.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_bold.ttf"))
	crew_stamp.add_theme_font_size_override("font_size", 84)
	crew_stamp.add_theme_color_override("font_color", Color(1, .16, .1))
	crew_stamp.add_theme_constant_override("outline_size", 8)
	crew_stamp.add_theme_color_override("font_outline_color", Color(.25, 0, 0, .9))
	crew_stamp.hide()
	crew_card.add_child(crew_stamp)
	crew_card.hide()
	add_child(crew_card)
	_build_boss_move()
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
				elif mesh.name == &"Display" and workstation.name != &"YourWorkstation":
					displays.append(mesh)
	for mesh in monitors:
		mesh.material_override = screen_material
	desk = DESK_SCREEN.new()
	desk.name = "DeskScreen"
	desk.position = Vector3(0, 1.26, -.192)
	incident.room.get_node("YourWorkstation").add_child(desk)
	for index in range(6):
		pools.append(incident.room.get_node("CeilingPool%d" % index))
		pool_energy.append(pools[index].light_energy)
		pool_colors.append(pools[index].light_color)
	calm_material = StandardMaterial3D.new()
	calm_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	calm_material.albedo_color = Color(.12, .42, .38)
	alarm_display = StandardMaterial3D.new()
	alarm_display.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	alarm_display.albedo_color = Color(.85, .06, .03)
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
	base_exposure = incident.main.get_node("WorldEnvironment").environment.tonemap_exposure
	demon = MonsterRig.create("variance", null)
	demon.name = "OpeningVariance"
	var glow_light: OmniLight3D = OmniLight3D.new()
	glow_light.position = Vector3(0, 2.4, -1.0)
	glow_light.light_color = Color(1, .12, .06)
	glow_light.light_energy = 3.5
	glow_light.omni_range = 5.0
	demon.add_child(glow_light)
	incident.add_child(demon)
	demon.hide()
	screen_black = StandardMaterial3D.new()
	screen_black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_black.albedo_color = Color(.01, .005, .005)
	_build_screen_words()
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
	if is_instance_valid(all_hands):
		all_hands.finish(false)
	all_hands = null
	if is_instance_valid(duel_scene):
		duel_scene.queue_free()
	duel_scene = null
	for piece in duel_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	duel_pieces.clear()
	if demon != null:
		DUEL.restore(demon)
	all_hands_played = false
	if incident != null and is_instance_valid(incident.player):
		incident.player.get_node("Visual/Character").overtime(false)
	if boss_move_strip != null:
		boss_move_strip.hide()
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
		pools[index].light_color = pool_colors[index]
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
	# Cutscenes in the vault stay on the people in them: no chat cards over the shot.
	if in_cinematic() or entry.character == "NARRATOR" or beat_shot in ["massacre", "casualty"]:
		return
	var minutes: int = maxi(0, int((incident.elapsed - 29.1) / 20.0))
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
	if beat_shot == "all_hands" and is_instance_valid(all_hands):
		all_hands.finish()
		return
	if beat_shot == "duel" and is_instance_valid(duel_scene):
		duel_scene.land()
		return
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
		incident.coworkers.fall_all_now()
		if beat_shot in ["massacre", "casualty"]:
			# Skipped, it still happened: he fights in Unpaid Overtime.
			incident.player.get_node("Visual/Character").overtime(true)
			beat_shot = ""
			ElementFx.slow_motion(&"casualty", 1.0)
			crew_freeze.hide()
			crew_card.hide()
			crew_stamp.hide()
			for bar in letterbox:
				bar.hide()
			release_camera()
			boss_move_strip.hide()
			roar.stop()
			incident.player.get_node("Visual/Character").story_pose = CHARACTER.Pose.NONE
			incident.player.global_position = Vector3(9, .05, -31.0)
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
			_stage_vault_fight()
			incident.light_target = 3.7
			set_screens(Color(.45, .12, .3))
			sting(preload("res://assets/audio/sfx/door_open.ogg"), -4)
		incident.Stage.RESOLVED, incident.Stage.FAILED:
			if incident.stage == incident.Stage.RESOLVED:
				# With the finale they wait for its end (leadership is asleep until Monday).
				if DisplayServer.get_name() == "headless" and not killcam_in_headless:
					say_sequence(ALL_HANDS.VICTORY_LINES)
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
## The gate opens: The Variance is already in the vault, and the night shift sprints
## past the engineer to take it on themselves.
func _stage_vault_fight() -> void:
	if DisplayServer.get_name() == "headless" and not killcam_in_headless:
		return
	demon.global_position = incident.arrival_site()
	demon.rotation.y = PI
	DUEL.restore(demon)
	leap_t = -1.0
	demon.show()
	demon.animator.play(demon.clips.idle, 0.0)
	incident.coworkers.charge(demon)


func vault_entered() -> void:
	voice.clear()
	sound("res://assets/audio/boss_arrival.wav")
	beat_time = 0.0
	if demon.visible and incident.coworkers.cavalry_standing() > 0 and not boss_seen:
		# They are still fighting it when he walks in. Not for long.
		beat_shot = "massacre"
		boss_length = MASSACRE_LENGTH
		massacre_time = 0.0
		massacre_last = 0.0
		massacre_eye = incident.coworkers.stage_camera()
		massacre_look = incident.coworkers.stage_focus()
		hero_phase = ""
		# Whatever they were shouting in the corridor stops: the vault has the floor.
		incident.coworkers.hush()
		incident.player.global_position = Vector3(9, .05, -26.8)
		incident.player.velocity = Vector3.ZERO
		return
	incident.coworkers.fall_all_now()
	say("variance_intro")
	beat_shot = "vault"


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
	var minutes: int = maxi(0, int((incident.elapsed - 29.1) / 20.0))
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
## kill (tilted, flash, boom); then the hero shot: low and from the side while the
## engineer swings the Monolith through it in slow motion (a cleave or a spinning
## backhand; the leaping slam for the boss), sound slowed too; then a blend back to the
## gameplay camera as he turns back and shoulders the blade.
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
		var spot: Vector3 = head + across * 4.3 - axis * 1.0 - Vector3.UP * .3
		if space.intersect_ray(PhysicsRayQueryParameters3D.create(head, spot, 1)).is_empty():
			side = across
			break
	killcam_victim = subject + Vector3.UP * 1.0
	killcam_punch = killcam_victim - axis * 2.8 + side * 1.7 + Vector3.UP * .45
	# Low, from the side: the blade goes through the victim across the frame.
	killcam_from = head + side * 4.3 - axis * 1.0 - Vector3.UP * .3
	killcam_to = head + side * 3.7 - axis * .7 - Vector3.UP * .25
	killcam_look = hero + Vector3.UP * .75 + axis * 1.1
	killcam_roll = deg_to_rad(8.0) * sides[0]
	killcam_turn = atan2(-axis.x, -axis.z)
	# Big kills (the boss, the ultimate) get the leaping slam; the rest a cleave or a spin.
	killcam_style = 2 if length > KILLCAM_SECONDS else rng.randi_range(0, 1)
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
			# Cut to the hero squared up to it, the Monolith already moving.
			killcam_hero = true
			player.visual.rotation.y = killcam_turn
			character.story_pose = CHARACTER.Pose.FINISH
			character.finish_style = killcam_style
			sting(preload("res://assets/audio/sfx/whoosh_slice.ogg"), -6)
		# The swing plays out over the shot, finishing as the camera starts home.
		character.finish_progress = clampf((t - .16) / maxf(length - .61, .1), 0.0, 1.0)
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
		"duel":
			if not is_instance_valid(duel_scene) or not duel_scene.tick(get_process_delta_time()):
				if beat_shot == "duel":
					beat_shot = ""
		"casualty":
			_casualty_shot()
		"massacre":
			_massacre_shot(get_process_delta_time())
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
	# Won: the all-hands first (once; headless only when a suite asks).
	if incident.stage == incident.Stage.RESOLVED and not all_hands_played and beat_shot.is_empty() \
			and (DisplayServer.get_name() != "headless" or killcam_in_headless):
		all_hands_played = true
		all_hands = ALL_HANDS.new(self)
		add_child(all_hands)
		all_hands.start()
		beat_shot = "all_hands"
	if beat_shot == "all_hands":
		if is_instance_valid(all_hands) and all_hands.tick(delta):
			return
		beat_shot = ""
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
		desired = "tension" if short_opening or incident.stage_time > 37.6 else ""
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
	for mesh in monitors:
		mesh.material_override = screen_material
	for mesh in displays:
		mesh.material_override = null
	wave_start = -1.0
	storm_next = -1.0
	title_at = -1.0
	crew_shown = -1
	crew_card.hide()
	crew_freeze.hide()
	crew_stamp.hide()
	for word in screen_words:
		word.hide()
	for body: Node3D in crew_facing:
		if is_instance_valid(body):
			body.rotation.y = crew_facing[body]
	crew_facing.clear()
	demon.hide()
	incident.main.get_node("WorldEnvironment").environment.tonemap_exposure = base_exposure
	if incident.coworkers != null:
		incident.coworkers.process_mode = Node.PROCESS_MODE_PAUSABLE
	card.scale = Vector2.ONE
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
		"red_wave":
			# Every other screen was calm a moment ago; now they turn, nearest first.
			wave_start = incident.stage_time
			wave_order = monitors.duplicate()
			wave_order.append_array(displays)
			wave_order.sort_custom(func(a: MeshInstance3D, b: MeshInstance3D) -> bool: return a.global_position.distance_to(SEAT) < b.global_position.distance_to(SEAT))
			for mesh in wave_order:
				mesh.material_override = calm_material if mesh in monitors else null
		"storm":
			storm_next = incident.stage_time
			storm_index = 0
		"blackout":
			storm_next = -1.0
			incident.get_node("AlertSound").stop()
		"title":
			title_at = incident.stage_time
			shake = 1.0
			sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -3)
			sting(preload("res://assets/audio/sfx/low_boom.ogg"), -5)
		"typing":
			desk.set_typing("Leadership is typing…")
		"flicker":
			sting(preload("res://assets/audio/sfx/light_relay.ogg"), -8)
		"screens":
			_screens(entry[2])
		"heads":
			# Every one of them, at once, looking straight at you. Then nobody moves.
			for someone: Dictionary in incident.coworkers.people:
				var body: Node3D = someone.body
				crew_facing[body] = body.rotation.y
				var toward: Vector3 = SEAT - body.global_position
				body.rotation.y = atan2(toward.x, toward.z)
			incident.coworkers.process_mode = Node.PROCESS_MODE_DISABLED
			sting(preload("res://assets/audio/sfx/glitch_a.ogg"), -6)
			sting(preload("res://assets/audio/sfx/low_boom.ogg"), -8)
		"behind":
			demon.show()
			demon.rotation.y = 0.0
			demon.animator.play(demon.clips.idle, 0.0)
		"scream":
			demon.animator.play(demon.clips.attack, .05)
			var scream: AudioStreamPlayer = stings[0]
			scream.stream = preload("res://assets/audio/voices/talk/bark_record_spot_0.ogg")
			scream.volume_db = 2.0
			scream.pitch_scale = .82
			if DisplayServer.get_name() != "headless":
				scream.play()
			sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -2)
			shake = 1.4
		"lights":
			demon.hide()
			sting(preload("res://assets/audio/sfx/light_relay.ogg"), -4)
			sting(preload("res://assets/audio/sfx/low_boom.ogg"), -6)
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
	camera.position = shot[1].lerp(shot[2], weight)
	camera.look_at(shot[3].lerp(shot[4], weight))
	camera.fov = shot[5]
	if shot.size() > 6 and shot[6] is String:
		# Dolly zoom: hold the subject's size while the distance shrinks.
		var held: float = shot[1].distance_to(shot[3]) * tan(deg_to_rad(shot[5]) * .5)
		camera.fov = rad_to_deg(2.0 * atan(held / maxf(camera.position.distance_to(shot[3].lerp(shot[4], weight)), .05)))
	elif shot.size() > 6:
		camera.fov = lerpf(shot[5], shot[6], weight)
	if shot.size() > 7:
		camera.rotate_object_local(Vector3.BACK, deg_to_rad(shot[7]))
	if time < CREW_START:
		_fly_in(time)
	_crew_montage(time)
	shake = maxf(0, shake - delta * 1.6)
	if shake > 0:
		camera.rotation += Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), 0) * .012 * shake
	if time > OPENING_LENGTH - 1.0:
		var target: Camera3D = incident.player.get_node("CameraRig/SpringArm3D/Camera3D")
		var handover: float = smoothstep(OPENING_LENGTH - 1.0, OPENING_LENGTH, time)
		camera.global_transform = camera.global_transform.interpolate_with(target.global_transform, handover)
		camera.fov = lerpf(camera.fov, target.fov, handover)
	camera.make_current()
	# The montage's freeze shader compiles under the fade-in, not on the first freeze.
	if time < 1.0:
		crew_freeze.visible = true
		(crew_freeze.material as ShaderMaterial).set_shader_parameter("amount", 0.0)
	# Frame: fade from black, a hard beat of black after "Tangina naman.", letterbox.
	fade.visible = time < 1.4 or (time >= 37.2 and time < 37.75) or (time >= 41.6 and time < 43.6) or (time >= 44.75 and time < 45.9)
	if time < 1.4:
		fade.color.a = 1.0 - smoothstep(.2, 1.4, time)
	elif time < 37.75:
		fade.color.a = 1.0 - smoothstep(37.6, 37.75, time)
	elif time < 43.6:
		# Near-total dark between flashes; the flashes are all you get.
		fade.color.a = 0.0 if _flashing(time) else .9
	else:
		fade.color.a = 1.0
	var bars: float = 66.0 * smoothstep(0, 1.0, time) * (1.0 - smoothstep(OPENING_LENGTH - 1.2, OPENING_LENGTH - .2, time))
	for side in [0, 1]:
		letterbox[side].show()
		letterbox[side].offset_top = 0.0 if side == 0 else -bars
		letterbox[side].offset_bottom = bars if side == 0 else 0.0
	# Diegetic clock: 4:59 PM runs out exactly when the pager fires.
	var seconds: int = 41 + int(minf(time, 29.09) * 18.0 / 29.1)
	var clock: String = "16:59:%02d" % seconds if time < 29.1 else "17:00:%02d" % int(time - 29.1)
	timecode.visible = false
	desk.set_clock("FRI " + clock.left(5))
	desk.show_logoff(time >= 24.0 and time < 29.1, smoothstep(24.2, 28.2, time), time >= 28.9)
	# The alarm strobes the floor red until the storm takes over.
	for pool in range(pools.size()):
		if time >= 29.1 and time < 30.75:
			pools[pool].light_color = Color(1, .12, .08)
			pools[pool].light_energy = pool_energy[pool] * (1.6 if fmod(time * 6.0 + pool * .3, 1.0) < .5 else .15)
		elif time >= 30.75 and time < 30.9:
			pools[pool].light_color = pool_colors[pool]
			pools[pool].light_energy = pool_energy[pool]
	if wave_start >= 0.0:
		for rank in range(wave_order.size()):
			if time >= wave_start + rank * .012:
				wave_order[rank].material_override = alarm_display if wave_order[rank] in displays else screen_material
	if storm_next >= 0.0 and time >= storm_next and time < 35.4:
		var spam: Array = STORM[storm_index % STORM.size()]
		desk.post(spam[0], spam[1], spam[2], "17:00")
		pinger.stream = preload("res://assets/audio/sfx/chat_ping.ogg")
		pinger.pitch_scale = rng.randf_range(.85, 1.35)
		if DisplayServer.get_name() != "headless":
			pinger.play()
		storm_index += 1
		# Faster and faster: the pings start polite and end as one sound.
		storm_next = time + lerpf(.32, .08, smoothstep(31.0, 34.6, time))
	# Lights die from the desk toward Operations: a bounded flicker, then dim pools.
	for order in range(6):
		var light: int = [1, 0, 3, 2, 4, 5][order]
		var start: float = 37.7 + order * .3
		if time >= start and time < 45.9:
			var lit: bool = time < start + .5 and fmod(time - start, .14) < .06
			var flash: bool = _flashing(time)
			pools[light].light_energy = pool_energy[light] * (1.4 if flash else (1.0 if lit else (.12 if time < 41.6 else 0.0)))
			incident.room.get_node("Diffuser%d" % light).material_override = null if lit or flash else dark
		elif time >= 45.9 and time < OPENING_LENGTH - 1.0:
			# Emergency power: red, and on all at once.
			pools[light].light_color = Color(1, .22, .16)
			pools[light].light_energy = pool_energy[light]
			incident.room.get_node("Diffuser%d" % light).material_override = null
	if time >= OPENING_LENGTH - 1.0:
		_restore_lights()
	_reveal(time, delta)
	if time >= 38.2 and time < 40.2:
		var states: Array[String] = ["SUCCESS", "FAILED", "NOT FOUND"]
		var flip: int = int(time * 9.0) % 3
		incident.room.get_node("Critical").text = states[flip]
		incident.room.get_node("Critical").modulate = [Color(.3, .95, .7), Color(1, .3, .12), Color(1, .8, .3)][flip]
		incident.room.get_node("Impossible").text = "LEDGER: %s" % states[(flip + 1) % 3]
		incident.room.get_node("ETA").text = "PAYMENTS: %s" % states[(flip + 2) % 3]
		if fmod(time, .25) < delta:
			sting(preload("res://assets/audio/sfx/glitch_b.ogg"), -14)
	elif time >= 40.2 and incident.room.get_node("Critical").text != "THREE SYSTEMS\nDISAGREE":
		incident._dashboard("THREE SYSTEMS\nDISAGREE", "CRITICAL INCIDENT / SEV-1")
	# Something steps out of the production dashboard: visual only, never an actor.
	if emerging.visible:
		var rise: float = smoothstep(40.0, 42.2, time)
		emerging.position = Vector3(-4.1 + rng.randf_range(-.06, .06) * (1.0 - rise), lerpf(.6, .05, rise), lerpf(-15.9, -13.5, rise))
		emerging.rotation.y = PI
		emerging.scale = Vector3.ONE * lerpf(.75, 1.3, rise)
		for part in range(fragments.size()):
			var angle: float = part * TAU / 8 + time * 2.0
			var radius: float = lerpf(.2, 2.6, smoothstep(40.0, 41.6, time))
			fragments[part].position = Vector3(-4.1, 2.6, -15.2) + Vector3(cos(angle) * radius, sin(angle * 1.5) * radius * .5, absf(sin(angle)) * radius * .6)
			fragments[part].rotation = Vector3(time * 3.0, angle, 0)
			fragments[part].visible = time < 42.4
		if time >= 43.6:
			emerging.hide()
	# Title slams in over the rising shot: oversized, then settles.
	card.visible = title_at >= 0.0 and time < OPENING_LENGTH - .4
	if card.visible:
		var since: float = time - title_at
		card.pivot_offset = card.size * .5
		card.scale = Vector2.ONE * lerpf(1.6, 1.0, ease(minf(1.0, since / .18), .4))
		card.modulate.a = minf(1.0, since / .08) * (1.0 - smoothstep(OPENING_LENGTH - 1.2, OPENING_LENGTH - .4, time))


## One of the night shift falls in the boss fight: cut to them, nearly frozen, and file
## their record. Skipped (card only) while another beat owns the camera.
func casualty(body: Node3D, who: String, epitaph: String, stamp: String, frame: Array = []) -> void:
	if DisplayServer.get_name() == "headless" and not killcam_in_headless:
		return
	crew_name.text = who
	crew_misery.text = epitaph
	crew_stamp.text = stamp
	crew_stamp.reset_size()
	crew_stamp.pivot_offset = crew_stamp.size / 2.0
	# Tilted about its centre, a long stamp's left end dips: lift it clear of the epitaph.
	crew_stamp.position = Vector2(crew_name.position.x + crew_name.get_minimum_size().x + 24.0, 40.0 - crew_stamp.size.x * .14)
	crew_bar.color = Color(1, .2, .15)
	crew_name.add_theme_color_override("font_color", Color(1, .9, .85))
	sting(preload("res://assets/audio/sfx/low_boom.ogg"), -4)
	sting(preload("res://assets/audio/sfx/whoosh_slice.ogg"), -6)
	casualty_start = Time.get_ticks_msec()
	casualty_side = -casualty_side
	casualty_angle = 999.0
	if beat_shot.is_empty() or beat_shot == "massacre":
		casualty_resume = beat_shot
		beat_shot = "casualty"
		casualty_body = body
		casualty_frame = frame


## The real Variance waits for the massacre (casualty cams pause this clock, not the
## boss's): its countdown is held and its timer follows the cutscene.
func _hold_boss() -> void:
	incident.spawn_delay = maxf(incident.spawn_delay, 1.0)
	incident.boss_time = minf(incident.boss_time, massacre_time)


func _massacre_shot(delta: float) -> void:
	massacre_time += delta
	_hold_boss()
	var player: CharacterBody3D = incident.player
	player.narrative_hold = true
	player.invulnerable_left = maxf(player.invulnerable_left, .3)
	incident.main.get_node("HUD").visible = false
	var crew: Node = incident.coworkers
	if hero_phase.is_empty():
		# The next one gets their move once the last one has finished talking.
		var waited: float = massacre_time - massacre_last
		var first: bool = crew.cavalry_fallen() == 0 and not crew.executing()
		if crew.cavalry_standing() > 0 and not crew.executing() and waited >= (MASSACRE_FIRST if first else MASSACRE_GAP) \
				and (crew.victim_ready() and voices_idle() or waited >= MASSACRE_PATIENCE):
			massacre_last = massacre_time
			crew.execute_next()
		if crew.cavalry_standing() == 0 and (voices_idle() or massacre_time - massacre_last > MASSACRE_PATIENCE):
			_hero_phase("walk")
		if beat_shot != "massacre":
			return
	var hero_time: float = massacre_time - hero_phase_at
	match hero_phase:
		"walk":
			if hero_time >= HERO_WALK:
				_hero_phase("grief")
		"grief":
			if hero_time >= .9 and voices_idle():
				_hero_phase("roar")
		"roar":
			if hero_time >= roar_length + .2:
				_hero_phase("reply")
	var bars: float = 54.0 * smoothstep(0.0, .4, massacre_time) * (1.0 - smoothstep(boss_length - .5, boss_length, massacre_time))
	for side in [0, 1]:
		letterbox[side].visible = bars > .5
		letterbox[side].offset_top = 0.0 if side == 0 else -bars
		letterbox[side].offset_bottom = bars if side == 0 else 0.0
	var boss_at: Vector3 = demon.global_position
	hero_time = massacre_time - hero_phase_at
	var face: Vector3 = player.global_position + Vector3.UP * 1.45
	match hero_phase:
		"":
			# Wide on whichever scene it is on, drifting over as it leaps to the next one.
			massacre_eye = massacre_eye.lerp(crew.stage_camera(), 1.0 - exp(-1.8 * delta))
			massacre_look = massacre_look.lerp(crew.stage_focus(), 1.0 - exp(-3.0 * delta))
			camera.global_position = massacre_eye
			camera.look_at(massacre_look)
			camera.fov = 52.0
		"walk":
			# Over the monster's shoulder: he walks in over his colleagues.
			var walk: float = smoothstep(0.0, HERO_WALK, hero_time)
			player.global_position = Vector3(9, .05, -26.8).lerp(Vector3(9, .05, -30.4), walk)
			player.visual.rotation.y = 0.0
			camera.global_position = boss_at + Vector3(1.5, 2.9, -1.7) + Vector3(0, -.3, .5) * walk
			camera.look_at(player.global_position + Vector3.UP * 1.25)
			camera.fov = lerpf(40.0, 36.0, walk)
			camera.rotate_object_local(Vector3.BACK, deg_to_rad(-6.0 * (1.0 - walk)))
		"grief":
			# Close, low, in front of him: he looks down at them.
			var push: float = smoothstep(0.0, 2.0, hero_time)
			camera.global_position = player.global_position + Vector3(.5, 1.05, -1.6).lerp(Vector3(.4, 1.15, -1.25), push)
			camera.look_at(face)
			camera.fov = 38.0
		"roar":
			# He snaps: the camera is thrown back, shaking, as the floor catches fire.
			var back: float = ease(minf(1.0, hero_time / .35), .3)
			var shake: float = .12 * maxf(0.0, 1.0 - hero_time / 1.6)
			camera.global_position = player.global_position + Vector3(.4, 1.15, -1.25).lerp(Vector3(2.0, .45, -4.0), back) \
				+ Vector3(randf_range(-shake, shake), randf_range(-shake, shake), 0.0)
			camera.look_at(player.global_position + Vector3.UP * 1.3)
			camera.fov = lerpf(38.0, 54.0, back)
			camera.rotate_object_local(Vector3.BACK, deg_to_rad(8.0 * back))
		"reply":
			# Over his shoulder, up at it. It is not impressed.
			var push: float = smoothstep(0.0, boss_length - hero_phase_at, hero_time)
			camera.global_position = player.global_position + Vector3(1.6, 2.3, 2.6).lerp(Vector3(1.3, 2.1, 1.9), push)
			camera.look_at(boss_at + Vector3.UP * 2.2)
			camera.fov = 46.0
	# Its length is only real once its answer starts (until then it is a placeholder).
	if hero_phase == "reply" and massacre_time >= boss_length:
		beat_shot = ""
		incident.boss_time = boss_length
		incident.spawn_delay = 0.0
		player.get_node("Visual/Character").story_pose = CHARACTER.Pose.NONE
		for bar in letterbox:
			bar.hide()
		release_camera()
		return
	camera.make_current()


## The engineer arrives: walk in, grief, the roar, its answer, then the fight.
func _hero_phase(phase: String) -> void:
	hero_phase = phase
	hero_phase_at = massacre_time
	var player: CharacterBody3D = incident.player
	var character: Node = player.get_node("Visual/Character")
	match phase:
		"walk":
			sting(preload("res://assets/audio/sfx/low_boom.ogg"), -3)
		"grief":
			# Their blood runs to his shoes.
			character.story_pose = CHARACTER.Pose.LOOK_DOWN
			say("rage_quiet")
			var ahead: Vector3 = Vector3(player.global_position.x, .02, player.global_position.z - .7)
			Blood.splat(incident, ahead, Vector3.UP, 1.6)
			Blood.splat(incident, ahead + Vector3(.35, 0, -.5), Vector3.UP, 1.1)
			Blood.burst(incident, ahead + Vector3.UP * .3, Vector3(0, .4, 1), 18)
		"roar":
			# He snaps, and goes gold: Unpaid Overtime. The blast throws it back across the vault.
			character.story_pose = CHARACTER.Pose.ARMED
			character.overtime(true)
			incident.coworkers.blown_home = true
			var stream: AudioStream = load("res://assets/audio/voices/talk/call_rage.ogg") if ResourceLoader.exists("res://assets/audio/voices/talk/call_rage.ogg") else null
			roar_length = stream.get_length() if stream != null else 2.2
			if DisplayServer.get_name() != "headless" and stream != null:
				roar.stream = stream
				roar.play()
			var feet: Vector3 = player.global_position
			ElementFx.pillar(incident, feet, Color(1, .8, .3), 1.3, 0.0)
			ElementFx.flame_ring(incident, feet, 3.4, 1.6)
			ElementFx.motes(incident, feet + Vector3.UP * .4, Color(1, .8, .3), 70, 3.5, 2.0, -3.0, .16)
			# The floor gives way under it: debris floats up around him.
			ElementFx.debris(incident, feet + Vector3.UP * .1, 26, 2.5, 2.2)
			ElementFx.cracks(incident, feet, Color(1, .7, .2), 3.0, 9, 2.2)
			ElementFx.shockwave(incident, feet + Vector3.UP * .05, Color(1, .75, .25), 5.0, .5)
			ElementFx.flash(incident, feet + Vector3.UP * 1.4, Color(1, .75, .3), 7.0, 10.0, .5)
			for arc in range(6):
				var angle: float = arc * TAU / 6.0
				ElementFx.bolt(incident, feet + Vector3.UP * 2.6, feet + Vector3(cos(angle), 0, sin(angle)) * 2.2, Color(1, .9, .5), .35, .06)
			ElementFx.tremor(incident, feet, .6, 14.0)
			sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -2)
		"reply":
			say("variance_budget")
			var answer: float = voice.lines.get("variance_budget", {}).get("fallback_duration", 2.6)
			boss_length = massacre_time + maxf(2.2, float(answer)) + .3


## The engineer lands what would kill The Variance: the duel plays it out (duel.gd).
func duel(boss: CharacterBody3D) -> void:
	if beat_shot == "killcam":
		_end_killcam()
	beat_shot = "duel"
	duel_scene = DUEL.new(self, boss)
	add_child(duel_scene)
	duel_scene.start()


## Blinded: the screen goes white and fades back (Paid In Exposure, looked at).
func whiteout(seconds: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	killflash.color = Color(1, 1, 1, .95)
	killflash.show()
	var fade: Tween = killflash.create_tween()
	fade.set_ignore_time_scale(true)
	fade.tween_property(killflash, "color:a", 0.0, seconds).set_delay(.15)
	fade.tween_callback(killflash.hide)


func voices_idle() -> bool:
	return voice.current_line.is_empty() and voice.queue.is_empty() and Time.get_ticks_msec() >= incident.coworkers.voice_until


## The Variance names the move it is about to use, in a red strip from the right; in the
## fight the strip says how to get out of it.
func boss_move(move: String, voiced: bool = true, fight: bool = false) -> void:
	var entry: Dictionary = VARIANCE.MOVES.get(move, {})
	if entry.is_empty():
		return
	if voiced:
		say(entry.line)
	if DisplayServer.get_name() == "headless" and not killcam_in_headless:
		return
	# Real time, so slow motion does not stall it.
	var view: Vector2 = get_viewport().get_visible_rect().size
	boss_move_name.text = entry.name
	boss_move_tagline.text = entry.hint if fight else entry.tagline
	boss_move_strip.reset_size()
	boss_move_strip.size.x = view.x * 1.3
	boss_move_strip.pivot_offset = boss_move_strip.size * .5
	# Below the boss bar in the fight; high in the cutscene (no HUD there).
	boss_move_strip.position = Vector2(view.x * 1.4, view.y * (.3 if fight else .16))
	boss_move_strip.show()
	var slide: Tween = boss_move_strip.create_tween()
	slide.set_ignore_time_scale(true)
	slide.tween_property(boss_move_strip, "position:x", -view.x * .12, .14).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	slide.tween_property(boss_move_strip, "position:x", -view.x * .18, 1.1)
	slide.tween_property(boss_move_strip, "position:x", -view.x * 1.5, .14).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	slide.tween_callback(boss_move_strip.hide)


func _build_boss_move() -> void:
	boss_move_strip = PanelContainer.new()
	boss_move_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_move_strip.rotation = deg_to_rad(5.0)
	var strip: StyleBoxFlat = StyleBoxFlat.new()
	strip.bg_color = Color(.12, 0, .01, .86)
	strip.border_color = Color(1, .18, .12)
	strip.border_width_top = 4
	strip.border_width_bottom = 4
	strip.content_margin_top = 6
	strip.content_margin_bottom = 10
	boss_move_strip.add_theme_stylebox_override("panel", strip)
	var lines: VBoxContainer = VBoxContainer.new()
	lines.add_theme_constant_override("separation", -8)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_move_strip.add_child(lines)
	boss_move_name = Label.new()
	boss_move_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_move_name.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_bold.ttf"))
	boss_move_name.add_theme_font_size_override("font_size", 76)
	boss_move_name.add_theme_color_override("font_color", Color(1, .25, .18))
	boss_move_name.add_theme_constant_override("outline_size", 8)
	boss_move_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, .85))
	lines.add_child(boss_move_name)
	boss_move_tagline = Label.new()
	boss_move_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_move_tagline.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_semibold.ttf"))
	boss_move_tagline.add_theme_font_size_override("font_size", 30)
	boss_move_tagline.add_theme_color_override("font_color", Color(1, .85, .8))
	lines.add_child(boss_move_tagline)
	boss_move_strip.hide()
	add_child(boss_move_strip)
	roar = AudioStreamPlayer.new()
	roar.bus = &"Voice"
	add_child(roar)


## The first angle round them with a clear line: no wall, and not through the boss.
func _clear_angle(at: Vector3, lift: float = -.35, reach: float = 2.4) -> float:
	var space: PhysicsDirectSpaceState3D = incident.get_world_3d().direct_space_state
	# The real boss, or the vault's staged one (bigger, and right next to its victim).
	var monsters: Array[Array] = []
	if is_instance_valid(incident.boss):
		monsters.append([incident.boss.global_position + Vector3.UP * 1.2, 1.1])
	if demon.visible:
		monsters.append([demon.global_position + Vector3.UP * 1.2, 1.8])
	for step in range(12):
		var angle: float = casualty_side * (.9 + step * TAU / 12.0)
		var spot: Vector3 = at + Vector3(sin(angle), 0, cos(angle)) * reach + Vector3.UP * lift
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(at, spot + (spot - at).normalized() * .4, 1)).is_empty():
			continue
		# Clear of it for the whole drift round them, not just where the shot starts.
		var drifted: float = angle + casualty_side * CASUALTY_SECONDS * .35
		var end: Vector3 = at + Vector3(sin(drifted), 0, cos(drifted)) * reach + Vector3.UP * lift
		var blocked: bool = false
		for monster: Array in monsters:
			for camera_at: Vector3 in [spot, end]:
				blocked = blocked or Geometry3D.get_closest_point_to_segment(monster[0], at, camera_at).distance_to(monster[0]) < monster[1]
		if not blocked:
			return angle
	return casualty_side * .9


func _casualty_shot() -> void:
	var t: float = (Time.get_ticks_msec() - casualty_start) / 1000.0
	var player: CharacterBody3D = incident.player
	var rig: Camera3D = player.get_node("CameraRig/SpringArm3D/Camera3D")
	if t >= CASUALTY_SECONDS or not is_instance_valid(casualty_body):
		beat_shot = casualty_resume
		casualty_resume = ""
		ElementFx.slow_motion(&"casualty", 1.0)
		crew_freeze.hide()
		crew_stamp.hide()
		crew_card.hide()
		if beat_shot.is_empty():
			for bar in letterbox:
				bar.hide()
			release_camera()
		return
	player.narrative_hold = true
	player.invulnerable_left = maxf(player.invulnerable_left, .3)
	incident.main.get_node("HUD").visible = false
	if casualty_resume == "massacre":
		_hold_boss()
	# Low, tilted, drifting round them while the world all but stops.
	# Some deaths frame elsewhere: a flattened manager from above, an intern from below.
	var at: Vector3 = casualty_frame[0] if not casualty_frame.is_empty() else casualty_body.global_position + Vector3.UP * .9
	var lift: float = casualty_frame[1] if not casualty_frame.is_empty() else -.35
	var reach: float = casualty_frame[2] if not casualty_frame.is_empty() else 2.4
	if t - get_process_delta_time() <= 0.0 or casualty_angle > 99.0:
		casualty_angle = _clear_angle(at, lift, reach)
	var orbit: float = casualty_angle + casualty_side * t * .35
	camera.global_position = at + Vector3(sin(orbit), 0, cos(orbit)) * reach + Vector3.UP * lift
	camera.look_at(at + Vector3.UP * (.2 if absf(lift) < 1.0 else 0.0))
	camera.rotate_object_local(Vector3.BACK, deg_to_rad(11.0 * casualty_side))
	camera.fov = lerpf(40.0, 34.0, t / CASUALTY_SECONDS)
	var handover: float = smoothstep(CASUALTY_SECONDS - .3, CASUALTY_SECONDS, t) if casualty_resume.is_empty() else 0.0
	if handover > 0:
		camera.global_transform = camera.global_transform.interpolate_with(rig.global_transform, handover)
		camera.fov = lerpf(camera.fov, rig.fov, handover)
	camera.make_current()
	ElementFx.slow_motion(&"casualty", lerpf(.06, 1.0, handover))
	var drain: float = smoothstep(0.0, .12, t) * (1.0 - handover)
	crew_freeze.visible = true
	(crew_freeze.material as ShaderMaterial).set_shader_parameter("amount", drain * .8)
	(crew_freeze.material as ShaderMaterial).set_shader_parameter("tint", Color(1, .45, .4))
	crew_card.visible = true
	crew_card.position.x = lerpf(-700.0, 90.0, ease(minf(1.0, t / .16), .35))
	crew_card.modulate.a = drain
	crew_stamp.visible = t > .35
	crew_stamp.scale = Vector2.ONE * lerpf(2.2, 1.0, ease(minf(1.0, (t - .35) / .12), .4))
	if crew_stamp.visible and t - get_process_delta_time() <= .35:
		sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -5)
	var bars: float = 50.0 * smoothstep(0.0, .1, t) * (1.0 - handover)
	for side in [0, 1]:
		letterbox[side].visible = bars > .5
		letterbox[side].offset_top = 0.0 if side == 0 else -bars
		letterbox[side].offset_bottom = bars if side == 0 else 0.0


func _flashing(time: float) -> bool:
	for flash: Array in FLASHES:
		if time >= flash[0] and time < flash[0] + FLASH_LENGTH:
			return true
	return false


## Every screen in the office goes black and says one thing.
func _screens(text: String) -> void:
	# The red wave is over: these screens belong to the question now.
	wave_start = -1.0
	for display in displays:
		display.material_override = screen_black
	for mesh in monitors:
		mesh.material_override = screen_black
	for word in screen_words:
		word.text = text
		word.show()
	sting(preload("res://assets/audio/sfx/glitch_b.ogg"), -6)


## One hidden word per office screen, made once at load (stable node counts on retry).
func _build_screen_words() -> void:
		for display in displays:
			var word: Label3D = Label3D.new()
			word.font = preload("res://assets/fonts/barlow_condensed_bold.ttf")
			word.font_size = 64
			word.outline_size = 0
			word.modulate = Color(4.0, .35, .22)
			word.shaded = false
			word.double_sided = false
			var facing: Vector3 = display.get_parent().global_basis.z.normalized()
			add_child(word)
			word.global_transform = Transform3D(Basis.looking_at(-facing), display.global_position + facing * .03)
			word.pixel_size = display.mesh.get_aabb().size.x * .75 / (12.0 * 34.0)
			word.hide()
			screen_words.append(word)


func _reveal(time: float, delta: float) -> void:
	if time >= 41.6 and time < 43.6:
		# Weeping angel: seen only in the flashes, closer every time.
		var current: Array = []
		for flash: Array in FLASHES:
			if time >= flash[0]:
				current = flash
		demon.visible = _flashing(time)
		if not current.is_empty():
			demon.global_position = current[1]
			demon.rotation.y = PI
		if demon.visible and time - delta < current[0]:
			sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -7)
			shake = .4
	elif time >= 43.6 and time < 44.75:
		# Behind you: it rises out of the dark over his shoulder.
		demon.visible = true
		var rise: float = smoothstep(43.6, 44.3, time)
		demon.global_position = Vector3(-2.45, lerpf(-1.6, 0.0, rise), 11.15)
		demon.rotation.y = 0.0
	if demon.visible:
		demon.animator.advance(delta)
	# The power goes: the whole floor sinks into the dark (the flashes and the screens
	# are all that cut through), then red emergency light for the hero.
	var dark_level: float = 1.0
	if time >= 38.0 and time < 45.9:
		dark_level = lerpf(1.0, .4, smoothstep(38.0, 39.6, time))
		if _flashing(time):
			dark_level = 1.1
	elif time >= 45.9 and time < OPENING_LENGTH - 1.0:
		dark_level = .85
	incident.main.get_node("WorldEnvironment").environment.tonemap_exposure = base_exposure * dark_level


func _fly_in(time: float) -> void:
	var u: float = smoothstep(0.0, 1.0, time / CREW_START) * (FLY.size() - 1)
	var segment: int = mini(int(u), FLY.size() - 2)
	var t: float = u - segment
	var points: Array[Vector3] = []
	var looks: Array[Vector3] = []
	for offset in [-1, 0, 1, 2]:
		var index: int = clampi(segment + offset, 0, FLY.size() - 1)
		points.append(FLY[index][0])
		looks.append(FLY[index][1])
	var at: Vector3 = _catmull(points, t)
	camera.global_position = at
	camera.look_at(_catmull(looks, t))
	camera.fov = lerpf(32.0, 55.0, smoothstep(.2, 1.0, time / CREW_START))


func _catmull(p: Array[Vector3], t: float) -> Vector3:
	var t2: float = t * t
	return .5 * ((2.0 * p[1]) + (-p[0] + p[2]) * t + (2.0 * p[0] - 5.0 * p[1] + 4.0 * p[2] - p[3]) * t2 + (-p[0] + 3.0 * p[1] - 3.0 * p[2] + p[3]) * t2 * t)


## Meet the night shift: whip to each coworker, freeze the world, slam their card.
func _crew_montage(time: float) -> void:
	var index: int = int(floor((time - CREW_START) / CREW_EACH))
	var active: bool = time >= CREW_START and index < CREW.size() and incident.coworkers != null
	crew_card.visible = false
	crew_freeze.visible = false
	if not active:
		if crew_shown >= 0 and incident.coworkers != null:
			incident.coworkers.process_mode = Node.PROCESS_MODE_PAUSABLE
		crew_shown = -1
		return
	var entry: Array = CREW[index]
	var body: Node3D = null
	for someone: Dictionary in incident.coworkers.people:
		if someone.entry.name == entry[0]:
			body = someone.body
	if body == null:
		return
	var since: float = time - CREW_START - index * CREW_EACH
	if index != crew_shown:
		# Each whip starts from wherever the camera was a moment ago.
		crew_shown = index
		crew_from = camera.global_transform
		incident.coworkers.process_mode = Node.PROCESS_MODE_PAUSABLE
		sting(preload("res://assets/audio/sfx/whoosh_slice.ogg"), -8)
	var routine: String = ""
	for someone: Dictionary in incident.coworkers.people:
		if someone.body == body:
			routine = someone.entry.routine
	var head: Vector3 = body.global_position + Vector3.UP * {"asleep": 1.05, "sit": 1.2}.get(routine, 1.5)
	var front: Vector3 = body.global_basis.z
	front.y = 0
	front = front.normalized() if front.length() > .1 else Vector3.BACK
	var side: Vector3 = front.cross(Vector3.UP).normalized()
	var framing: Vector3 = entry[4]
	var spot: Vector3 = head + front * framing.x + side * framing.z + Vector3.UP * framing.y
	# Never through a wall: pull the lens in front of whatever is between.
	var hit: Dictionary = incident.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(head, spot, 1))
	if not hit.is_empty():
		spot = head + (hit.position - head) * .85
	var hold: Transform3D = Transform3D(Basis.looking_at(head - Vector3.UP * .1 - spot), spot)
	var whip: float = smoothstep(0.0, .3, since)
	camera.global_transform = crew_from.interpolate_with(hold, whip)
	camera.fov = lerpf(46.0, 38.0, smoothstep(.3, CREW_EACH, since))
	if since >= .3:
		# Freeze: the night shift stops; the colour drains; the card slams in.
		if since - get_process_delta_time() < .3:
			incident.coworkers.process_mode = Node.PROCESS_MODE_DISABLED
			shake = .5
			sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -10)
		var drain: float = smoothstep(.3, .45, since) * (1.0 - smoothstep(CREW_EACH - .15, CREW_EACH, since))
		crew_freeze.visible = true
		(crew_freeze.material as ShaderMaterial).set_shader_parameter("amount", drain * .85)
		(crew_freeze.material as ShaderMaterial).set_shader_parameter("tint", entry[3].lerp(Color.WHITE, .55))
		crew_card.visible = true
		crew_name.text = entry[1]
		crew_misery.text = entry[2]
		crew_bar.color = entry[3]
		crew_name.add_theme_color_override("font_color", entry[3].lerp(Color.WHITE, .2))
		var slide: float = ease(minf(1.0, (since - .3) / .16), .35)
		crew_card.position.x = lerpf(-700.0, 90.0, slide)
		crew_card.modulate.a = drain


## The staged Variance in the vault (before the real one takes over): idle, and swinging
## at whoever is in reach.
func _vault_demon(delta: float) -> void:
	# The duel drives it itself.
	if incident.stage != incident.Stage.BOSS or not demon.visible or beat_shot == "duel":
		return
	if is_instance_valid(incident.boss):
		demon.hide()
		return
	var crew: Node = incident.coworkers
	# Across the vault to whoever is next, in one leap; or blown back by the engineer.
	var spot: Vector3 = crew.demon_spot()
	if leap_t < 0.0 and Vector2(spot.x - demon.global_position.x, spot.z - demon.global_position.z).length() > .3:
		leap_t = 0.0
		leap_from = demon.global_position
		leap_to = spot
		leap_blown = crew.blown_home
		demon.animator.play(demon.clips.get("hit", demon.clips.attack) if leap_blown else demon.clips.attack, .05)
		sting(preload("res://assets/audio/sfx/whoosh_dash.ogg"), -6)
	if leap_t >= 0.0:
		leap_t = minf(1.0, leap_t + delta / (.55 if leap_blown else .75))
		var arc: float = sin(leap_t * PI) * (.5 if leap_blown else 2.4)
		var glide: float = ease(leap_t, -2.0) if not leap_blown else 1.0 - pow(1.0 - leap_t, 3.0)
		demon.global_position = leap_from.lerp(leap_to, glide) + Vector3.UP * arc
		if leap_t >= 1.0:
			leap_t = -1.0
			demon.global_position = leap_to
			var floor_at: Vector3 = Vector3(leap_to.x, .05, leap_to.z)
			ElementFx.quake(incident, floor_at, Color(.9, .15, .1), 2.6, .7)
			ElementFx.dust(incident, floor_at, 2.0)
			ElementFx.tremor(incident, floor_at, .3, 14.0)
			sting(preload("res://assets/audio/sfx/heavy_impact.ogg"), -4)
	# It only has eyes for whoever it is taking apart; then for the engineer.
	var prey: Dictionary = crew.spotlight if not crew.spotlight.is_empty() and not crew.spotlight.dead else crew.victim()
	var focus: Vector3 = prey.body.global_position if not prey.is_empty() else incident.player.global_position
	if leap_t >= 0.0 and not leap_blown:
		focus = leap_to
	var toward: Vector3 = focus - demon.global_position
	if Vector2(toward.x, toward.z).length() > .3:
		demon.rotation.y = lerp_angle(demon.rotation.y, atan2(-toward.x, -toward.z), 1.0 - exp(-(9.0 if leap_blown else 5.0) * delta))
	demon_swing -= delta
	if leap_t < 0.0 and demon_swing <= 0.0 and crew.cavalry_standing() > 0 and not crew.executing() and crew.landed():
		demon_swing = randf_range(1.1, 1.8)
		demon.animator.play(demon.clips.attack, .1)
	elif not demon.animator.is_playing():
		demon.animator.play(demon.clips.idle, .2)
	demon.animator.advance(delta)


func _process(delta: float) -> void:
	_vault_demon(delta)
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
	feed.visible = visible_play and not beat_shot in ["massacre", "casualty"]
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
		title.visible = not (beat_shot in ["massacre", "casualty", "duel"]) or beat_shot != "duel" and time >= boss_length - 2
		title.text = "DISCREPANCY CONVERGING" if time < boss_length - 2 else "THE VARIANCE\nDifference detected. Explanation unavailable."
		hint.visible = not is_instance_valid(incident.active_enemy)
		if hint.visible and not demon.visible:
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
	if incident.stage == incident.Stage.ALERT and "\n" in caption.text:
		# Film subtitles: the line only; the shot already shows who is speaking.
		caption.text = caption.text.get_slice("\n", 1)
	# Film subtitles belong to the cinematic; in play, speech arrives as chat cards.
	panel.visible = not voice.subtitle.is_empty() and in_cinematic()
