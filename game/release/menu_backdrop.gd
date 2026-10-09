extends Node3D
## Title backdrop: Friday night at the desk. Pure presentation; no run state, no actors.
## The front end owns its lifetime and frees it before an incident starts.

const DESK_SCREEN: Script = preload("res://game/ui/desk_screen.gd")
const PRESENTATION = preload("res://game/player/character_presentation.gd")
const CAMERA_FROM: Vector3 = Vector3(.15, 1.78, 13.5)
const CAMERA_TO: Vector3 = Vector3(-.15, 1.7, 13.05)
const LOOK: Vector3 = Vector3(-4.1, 1.12, 9.4)
## Speaker, line, avatar color. Some messages arrive as a pair; the second lands late.
const NOTICES: Array = [
	["Monitoring", "All systems operational.", Color(.95, .35, .25), "Except three."],
	["Calendar", "Quick Sync moved to Friday 17:00. Optional (mandatory).", Color(.55, .75, 1)],
	["People Ops", "Reminder: please log exactly 40 hours this week.", Color(.78, .62, 1)],
	["Management", "Hey! Quick question. Is this a quick question?", Color(1, .62, .78)],
	["CI Pipeline", "Build #4,812 failed. Retrying (attempt 37).", Color(.95, .75, .3)],
	["IT Helpdesk", "Your password expires today. Choose one you have never thought of.", Color(.5, .85, .7)],
	["Facilities", "Lights turn off at 17:00. Keep moving to remain visible.", Color(.7, .75, .78)],
	["Leadership", "Great energy this week. Let's carry that into the weekend.", Color(1, .8, .35)],
	["Synergize", "Your status was set to Away. Leadership set it back to Available.", Color(.45, .9, .95)],
]
var screen: Node3D
var character: Node3D
var camera: Camera3D
var room: Node3D
var clock: float = 0.0
var next_notice: float = 2.2
var follow_up: float = -1.0
var follow_text: Array = []
var pose_until: float = 0.0
var next_reaction: float = 9.0
var next_flicker: float = 13.0
var flicker_light: Light3D
var flicker_left: float = 0.0
var bag: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 1659
	room = $OfficeAfterHours
	camera = $Camera3D
	character = $Engineer/Visual/Character
	character.story_pose = PRESENTATION.Pose.TYPING
	screen = DESK_SCREEN.new()
	screen.name = "DeskScreen"
	screen.position = Vector3(0, 1.26, -.192)
	room.get_node("YourWorkstation").add_child(screen)
	screen.banner("INC-001  ·  UNRESOLVED  ·  3 systems disagree")
	screen.set_clock("FRI 16:59")
	# A dark floor: only the desk, the screen and the far incident wall carry light.
	for index in range(6):
		var pool: Light3D = room.get_node("CeilingPool%d" % index)
		pool.light_energy = .55 if index == 1 else 0.0
		if index != 1:
			room.get_node("Diffuser%d" % index).material_override = preload("res://game/rooms/office/black.tres")
	room.get_node("WindowBounce").light_energy = .9
	room.get_node("ConferenceFill").light_energy = .35
	room.get_node("TaskLight").light_energy = 2.2
	room.get_node("Critical").text = "INC-001\nUNRESOLVED"
	room.get_node("Critical").modulate = Color(1, .3, .15)
	room.get_node("RootCause").text = "OWNER: YOU"
	room.get_node("Clock").text = "FRIDAY  /  16:59"
	room.get_node("Impossible").text = "UPTIME 99.999%"
	room.get_node("ETA").text = "ETA: REQUESTED (4)"
	_place_camera(0.0)
	if DisplayServer.get_name() != "headless":
		$Ambience.play()


func _place_camera(time: float) -> void:
	# A slow push with a faint handheld breath; never fast enough to compete with the menu.
	var push: float = smoothstep(0, 1, minf(1, time / 40.0))
	camera.position = CAMERA_FROM.lerp(CAMERA_TO, push) + Vector3(sin(time * .31) * .015, sin(time * .47) * .01, 0)
	camera.look_at(LOOK + Vector3(sin(time * .23) * .02, 0, 0))


func _next_notice() -> Array:
	if bag.is_empty():
		bag = NOTICES.duplicate()
		# Keep the strongest pair first on every launch; shuffle the rest.
		var lead: Array = bag.pop_front()
		bag.shuffle()
		bag.push_front(lead)
	return bag.pop_front()


func _process(delta: float) -> void:
	clock += delta
	_place_camera(clock)
	room.get_node("IncidentSpill").light_energy = 1.0 + .45 * sin(clock * 1.7)
	if clock >= next_notice:
		var notice: Array = _next_notice()
		screen.post(notice[0], notice[1], notice[2])
		_ping()
		character.story_pose = PRESENTATION.Pose.GLANCE
		pose_until = clock + 1.7
		next_notice = clock + rng.randf_range(7.0, 11.0)
		if notice.size() > 3:
			follow_up = clock + 2.1
			follow_text = [notice[0], notice[3], notice[2]]
	if follow_up > 0 and clock >= follow_up:
		follow_up = -1.0
		screen.post(follow_text[0], follow_text[1], follow_text[2])
		_ping()
	if clock >= next_reaction and clock >= pose_until:
		character.story_pose = [PRESENTATION.Pose.SLUMP, PRESENTATION.Pose.SIP, PRESENTATION.Pose.RELAX][rng.randi_range(0, 2)]
		pose_until = clock + 2.6
		next_reaction = clock + rng.randf_range(10.0, 15.0)
	elif clock >= pose_until and character.story_pose != PRESENTATION.Pose.TYPING:
		character.story_pose = PRESENTATION.Pose.TYPING
	_flicker(delta)


func _ping() -> void:
	if DisplayServer.get_name() != "headless":
		$Ping.stream = preload("res://assets/audio/sfx/chat_ping.ogg")
		$Ping.play()


func _flicker(delta: float) -> void:
	if flicker_left > 0:
		flicker_left -= delta
		flicker_light.light_energy = .55 if fmod(flicker_left, .16) > .08 or flicker_left <= 0 else .05
		return
	if clock >= next_flicker:
		flicker_light = room.get_node("CeilingPool1")
		flicker_left = .5
		next_flicker = clock + rng.randf_range(14.0, 22.0)
		if DisplayServer.get_name() != "headless":
			$Ping.stream = preload("res://assets/audio/sfx/glitch_a.ogg")
			$Ping.play()
