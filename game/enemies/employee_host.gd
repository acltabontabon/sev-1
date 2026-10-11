extends Node3D
## An overtime employee who has not become an incident yet. Presentation only: no
## collision, no damage, no awareness. Planted on the floor before a wave; the enemy
## that breaks out of it wears it until the reveal (incident.gd `disguise`).
##
## Attentive players can read the tell: every few seconds a planted host twitches and
## flickers red.

const ROOT: String = "res://assets/characters/quaternius/"
const OVERLAY: Shader = preload("res://game/enemies/corruption.gdshader")
## Who each archetype used to be (name, team, cutscene quip, passing line, body) lives in
## assets/audio/voices/talk.json with the rest of the night shift's lines.
const DIALOGUES: Script = preload("res://game/incidents/dialogues.gd")
const PALETTES: Array = [
	[Color(.32, .45, .62), Color(.14, .15, .2), Color(.82, .62, .48), Color(.18, .12, .08)],
	[Color(.62, .55, .4), Color(.2, .2, .22), Color(.5, .34, .24), Color(.06, .05, .05)],
	[Color(.4, .6, .5), Color(.16, .14, .12), Color(.9, .74, .62), Color(.5, .32, .14)],
	[Color(.7, .7, .74), Color(.12, .12, .16), Color(.62, .44, .32), Color(.1, .08, .06)],
	[Color(.55, .3, .35), Color(.18, .2, .26), Color(.72, .52, .38), Color(.25, .15, .08)],
]

static var overlay: ShaderMaterial

var kind: String = "record"
var identity: Dictionary
var body: Node3D
var animator: AnimationPlayer
var meshes: Array[MeshInstance3D] = []
var line: Label3D
var player: Node3D
var clock: float = 0.0
var twitch_left: float = 0.0
var calm_left: float = 0.0
var gesture_left: float = 0.0
var line_left: float = 0.0
var said: bool = false
## 0..1 while turning: drives the red glow and the shaking.
var dread: float = 0.0
var phase: String = "calm"
## Mid-conversation: the incident drives the gestures and the twitching waits.
var talking: bool = false
## What they do while waiting to turn: on the phone by default, now and then a gesture.
var idle_clip: String = "ual/phone"
var gesture_clip: String = "ual/talking"
var grounded_at: Vector3 = Vector3.INF


static func create(kind_: String, index: int) -> Node3D:
	var host: Node3D = (load("res://game/enemies/employee_host.gd") as GDScript).new()
	var crew: Array = DIALOGUES.crew(kind_)
	host.kind = kind_
	host.identity = crew[index % crew.size()]
	host.name = "Host_" + host.identity.name
	return host


func _ready() -> void:
	player = get_tree().get_first_node_in_group("players") as Node3D
	body = load(ROOT + identity.body).instantiate()
	body.scale = Vector3.ONE * .62
	add_child(body)
	animator = body.find_child("AnimationPlayer", true, false)
	animator.add_animation_library("ual", preload("res://game/player/engineer_animations.res"))
	for clip in ["Idle", "RecieveHit"]:
		animator.get_animation("CharacterArmature|" + clip).loop_mode = Animation.LOOP_LINEAR
	preload("res://game/incidents/coworkers.gd").dress(body, PALETTES[hash(identity.name) % PALETTES.size()], "office", identity.get("hair", ""))
	if overlay == null:
		overlay = ShaderMaterial.new()
		overlay.shader = OVERLAY
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh as MeshInstance3D
		meshes.append(instance)
		for surface in instance.mesh.get_surface_count():
			var source: Material = instance.get_active_material(surface)
			var skin: Material = source.duplicate() if source != null else StandardMaterial3D.new()
			skin.next_pass = overlay
			instance.set_surface_override_material(surface, skin)
			instance.set_instance_shader_parameter("glow", Color(1, .22, .3))
	line = Label3D.new()
	line.text = identity.line
	line.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	line.font = preload("res://assets/fonts/inter_variable.ttf")
	line.font_size = 34
	line.pixel_size = .0045
	line.outline_size = 10
	line.modulate = Color(.92, .95, 1, 0)
	line.position.y = 2.25
	line.no_depth_test = true
	line.visible = false
	add_child(line)
	animator.play(idle_clip)
	animator.seek(randf() * animator.current_animation_length, true)
	calm_left = randf_range(3.0, 7.0)
	gesture_left = randf_range(4.0, 9.0)


## A remark over their head, in their own voice: `node` is "hover" or "hr".
func say(node: String) -> void:
	var talk: Dictionary = DIALOGUES.data()
	line.text = talk.get("host_" + node, "…")
	line_left = 3.2
	var path: String = DIALOGUES.audio("host_%s_%s" % [str(identity.name).to_lower(), node])
	if DisplayServer.get_name() != "headless" and ResourceLoader.exists(path):
		var voice: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		voice.stream = load(path)
		voice.bus = &"Voice"
		voice.position.y = 1.4
		add_child(voice)
		voice.play()
		voice.finished.connect(voice.queue_free)


## Where the turn is, in seconds before the burst: calm, a ping (phone up), then the
## convulsion as the corruption takes hold.
func turn(remaining: float) -> void:
	if remaining > 1.7:
		_phase("calm")
	elif remaining > .9:
		_phase("ping")
		dread = lerpf(.15, .35, (1.7 - remaining) / .8)
	else:
		_phase("convulse")
		dread = lerpf(.4, 1.0, 1.0 - remaining / .9)


func _phase(next: String) -> void:
	if phase == next:
		return
	phase = next
	line_left = 0.0
	match next:
		"calm":
			animator.play(idle_clip, .2)
		"ping":
			# The notification lands: a P1 ticket, assigned to them.
			animator.play("ual/no", .15)
			ElementFx.glyphs(self, global_position + Vector3.UP * 1.9, Color(1, .5, .35), ["P1 ASSIGNED"], .9, 0.0)
		"convulse":
			animator.play("CharacterArmature|RecieveHit", .08)
			animator.speed_scale = 1.8


## Navigation voxels sit above the rendered floor. These presentation-only actors
## have no gravity, so resolve the physical support instead of keeping that height.
## Recheck after reparenting onto a monster, which can still be settling during a reveal.
func _physics_process(_delta: float) -> void:
	if global_position == grounded_at:
		return
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * .6, global_position - Vector3.UP * 1.5, 1)
	var support: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	if not support.is_empty() and (support.normal as Vector3).y > .7:
		global_position.y = (support.position as Vector3).y + .05
		grounded_at = global_position


func _process(delta: float) -> void:
	clock += delta
	var twitch: float = 0.0
	if talking:
		line_left = 0.0
	elif phase == "calm":
		calm_left -= delta
		if calm_left <= 0:
			calm_left = randf_range(5.0, 9.0)
			twitch_left = .3
		gesture_left -= delta
		if gesture_left <= 0:
			gesture_left = randf_range(6.0, 10.0)
			animator.play(gesture_clip, .25)
		elif not animator.is_playing() or animator.current_animation == gesture_clip and gesture_left < 3.0:
			# Talking loops forever on its own; after a few seconds they're back to idling.
			animator.play(idle_clip, .3)
		if is_instance_valid(player) and not said and player.global_position.distance_to(global_position) < 3.6:
			said = true
			line_left = 3.2
	twitch_left = maxf(0.0, twitch_left - delta)
	if twitch_left > 0:
		twitch = .55 * absf(sin(twitch_left * 40.0))
	line_left = maxf(0.0, line_left - delta)
	line.modulate.a = minf(1.0, line_left * 2.0)
	line.outline_modulate.a = line.modulate.a
	line.visible = line.modulate.a > .01
	var shake: float = dread * dread * .06 + twitch * .03
	body.position = Vector3(randf_range(-shake, shake), 0, randf_range(-shake, shake))
	var charge: float = maxf(dread, twitch)
	var flash: float = .6 if phase == "convulse" and fmod(clock, .16) < .05 else 0.0
	for mesh in meshes:
		mesh.set_instance_shader_parameter("charge", charge)
		mesh.set_instance_shader_parameter("flash", flash)
