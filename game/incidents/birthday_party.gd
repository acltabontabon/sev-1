extends Node3D
## The pantry birthday before the cake ambush: a mandatory celebration, a deadpan song,
## Kevin's wish and trick candles that relight like reopened tickets. Bounded and
## skippable; local prerecorded speech. Nothing outlives the scene or an incident restart.

## [line in talk.json `party.scene`, speaker (0 Kevin, 1 Brenda, 2 Marco, -1 engineer), cue]
const STEPS: Array = [
	["party_surprise", 1, "horn"], ["party_kelvin", 2, ""], ["party_sing", 1, ""],
	["party_song", 2, "song"], ["party_engineer", -1, ""], ["party_wish", 0, "blow"],
	["party_relit", 0, "relit"],
]
## Each line's camera, [position, look-at], authored around the table so nobody's head
## (the engineer's included) fills the lens. The engineer stands at STAND for the scene.
const SHOTS: Array = [
	[Vector3(26.3, 1.95, 11.1), Vector3(25.3, 1.3, 13.4)], [Vector3(29.4, 1.8, 11.95), Vector3(28.2, 1.35, 13.4)],
	[Vector3(25.9, 1.75, 11.5), Vector3(24.55, 1.3, 13.3)], [Vector3(29.15, 1.6, 12.3), Vector3(28.45, 1.35, 13.1)],
	[Vector3(25.2, 1.9, 14.6), Vector3(27.6, 1.3, 11.6)], [Vector3(26.5, 1.55, 12.2), Vector3(26.5, 1.25, 14.5)],
	[Vector3(25.6, 1.7, 12.0), Vector3(26.5, 1.3, 14.4)],
]
const STAND: Vector3 = Vector3(27.6, .05, 11.6)
const DIALOGUES: Script = preload("res://game/incidents/dialogues.gd")
const HAT_COLORS: Array[Color] = [Color(1, .25, .62), Color(.2, .82, 1), Color(1, .72, .2)]
var incident: Node3D
var camera: Camera3D
var speech: AudioStreamPlayer
var horn: AudioStreamPlayer
var captions: CanvasLayer
var caption: Label
var step: int = -1
var left: float = 0.0
var blow_left: float = -1.0
var finished: bool = false


## A paper cone with a pom-pom. On an employee it rides the head bone; anywhere else it
## sits where it is put. The colour is shared by the cone and a brighter pom-pom.
static func party_hat(parent: Node3D, color: Color, size: float = 1.0) -> Node3D:
	var hat: Node3D = Node3D.new()
	hat.name = "PartyHat"
	var paper: StandardMaterial3D = StandardMaterial3D.new()
	paper.albedo_color = color
	paper.roughness = .55
	paper.emission_enabled = true
	paper.emission = color
	paper.emission_energy_multiplier = .25
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = .1 * size
	cone.height = .28 * size
	cone.radial_segments = 12
	cone.material = paper
	var shell: MeshInstance3D = MeshInstance3D.new()
	shell.mesh = cone
	shell.position.y = .14 * size
	hat.add_child(shell)
	var fluff: SphereMesh = SphereMesh.new()
	fluff.radius = .035 * size
	fluff.height = .07 * size
	var white: StandardMaterial3D = StandardMaterial3D.new()
	white.albedo_color = Color(1, .97, .9)
	fluff.material = white
	var pom: MeshInstance3D = MeshInstance3D.new()
	pom.mesh = fluff
	pom.position.y = .29 * size
	hat.add_child(pom)
	var skeleton: Skeleton3D = parent.find_children("*", "Skeleton3D", true, false).front() if not parent.find_children("*", "Skeleton3D", true, false).is_empty() else null
	if skeleton == null or skeleton.find_bone("Head") < 0:
		parent.add_child(hat)
		return hat
	# Head to Head_end is the lower skull; these chibi heads reach about half as far
	# again above it, so the hat sits on the crown there, a little jaunty.
	var mount: BoneAttachment3D = BoneAttachment3D.new()
	mount.bone_name = "Head"
	skeleton.add_child(mount)
	var head: int = skeleton.find_bone("Head")
	var crown: int = skeleton.find_bone("Head_end")
	var length: float = skeleton.get_bone_rest(crown).origin.length() if crown >= 0 else .5
	hat.scale = Vector3.ONE * length * 3.4
	hat.position = Vector3(0, length * 1.45, length * .08)
	hat.rotation.z = .22
	mount.add_child(hat)
	return hat


func _ready() -> void:
	incident.player.narrative_hold = true
	incident.presentation.voice.clear()
	incident.main.get_node("HUD").hide()
	for host: Node3D in incident.party_hosts:
		host.set_process(false)
		host.line.hide()
	# Joining the party: a step up to the table end, facing the cake.
	incident.player.global_position = STAND
	incident.player.velocity = Vector3.ZERO
	incident.player.reset_physics_interpolation()
	var toward: Vector3 = incident.room.get_node("SpawnPoints/BirthdayCake").global_position - STAND
	incident.player.visual.rotation.y = atan2(-toward.x, -toward.z)
	camera = Camera3D.new()
	camera.fov = 56
	add_child(camera)
	speech = AudioStreamPlayer.new()
	speech.bus = &"Voice"
	speech.volume_db = -3
	add_child(speech)
	horn = AudioStreamPlayer.new()
	horn.bus = &"Effects"
	horn.volume_db = -6
	add_child(horn)
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
	style.bg_color = Color(.035, .015, .03, .94)
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
	var entry: Dictionary = line(STEPS[step][0])
	caption.text = "%s: %s\nTAB · skip party" % [entry.who, entry.text]
	captions.visible = incident.presentation.voice.subtitles_enabled
	var speaker: Node3D = incident.player if STEPS[step][1] == -1 else incident.party_hosts[STEPS[step][1]]
	_act(speaker, STEPS[step][2])
	camera.global_position = SHOTS[step][0]
	camera.look_at(SHOTS[step][1])
	camera.current = true
	if speaker != incident.player:
		# Speaking up for the room: they turn to the camera (bodies face +Z).
		var toward: Vector3 = camera.global_position - speaker.global_position
		speaker.rotation.y = atan2(toward.x, toward.z)
	speech.stream = load(DIALOGUES.audio(STEPS[step][0]))
	left = speech.stream.get_length() + .35
	if STEPS[step][2] == "relit":
		# The candles take a beat to come back before the wish goes wrong out loud.
		left += .6
	blow_left = speech.stream.get_length() * .8 if STEPS[step][2] == "blow" else -1.0
	if DisplayServer.get_name() != "headless":
		speech.play()


## The scene's subtitle: who says it, as the name plate reads.
static func line(id: String) -> Dictionary:
	var party: Dictionary = DIALOGUES.data().party
	for entry: Dictionary in party.scene:
		if entry.id == id:
			var who: String = "ENGINEER" if entry.who == "you" else str(party.cast[entry.who].name)
			return {"who": who, "text": entry.text}
	return {"who": "", "text": ""}


## Body language around whoever is talking: the room cheers on cue, Kevin endures it.
func _act(speaker: Node3D, cue: String) -> void:
	for index in range(incident.party_hosts.size()):
		var host: Node3D = incident.party_hosts[index]
		var clip: String = "ual/idle_casual"
		if host == speaker:
			clip = "ual/talking"
		elif index == 0:
			clip = "ual/fold_arms"
		elif cue in ["horn", "song"]:
			clip = "CharacterArmature|Victory"
		host.animator.play(clip, .2)
	match cue:
		"horn":
			_toot(preload("res://assets/audio/sfx/party_horn.wav"))
		"relit":
			incident.set_candles(true)
			_toot(preload("res://assets/audio/sfx/party_horn_sad.wav"))
			var cake: Vector3 = incident.room.get_node("SpawnPoints/BirthdayCake").global_position
			ElementFx.glyphs(self, cake + Vector3.UP * 1.3, Color(1, .5, .35), ["REOPENED"], 1.1, 0.0)
			incident.party_hosts[0].dread = .6


func _toot(stream: AudioStream) -> void:
	horn.stream = stream
	if DisplayServer.get_name() != "headless":
		horn.play()


func _process(delta: float) -> void:
	if finished:
		return
	if blow_left > 0:
		blow_left -= delta
		if blow_left <= 0:
			incident.set_candles(false)
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
	incident.party_scene = null
	incident.actors.erase(self)
	incident._begin_party()
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
	for host: Node3D in incident.party_hosts:
		if is_instance_valid(host):
			host.set_process(true)


func _exit_tree() -> void:
	if not finished and is_instance_valid(incident):
		_restore()
