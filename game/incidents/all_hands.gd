extends Node3D
## The victory ending of Incident 001, after the duel (duel.gd). The night:
##  "death"     slow motion, low: The Variance comes apart into a burst of receipts; the
##              ledger behind it reconciles one screen at a time.
##  "receipts"  receipts snow over the vault; a low orbit round the engineer, wrecked and
##              bloody, as his Unpaid Overtime slowly burns out; a receipt drifts down.
##  "cent"      close on it: the missing transaction, $0.01, cost: 5 staff (the narrator).
##  "memorial"  In Memoriam: a glide past each of the five where they fell.
##  "grief"     a last look at JO; a tear rolls down the engineer's cheek.
##  "desk"      back at his desk: he collects his mug and personal effects.
##  "exit"      he walks through the empty lift corridor to a sad theme; the five return as
##              fading memories along its edges, ordinary coffee/lunch/gossip
##              fragments with matching quiet captions; the motion lights click off behind him.
##  "street"    midnight, street level, rain: he walks out of the tower and away.
##  "window"    up in the one lit window: five silhouettes watching him go. The narrator.
##  "resolved"  INCIDENT 001 — RESOLVED.
## Monday (leadership slept through all of it):
##  "card"      MONDAY, 9:00 AM. Blameless postmortem. Attendance mandatory.
##  "monday"    the postmortem call in the Quick Sync room (postmortem_call.gd).
##  "return"    Monday again: out of the meeting, back to his desk, another workday.
##  "next"      END OF INCIDENT 001.
## Presentation only, on real time (the photo freezes the world, not the scene). TAB skips.

const ROOT: String = "res://assets/characters/quaternius/"
const MOTION: AnimationLibrary = preload("res://game/player/engineer_animations.res")
const CREW = preload("res://game/incidents/coworkers.gd")
const DIALOGUES = preload("res://game/incidents/dialogues.gd")
## In Memoriam, in the order they fell.
const MEMORIAL: Array = [
	["Manager", "MORGAN", "MANAGER  ·  2019 – TONIGHT", "His calendar is still full."],
	["SRE", "NADIA", "SITE RELIABILITY  ·  2020 – TONIGHT", "Her pager is still ringing."],
	["Designer", "JUN", "PRODUCT DESIGN  ·  2021 – TONIGHT", "The kerning was perfect."],
	["Intern", "JO", "INTERN  ·  TODAY – TONIGHT", "Never got a badge photo."],
	["Director", "VAL", "DIRECTOR  ·  2018 – TONIGHT", "Her deck will be presented by someone else."]]
const MEMORIAL_EACH: float = 2.4
## The way out: each memory recalls an ordinary conversation beside the clear route.
const MEMORIES: Array = [
	["Manager", "ual/phone"],
	["SRE", "ual/interact"],
	["Designer", "ual/talking"],
	["Intern", "ual/yes"],
	["Director", "ual/phone"]]
const VAULT_AT: Vector3 = Vector3(9.0, .05, -33.8)
const POSTMORTEM: Script = preload("res://game/incidents/postmortem_call.gd")
const DEPARTURE: PackedScene = preload("res://game/incidents/departure_corridor.tscn")
const NIGHTLIFE: Script = preload("res://game/incidents/nightlife_street.gd")
const DEPARTURE_AT: Vector3 = Vector3(0, -120, 0)
const EXIT_PATH: Array[Vector3] = [DEPARTURE_AT + Vector3(-6, .05, 0), DEPARTURE_AT + Vector3(7.1, .05, 0)]
const EXIT_SECONDS: float = 9.0
const DOOR_PATH: Array[Vector3] = [EXIT_PATH[1], DEPARTURE_AT + Vector3(14.2, .05, 0)]
const DOOR_SECONDS: float = 6.5
## The street at the foot of the tower (its west face), and his way away from it.
const STREET_PATH: Array[Vector3] = [Vector3(-15.0, -69.95, 6.2), Vector3(-23.0, -69.95, 8.0)]
const STREET_SECONDS: float = 7.5
## The office's west window, where the night shift stands to watch him go.
const WINDOW: Vector3 = Vector3(-13.3, .05, 2.0)
## Every line the same width (monospace), so a centred block reads as a printed column.
const RECEIPT: String = "  SYNERGEX PAYMENTS  \nFRI 23:58   VAULT 01\n- - - - - - - - - - \nTXN           000001\nSTATUS         FOUND\nAMOUNT         $0.01\n- - - - - - - - - - \nCOST         5 STAFF\n- - - - - - - - - - \n THANK YOU FOR YOUR \n     SACRIFICE      "

var story: Node
var incident: Node
var player: CharacterBody3D
var character: Node3D
var beat: String = ""
var beat_at: float = 0.0
var clock: float = 0.0
var done: bool = false
var memories: Array[Dictionary] = []
var props: Array[Node] = []
var receipt: Node3D
var receipt_from: Vector3
var snow: CPUParticles3D
var meeting: Node3D
var mourn: AudioStreamPlayer
var focus: CameraAttributesPractical
var saved_attributes: CameraAttributes
var ledger: Array[Array] = []
var desk_texts: Array[String] = []
var bloodied: Array[MeshInstance3D] = []
var fade: ColorRect
var titles: Label
var memorial_name: Label
var memorial_line: Label
var memory_caption: Label
var tear_anchor: Node3D
var tear: MeshInstance3D
var belongings: Node3D
var carry_anchor: Node3D
var belongings_from: Vector3
var exit_duration: float = EXIT_SECONDS
var weapon_was_visible: bool
var parked_sword: Node3D
var sword_from: Transform3D
var sword_rest: Transform3D
var saved_clock: String
var departure: Node3D
var nightlife: Node3D


func _init(presentation: Node) -> void:
	story = presentation
	incident = presentation.incident
	player = incident.player
	character = player.get_node("Visual/Character")
	name = "AllHands"


func start() -> void:
	_build_ui()
	story._caption_layout(true)
	for index in range(3):
		var screen: Label3D = incident.room.get_node("LedgerText%d" % index)
		ledger.append([screen, screen.text, screen.modulate])
	desk_texts = [story.desk.alarm_title.text, story.desk.alarm_detail.text]
	saved_clock = incident.room.get_node("Clock").text
	saved_attributes = story.camera.attributes
	weapon_was_visible = character.weapon.visible
	focus = CameraAttributesPractical.new()
	story.camera.attributes = focus
	mourn = AudioStreamPlayer.new()
	mourn.bus = &"Music"
	var theme: AudioStreamWAV = load("res://assets/audio/music/mourning.wav").duplicate()
	theme.loop_mode = AudioStreamWAV.LOOP_FORWARD
	theme.loop_end = int(theme.get_length() * theme.mix_rate)
	mourn.stream = theme
	add_child(mourn)
	player.global_position = VAULT_AT
	player.velocity = Vector3.ZERO
	player.visual.rotation.y = 0.0
	_beat("death")


func _beat(next: String) -> void:
	beat = next
	beat_at = clock
	character.story_walk_speed = 0.0
	focus.dof_blur_far_enabled = false
	focus.dof_blur_near_enabled = false
	match beat:
		"death":
			ElementFx.slow_motion(&"finale", .3)
			var at: Vector3 = _boss_at()
			ElementFx.flash(incident, at + Vector3.UP * 1.5, Color(1, .95, .85), 9.0, 14.0, .5)
			ElementFx.shockwave(incident, at + Vector3.UP * .05, Color(1, .95, .85), 6.0, .7)
			ElementFx.shards(incident, at + Vector3.UP * 1.6, Color(.95, .93, .88), 60, 7.0, 1.8, Vector3.UP, .16)
			story.sting(preload("res://assets/audio/sfx/low_boom.ogg"), -2)
			_snowfall()
		"receipts":
			ElementFx.slow_motion(&"finale", 1.0)
			_bloody()
			character.story_pose = character.Pose.LOOK_DOWN
			character.overtime_fade(5.0)
			_drop_receipt()
		"cent":
			story.say("doc_cent")
		"memorial":
			memorial_name.show()
			memorial_line.show()
			_start_mourning()
		"grief":
			memorial_name.hide()
			memorial_line.hide()
			var fallen: Vector3 = _fallen_at("Intern")
			player.global_position = fallen + Vector3(0, .05, 1.15)
			player.visual.rotation.y = 0.0
			character.story_pose = character.Pose.LOOK_DOWN
			character.weapon.hide()
			_build_tear()
		"desk":
			# The machine still wants something. He takes only what belongs to him.
			memorial_name.hide()
			memorial_line.hide()
			if is_instance_valid(snow):
				snow.emitting = false
			if is_instance_valid(receipt):
				receipt.hide()
			_exposure(.6)
			player.global_position = story.SEAT
			player.visual.rotation.y = 0.0
			character.story_pose = character.Pose.TYPING
			character.sit = 1.0
			tear_anchor.hide()
			_build_belongings()
			_park_sword()
			story.desk.alarm_title.text = "SEV-2  ·  COFFEE MACHINE DOWN"
			story.desk.alarm_detail.text = "Owner: YOU  ·  Due: Now  ·  Leadership is aware"
			story.desk.set_live(true)
			story.desk.alarm(true)
			story.sting(preload("res://assets/audio/sfx/chat_ping.ogg"), -4)
		"exit":
			character.story_hand_targets.clear()
			character.story_pose = 0
			character.sit = 0.0
			player.global_position = EXIT_PATH[0]
			departure = DEPARTURE.instantiate()
			incident.add_child(departure)
			departure.global_position = DEPARTURE_AT
			props.append(departure)
			_summon_memories()
		"door":
			memory_caption.hide()
			for memory: Dictionary in memories:
				memory.body.hide()
			player.global_position = DOOR_PATH[0]
			departure.set_door(0.0)
			story.sting(preload("res://assets/audio/sfx/door_open.ogg"), -10)
		"street":
			# A cut to the street: rain, a sodium lamp, the tower going up into the dark.
			if is_instance_valid(departure):
				departure.hide()
			for memory: Dictionary in memories:
				memory.body.hide()
			memory_caption.hide()
			_exposure(.5)
			story._restore_lights()
			_stage_street()
			player.global_position = STREET_PATH[0]
			var away: Vector3 = STREET_PATH[1] - STREET_PATH[0]
			player.visual.rotation.y = atan2(-away.x, -away.z)
			story.say("doc_end")
		"window":
			if is_instance_valid(nightlife):
				nightlife.hide()
			_stage_window()
		"resolved":
			fade.show()
			titles.show()
			titles.text = "INCIDENT 001 — RESOLVED\nProduction recovered. Nobody else did."
		"card":
			incident.room.get_node("Clock").text = "MONDAY / 09:00"
			titles.text = "MONDAY, 9:00 AM\nBLAMELESS POSTMORTEM  ·  ATTENDANCE MANDATORY"
			if mourn.playing:
				var out: Tween = mourn.create_tween()
				out.tween_property(mourn, "volume_db", -40.0, 1.8)
				out.tween_callback(mourn.stop)
			# Monday: he has showered. He has not slept. The gold is long gone.
			_unbloody()
			character.overtime(false)
			character.story_pose = 0
			character.sit = 0.0
			character.story_hand_targets.clear()
			character.story_sit_progress = -1.0
			belongings.hide()
		"monday":
			titles.hide()
			_exposure(.9)
			meeting = POSTMORTEM.new(story)
			add_child(meeting)
			meeting.start()
		"next":
			titles.text = "TO BE CONTINUED"
		"return_meeting":
			meeting.ended.show()
			character.story_pose = 0
		"return_floor":
			meeting.finish()
			meeting = null
			player.global_position = Vector3(4.6, .05, 11.4)
		"return_desk":
			incident.room.get_node("Clock").text = "MONDAY / 09:05"
			player.global_position = Vector3(-.5, .05, 11.4)
			story.desk.alarm(false)
			story.desk.alarm_title.text = "MONDAY  ·  09:05"
			story.desk.alarm_detail.text = "NEW DAY. SAME DESK."
			story.desk.set_live(true)


## Returns false when it is over (or skipped).
func tick(delta: float) -> bool:
	if done:
		return false
	var real: float = delta / maxf(Engine.time_scale, .01)
	clock += real
	var t: float = clock - beat_at
	var quiet: bool = story.voice.current_line.is_empty() and story.voice.queue.is_empty()
	incident.main.get_node("HUD").visible = false
	player.narrative_hold = true
	story.caption.text = story.voice.subtitle
	story.panel.visible = not story.voice.subtitle.is_empty() and beat not in ["memorial", "card", "resolved", "next"]
	var camera: Camera3D = story.camera
	var engineer: Vector3 = player.global_position
	if is_instance_valid(belongings) and beat != "desk":
		belongings.global_transform = _carry_transform()
	match beat:
		"death":
			# Low, looking up: it comes apart; the ledger behind it reconciles.
			var boss: Vector3 = _boss_at()
			var inward: Vector3 = Vector3(VAULT_AT.x - boss.x, 0, VAULT_AT.z - boss.z - 3.0).normalized()
			camera.global_position = boss + inward * (3.6 - .6 * minf(1.0, t / 3.0)) + inward.cross(Vector3.UP) * 1.2 + Vector3.UP * .35
			camera.look_at(boss + Vector3.UP * 2.0)
			camera.fov = 48.0
			for index in range(3):
				if t - real < .9 + index * .45 and t >= .9 + index * .45:
					var screen: Label3D = incident.room.get_node("LedgerText%d" % index)
					screen.text = "SUCCESS"
					screen.modulate = Color(.3, 1, .6)
					story.sting(preload("res://assets/audio/sfx/ui_confirm.ogg"), -8)
			if t >= 3.0:
				_beat("receipts")
		"receipts":
			# A low orbit round him among them; the gold burns out; the lights come back.
			var angle: float = lerpf(3.6, 4.4, smoothstep(0.0, 5.5, t))
			camera.global_position = engineer + Vector3(sin(angle), 0, cos(angle)) * 3.0 + Vector3.UP * lerpf(.6, 1.0, minf(1.0, t / 5.5))
			camera.look_at(engineer + Vector3.UP * 1.1)
			camera.fov = 46.0
			_focus_far(3.0)
			for index in range(story.vault_lights.size()):
				story.vault_lights[index].light_energy = story.vault_energy[index] * smoothstep(1.0 + index * .6, 2.5 + index * .6, t)
			_float_receipt(t)
			if t >= 5.5:
				_beat("cent")
		"cent":
			# Close on it, him soft behind it: one cent.
			_float_receipt(5.5 + t)
			var at: Vector3 = receipt.global_position
			camera.global_position = at + Vector3(.1, .02, -.9) + Vector3(0, 0, .18) * minf(1.0, t / 4.0)
			camera.look_at(at)
			camera.fov = 36.0
			_focus_far(1.0)
			if t >= 2.0 and quiet:
				_beat("memorial")
		"memorial":
			# Where each of them fell, in the order they fell; receipts settling on them.
			var index: int = mini(int(t / MEMORIAL_EACH), MEMORIAL.size() - 1)
			var local: float = t - index * MEMORIAL_EACH
			var entry: Array = MEMORIAL[index]
			var place: Vector3 = _fallen_at(entry[0])
			var inward: Vector3 = Vector3(VAULT_AT.x - place.x, 0, VAULT_AT.z - place.z).normalized()
			var side: Vector3 = inward.cross(Vector3.UP)
			camera.global_position = place + Vector3.UP * 1.1 + inward * 1.7 + side * (.9 - local * .3)
			camera.look_at(place + Vector3.UP * .4)
			camera.fov = 40.0
			_focus_far(3.2)
			memorial_name.text = entry[1]
			memorial_line.text = "%s\n%s" % [entry[2], entry[3]]
			var alpha: float = smoothstep(0.0, .5, local) * (1.0 - smoothstep(MEMORIAL_EACH - .45, MEMORIAL_EACH, local))
			memorial_name.modulate.a = alpha
			memorial_line.modulate.a = alpha
			if t >= MEMORIAL_EACH * MEMORIAL.size():
				_beat("grief")
		"grief":
			# First his colleague, then the face of someone who cannot fix this.
			var head: Vector3 = tear_anchor.global_position
			if t < 2.2:
				camera.global_position = engineer + Vector3(.7, 1.5, .6)
				camera.look_at(_fallen_at("Intern") + Vector3.UP * .3)
				camera.fov = 42.0
			else:
				camera.global_position = head + Vector3(.45, .2, -2.0).lerp(Vector3(.35, .15, -1.7), smoothstep(2.2, 6.5, t))
				camera.look_at(head + Vector3(0, .15, -.08))
				camera.fov = 40.0
			tear.position.y = .21 - .14 * smoothstep(2.6, 6.6, t)
			tear.scale = Vector3(.75, lerpf(.6, 1.7, smoothstep(2.2, 6.0, t)), .65)
			if t >= 7.0:
				_beat("desk")
		"desk":
			parked_sword.global_transform = sword_from.interpolate_with(sword_rest, smoothstep(0.0, 1.7, t))
			character.story_pose = character.Pose.GLANCE if t < 2.5 else character.Pose.ARMED
			character.sit = 1.0 - smoothstep(2.5, 4.0, t)
			var box_hand: Vector3 = character.to_global(Vector3(-.35, .72, -.06))
			var carried: Transform3D = Transform3D(Basis.IDENTITY, box_hand + Vector3(0, -.22, 0))
			belongings.global_position = belongings_from.lerp(carried.origin, smoothstep(3.4, 5.2, t))
			belongings.global_basis = Basis.IDENTITY.slerp(carried.basis, smoothstep(3.4, 5.2, t))
			var left: Vector3 = character.to_local(belongings.global_position + Vector3.UP * .22)
			var right: Vector3 = character.to_local(parked_sword.global_transform * Vector3(0, 0, -.65))
			character.story_hand_targets.assign([
				Vector3(-.28, .55, .08).lerp(left, smoothstep(2.6, 3.4, t)),
				right.lerp(Vector3(.32, .7, .03), smoothstep(1.7, 2.6, t))])
			camera.global_position = story.SEAT + Vector3(1.6, 1.55, -.45)
			camera.look_at(belongings.global_position + Vector3.UP * .2)
			camera.fov = 42.0
			if t >= 6.0:
				_beat("exit")
		"exit":
			# A dedicated corridor keeps furniture and live coworkers out of the shot.
			var travel: Vector4 = departure.travel(t)
			character.story_walk_speed = travel.w
			character.story_pose = character.Pose.ARMED if travel.w <= .001 else character.Pose.NONE
			player.global_position = Vector3(travel.x, travel.y, travel.z)
			engineer = player.global_position
			var heading: Vector3 = EXIT_PATH[1] - EXIT_PATH[0]
			player.visual.rotation.y = atan2(-heading.x, -heading.z)
			for pool: Light3D in departure.find_children("Pool*", "Light3D", false, false):
				if pool.light_energy > 0.0 and pool.global_position.x < engineer.x - 1.8 and absf(pool.global_position.z - engineer.z) < 6.0:
					pool.light_energy = 0.0
					story.sting(preload("res://assets/audio/sfx/light_relay.ogg"), -14)
			_haunt(t)
			if t < exit_duration * .55:
				# Side on, a little ahead of him: the memories pass between us.
				camera.global_position = engineer + Vector3(-2.8, 1.7, -3.0)
				camera.look_at(engineer + Vector3(.4, 1.0, .7))
				camera.fov = 50.0
			else:
				camera.global_position = engineer - heading.normalized() * 4.4 + Vector3(0, 1.7, -2.0)
				camera.look_at(engineer + Vector3(1.2, 1.0, 1.0))
				camera.fov = 54.0
			if t >= exit_duration:
				_beat("door")
		"door":
			# Hold a full-body view: the mark, opening panels and threshold all stay in frame.
			character.story_pose = character.Pose.NONE
			departure.set_door(smoothstep(.15, 1.35, t))
			player.global_position = DOOR_PATH[0].lerp(DOOR_PATH[1], _walk_progress(t, DOOR_SECONDS))
			character.story_walk_speed = _walk_speed(t, DOOR_SECONDS, DOOR_PATH[0].distance_to(DOOR_PATH[1]))
			player.visual.rotation.y = -PI * .5
			camera.global_position = DEPARTURE_AT + Vector3(5.0, 1.65, -1.8)
			camera.look_at(DEPARTURE_AT + Vector3(10.2, 1.8, 0))
			camera.fov = 52.0
			if t >= DOOR_SECONDS:
				_beat("street")
		"street":
			# Low across the wet street, the tower behind him; he walks out of frame.
			nightlife.tick(t)
			var walk: float = _walk_progress(t, STREET_SECONDS)
			character.story_walk_speed = _walk_speed(t, STREET_SECONDS, STREET_PATH[0].distance_to(STREET_PATH[1]))
			player.global_position = STREET_PATH[0].lerp(STREET_PATH[1], walk)
			camera.global_position = Vector3(-30.0, -68.1, 12.8) + Vector3(.6, .15, -.4) * walk
			camera.look_at(Vector3(-18.0, -68.0, 5.5) + Vector3(0, 3.0, 0) * smoothstep(.6, 1.0, walk))
			camera.fov = 50.0
			if t >= STREET_SECONDS:
				_beat("window")
		"window":
			# Long lens from across the city, up to the one lit window: the night shift.
			camera.global_position = Vector3(-74.0, 13.0, 28.0)
			camera.look_at(WINDOW + Vector3.UP * .9)
			camera.fov = lerpf(3.2, 2.6, minf(1.0, t / 5.0))
			if t >= 4.5 and quiet:
				_beat("resolved")
		"resolved":
			fade.color.a = smoothstep(0.0, .8, t)
			titles.modulate.a = smoothstep(.8, 1.3, t) * (1.0 - smoothstep(3.4, 3.8, t))
			if t >= 3.9:
				_beat("card")
		"card":
			fade.color.a = 1.0
			titles.modulate.a = smoothstep(0.0, .35, t) * (1.0 - smoothstep(1.9, 2.3, t))
			if t >= 2.4:
				_beat("monday")
		"monday":
			fade.color.a = 1.0 - smoothstep(0.0, .7, t)
			if not meeting.tick(real):
				_beat("return_meeting")
		"return_meeting", "return_floor":
			var from: Vector3 = POSTMORTEM.STANDS_AT if beat == "return_meeting" else Vector3(4.6, .05, 11.4)
			var to: Vector3 = Vector3(17.7, .05, -8.75) if beat == "return_meeting" else Vector3(.6, .05, 11.4)
			var length: float = 3.2
			player.global_position = from.lerp(to, _walk_progress(t, length))
			character.story_walk_speed = _walk_speed(t, length, from.distance_to(to))
			player.visual.rotation.y = PI * .5
			camera.global_position = player.global_position + (Vector3(-1.4, 2.2, .9) if beat == "return_meeting" else Vector3(-2.4, 2.4, -1.1))
			camera.look_at(player.global_position + Vector3.UP * 1.1)
			camera.fov = 50.0
			if t >= length:
				_beat("return_floor" if beat == "return_meeting" else "return_desk")
		"return_desk":
			if t < 3.0:
				var from: Vector3 = Vector3(-.5, .05, 11.4)
				player.global_position = from.lerp(story.SEAT, _walk_progress(t, 3.0))
				character.story_walk_speed = _walk_speed(t, 3.0, from.distance_to(story.SEAT))
				var heading: Vector3 = story.SEAT - from
				player.visual.rotation.y = atan2(-heading.x, -heading.z)
			else:
				player.global_position = story.SEAT
				player.visual.rotation.y = lerp_angle(player.visual.rotation.y, 0.0, 1.0 - exp(-5.0 * real))
				character.story_walk_speed = 0.0
				character.story_pose = character.Pose.TYPING
				character.story_sit_progress = smoothstep(3.0, 4.8, t)
			camera.global_position = story.SEAT + Vector3(-1.9, 2.25, 2.1)
			camera.look_at(story.SEAT + Vector3(0, 1.15, -.5))
			camera.fov = 54.0
			if t >= 8.0:
				_beat("next")
		"next":
			fade.show()
			fade.color.a = smoothstep(0.0, .8, t)
			titles.show()
			titles.modulate.a = smoothstep(.8, 1.3, t) * (1.0 - smoothstep(3.0, 3.4, t))
			if t >= 3.5:
				finish()
				return false
	camera.make_current()
	return true


## Skipped or over: everything it made goes, and the world is left as the ending found it.
## The report is silent: Monday already delivered the final word.
func finish(completed: bool = true) -> void:
	if done:
		return
	done = true
	story.finale_completed = completed
	story.sequence.clear()
	story.voice.clear()
	ElementFx.slow_motion(&"photo", 1.0)
	ElementFx.slow_motion(&"finale", 1.0)
	story.crew_freeze.hide()
	story.panel.hide()
	character.overtime(false)
	character.story_pose = 0
	character.sit = 0.0
	character.story_hand_targets.clear()
	character.story_walk_speed = 0.0
	character.story_sit_progress = -1.0
	character.weapon.visible = weapon_was_visible
	player.global_position = VAULT_AT
	_unbloody()
	story._restore_lights()
	_exposure(1.0)
	story.camera.attributes = saved_attributes
	for index in range(story.vault_lights.size()):
		story.vault_lights[index].light_energy = story.vault_energy[index]
	for screen: Array in ledger:
		if is_instance_valid(screen[0]):
			screen[0].text = screen[1]
			screen[0].modulate = screen[2]
	if desk_texts.size() == 2:
		story.desk.alarm(false)
		story.desk.alarm_title.text = desk_texts[0]
		story.desk.alarm_detail.text = desk_texts[1]
	incident.room.get_node("Clock").text = saved_clock
	# The report follows straight on; the orbit it usually waits for has been had.
	incident.ending_hold = minf(incident.ending_hold, .3)
	for memory: Dictionary in memories:
		if is_instance_valid(memory.body):
			memory.body.queue_free()
	memories.clear()
	if is_instance_valid(meeting):
		meeting.finish()
	for node: Node in props + [fade, titles, memorial_name, memorial_line, memory_caption]:
		if is_instance_valid(node):
			node.queue_free()
	props.clear()
	queue_free()
	if completed:
		story.finale_finished.emit()


func _exit_tree() -> void:
	if not done:
		finish(false)


## Wrecked: his clothes dark and wet with it, from the vault to the street.
func _bloody() -> void:
	for mesh: Node in player.visual.find_children("*", "MeshInstance3D", true, false):
		if (mesh as MeshInstance3D).material_overlay == null:
			(mesh as MeshInstance3D).material_overlay = Blood.coating(mesh as MeshInstance3D)
			bloodied.append(mesh)


func _unbloody() -> void:
	for mesh in bloodied:
		if is_instance_valid(mesh):
			mesh.material_overlay = null
	bloodied.clear()


func _start_mourning() -> void:
	if DisplayServer.get_name() == "headless":
		return
	mourn.volume_db = -30.0
	mourn.play()
	mourn.create_tween().tween_property(mourn, "volume_db", -10.0, 3.0)


## Small wet geometry attached to the animated head, rather than a screen-space icon.
func _build_tear() -> void:
	var unit: float = 1.0 / character.skeleton.global_basis.get_scale().x
	tear_anchor = character._attach("Head", unit)
	props.append(tear_anchor.get_parent())
	tear = MeshInstance3D.new()
	var drop: SphereMesh = SphereMesh.new()
	drop.radius = .014
	drop.height = .028
	tear.mesh = drop
	var water: StandardMaterial3D = StandardMaterial3D.new()
	water.albedo_color = Color(.7, .85, .93, .85)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = .05
	water.metallic = .35
	tear.material_override = water
	tear.position = Vector3(.18, .21, .325)
	tear.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tear_anchor.add_child(tear)
	var fill: OmniLight3D = OmniLight3D.new()
	fill.position = Vector3(.5, .2, -.8)
	fill.light_color = Color(.72, .8, 1)
	fill.light_energy = .7
	fill.omni_range = 2.0
	tear_anchor.add_child(fill)


## A small cardboard box: his laptop, his mug and JO's handwritten lunch reminder.
func _build_belongings() -> void:
	belongings = Node3D.new()
	incident.add_child(belongings)
	props.append(belongings)
	belongings_from = story.SEAT + Vector3(.65, .86, -.85)
	belongings.global_position = belongings_from
	var cardboard: StandardMaterial3D = StandardMaterial3D.new()
	cardboard.albedo_color = Color(.48, .33, .2)
	cardboard.roughness = .95
	_box_part(Vector3(.42, .02, .3), Vector3.ZERO, cardboard)
	for side: float in [-1.0, 1.0]:
		_box_part(Vector3(.02, .22, .3), Vector3(side * .21, .11, 0), cardboard)
		_box_part(Vector3(.42, .22, .02), Vector3(0, .11, side * .15), cardboard)
	var laptop: StandardMaterial3D = StandardMaterial3D.new()
	laptop.albedo_color = Color(.13, .15, .17)
	laptop.metallic = .5
	_box_part(Vector3(.27, .3, .025), Vector3(-.055, .18, .045), laptop)
	var mug: MeshInstance3D = MeshInstance3D.new()
	var cup: CylinderMesh = CylinderMesh.new()
	cup.top_radius = .05
	cup.bottom_radius = .045
	cup.height = .12
	mug.mesh = cup
	var ceramic: StandardMaterial3D = StandardMaterial3D.new()
	ceramic.albedo_color = Color(.85, .83, .75)
	ceramic.roughness = .25
	mug.material_override = ceramic
	mug.position = Vector3(.12, .12, -.065)
	belongings.add_child(mug)
	var note: Label3D = Label3D.new()
	note.text = "MONDAY LUNCH?\n— JO"
	note.font = preload("res://assets/fonts/barlow_condensed_semibold.ttf")
	note.font_size = 32
	note.pixel_size = .0011
	note.modulate = Color(.98, .88, .59)
	note.outline_size = 0
	note.position = Vector3(0, .115, -.162)
	note.rotation.y = PI
	belongings.add_child(note)
	var unit: float = 1.0 / character.skeleton.global_basis.get_scale().x
	var hand: Node3D = character._attach("Fist.L", unit)
	carry_anchor = Node3D.new()
	hand.add_child(carry_anchor)
	props.append(hand.get_parent())


func _carry_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, player.visual.rotation.y), carry_anchor.global_position + Vector3(0, -.22, 0))


## Integral of a .6-second smooth velocity ramp: feet and travel start/stop together.
func _walk_progress(time: float, length: float) -> float:
	var t: float = clampf(time, 0.0, length)
	var ramp: float = .6
	var distance: float
	if t < ramp:
		distance = t * t * t / (ramp * ramp) - .5 * pow(t, 4) / pow(ramp, 3)
	elif t > length - ramp:
		var remaining: float = length - t
		distance = length - ramp - (pow(remaining, 3) / pow(ramp, 2) - .5 * pow(remaining, 4) / pow(ramp, 3))
	else:
		distance = t - ramp * .5
	return distance / (length - ramp)


func _walk_speed(time: float, length: float, distance: float) -> float:
	return maxf(.001, distance / (length - .6) * smoothstep(0.0, .6, time) * (1.0 - smoothstep(length - .6, length, time)))


## Blade down beside the workstation, clear of its tabletop, keyboard and monitor.
func _park_sword() -> void:
	parked_sword = character.weapon.duplicate()
	incident.add_child(parked_sword)
	props.append(parked_sword)
	parked_sword.show()
	parked_sword.global_transform = Transform3D(Basis.from_euler(Vector3(-PI * .5, 0, 0)), Vector3(story.SEAT.x - 1.5, 0, story.SEAT.z - .87))
	# Include the rotated tip and every child mesh so the actual blade touches the floor.
	parked_sword.global_position.y += .02 - sword_bounds().position.y
	sword_rest = parked_sword.global_transform
	sword_from = Transform3D(sword_rest.basis, sword_rest.origin + Vector3(0, .22, .28))
	parked_sword.global_transform = sword_from


func sword_bounds() -> AABB:
	var bounds: AABB
	var began: bool = false
	for mesh: Node in parked_sword.find_children("*", "MeshInstance3D", true, false):
		var local: AABB = (mesh as MeshInstance3D).get_aabb()
		for corner in range(8):
			var point: Vector3 = mesh.global_transform * local.get_endpoint(corner)
			if not began:
				bounds = AABB(point, Vector3.ZERO)
				began = true
			else:
				bounds = bounds.expand(point)
	return bounds


func _box_part(size: Vector3, at: Vector3, material: Material) -> void:
	var part: MeshInstance3D = MeshInstance3D.new()
	var shape: BoxMesh = BoxMesh.new()
	shape.size = size
	part.mesh = shape
	part.material_override = material
	part.position = at
	belongings.add_child(part)


## The five, as he remembers them tonight: pale, translucent, beside the lift corridor.
func _summon_memories() -> void:
	var cue: float = .7
	for entry: Array in MEMORIES:
		var cast: Dictionary = {}
		for member: Dictionary in CREW.CAST:
			if member.name == entry[0]:
				cast = member
		var body: Node3D = load(ROOT + cast.body).instantiate()
		incident.add_child(body)
		body.scale = Vector3.ONE * .62
		body.global_position = EXIT_PATH[0]
		var ghost: StandardMaterial3D = StandardMaterial3D.new()
		ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost.albedo_color = Color(.84, .79, .69, 0.0)
		for mesh: Node in body.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).material_override = ghost
			(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
		animator.add_animation_library("ual", MOTION)
		animator.play(entry[1])
		var remembered: Dictionary = DIALOGUES.memory(entry[0])
		var whisper: AudioStreamPlayer = AudioStreamPlayer.new()
		whisper.bus = &"Voice"
		whisper.stream = load(DIALOGUES.audio(remembered.clip))
		whisper.volume_db = -10.0
		body.add_child(whisper)
		var length: float = whisper.stream.get_length()
		memories.append({"body": body, "ghost": ghost, "whisper": whisper, "seen": false,
			"cue": cue, "length": length, "text": remembered.text, "who": DIALOGUES.tree(entry[0]).who})
		cue += length + .9
	departure.configure(memories, EXIT_PATH[0], EXIT_PATH[1])
	exit_duration = departure.duration


## One intelligible fragment at a time. A memory vanishes after its line, not mid-word.
func _haunt(time: float) -> void:
	memory_caption.hide()
	for memory: Dictionary in memories:
		var within: float = time - float(memory.cue)
		var length: float = memory.length
		var alpha: float = smoothstep(-.4, .4, within) * (1.0 - smoothstep(length, length + .7, within))
		memory.ghost.albedo_color.a = alpha * .14
		if within >= 0.0 and not memory.seen:
			memory.seen = true
			if DisplayServer.get_name() != "headless":
				memory.whisper.play()
		if within >= 0.0 and within < length and story.voice.subtitles_enabled:
			memory_caption.text = "%s · remembered\n%s" % [memory.who, memory.text]
			memory_caption.modulate.a = smoothstep(0.0, .3, within) * (1.0 - smoothstep(length - .3, length, within))
			memory_caption.show()


func _boss_at() -> Vector3:
	return incident.boss.global_position if is_instance_valid(incident.boss) else incident.arrival_site()


func _fallen_at(who: String) -> Vector3:
	var someone: Dictionary = incident.coworkers.person(who)
	if not someone.is_empty() and someone.body.visible:
		return Vector3(someone.body.global_position.x, 0, someone.body.global_position.z)
	return CREW.STAGE[who].spot


func _exposure(level: float) -> void:
	incident.main.get_node("WorldEnvironment").environment.tonemap_exposure = story.base_exposure * level


func _focus_far(distance: float) -> void:
	focus.dof_blur_far_enabled = true
	focus.dof_blur_far_distance = distance
	focus.dof_blur_far_transition = distance * .8
	focus.dof_blur_amount = .12


func _focus_near(distance: float) -> void:
	focus.dof_blur_near_enabled = true
	focus.dof_blur_near_distance = distance
	focus.dof_blur_near_transition = 1.0
	focus.dof_blur_amount = .1


## Paper over the vault: every transaction it was hiding, coming down slowly.
func _snowfall() -> void:
	snow = CPUParticles3D.new()
	snow.amount = 260
	snow.lifetime = 9.0
	snow.preprocess = 2.0
	snow.local_coords = false
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(7.5, .2, 6.5)
	snow.direction = Vector3.DOWN
	snow.spread = 25.0
	snow.gravity = Vector3(0, -.45, 0)
	snow.initial_velocity_min = .1
	snow.initial_velocity_max = .4
	snow.particle_flag_rotate_y = true
	snow.angular_velocity_min = -160.0
	snow.angular_velocity_max = 160.0
	snow.angle_max = 360.0
	snow.scale_amount_min = .7
	snow.scale_amount_max = 1.2
	var slip: QuadMesh = QuadMesh.new()
	slip.size = Vector2(.13, .2)
	var paper: StandardMaterial3D = StandardMaterial3D.new()
	paper.albedo_color = Color(.93, .92, .88)
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	paper.emission_enabled = true
	paper.emission = Color(.5, .5, .48)
	paper.emission_energy_multiplier = .25
	slip.material = paper
	snow.mesh = slip
	snow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	incident.add_child(snow)
	snow.global_position = Vector3(9, 5.6, -38)
	props.append(snow)


## The missing transaction: a thermal-paper receipt, drifting down to him.
func _drop_receipt() -> void:
	receipt = Node3D.new()
	var slip: MeshInstance3D = MeshInstance3D.new()
	var face: QuadMesh = QuadMesh.new()
	face.size = Vector2(.24, .5)
	slip.mesh = face
	var paper: StandardMaterial3D = StandardMaterial3D.new()
	paper.albedo_color = Color(.96, .95, .91)
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	paper.roughness = .9
	paper.emission_enabled = true
	paper.emission = Color(.95, .93, .88)
	paper.emission_energy_multiplier = .35
	slip.material_override = paper
	receipt.add_child(slip)
	var printed: Label3D = Label3D.new()
	printed.text = RECEIPT
	printed.font = preload("res://assets/fonts/jetbrains_mono_variable.ttf")
	printed.font_size = 32
	printed.pixel_size = .00052
	printed.modulate = Color(.12, .12, .13)
	printed.outline_size = 0
	printed.double_sided = true
	printed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	printed.position.z = .002
	receipt.add_child(printed)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.light_color = Color(1, .9, .75)
	glow.light_energy = .6
	glow.omni_range = 1.4
	receipt.add_child(glow)
	incident.add_child(receipt)
	receipt_from = player.global_position + Vector3(.4, 4.2, -1.4)
	receipt.global_position = receipt_from
	props.append(receipt)


## Down in a lazy sway to just in front of his chest, then hanging there.
func _float_receipt(t: float) -> void:
	if not is_instance_valid(receipt):
		return
	var settle: float = smoothstep(0.0, 6.0, t)
	var rest: Vector3 = player.global_position + Vector3(0, 1.15, -.55)
	receipt.global_position = receipt_from.lerp(rest, settle) + Vector3(sin(t * 1.7) * .35, 0, cos(t * 1.3) * .12) * (1.0 - settle)
	receipt.rotation = Vector3(sin(t * 2.1) * .5 * (1.0 - settle), PI + sin(t * 1.1) * .4 * (1.0 - settle), sin(t * 1.6) * .3 * (1.0 - settle))


## Midnight at the foot of the tower: rain, a sodium streetlamp, a cold fill.
func _stage_street() -> void:
	if is_instance_valid(nightlife):
		nightlife.show()
	else:
		nightlife = NIGHTLIFE.new()
		incident.add_child(nightlife)
		props.append(nightlife)
	var rain: CPUParticles3D = CPUParticles3D.new()
	rain.amount = 900
	rain.lifetime = 1.2
	rain.preprocess = 1.2
	rain.local_coords = false
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(16, .5, 12)
	rain.direction = Vector3(.15, -1, .05)
	rain.spread = 3.0
	rain.gravity = Vector3(0, -20, 0)
	rain.initial_velocity_min = 12.0
	rain.initial_velocity_max = 15.0
	rain.particle_flag_align_y = true
	var streak: QuadMesh = QuadMesh.new()
	streak.size = Vector2(.012, .45)
	var wet: StandardMaterial3D = StandardMaterial3D.new()
	wet.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wet.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wet.albedo_color = Color(.65, .72, .85, .35)
	wet.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	streak.material = wet
	rain.mesh = streak
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	incident.add_child(rain)
	rain.global_position = Vector3(-22, -60, 9)
	props.append(rain)
	var lamp: OmniLight3D = OmniLight3D.new()
	lamp.light_color = Color(1, .62, .3)
	lamp.light_energy = 3.0
	lamp.omni_range = 9.0
	lamp.shadow_enabled = true
	incident.add_child(lamp)
	lamp.global_position = Vector3(-20.5, -64.5, 9.5)
	props.append(lamp)
	var cold: OmniLight3D = OmniLight3D.new()
	cold.light_color = Color(.45, .55, .85)
	cold.light_energy = 1.2
	cold.omni_range = 14.0
	incident.add_child(cold)
	cold.global_position = Vector3(-26, -67, 13)
	props.append(cold)


## Five of them in the lit window, black against the light, watching him go.
func _stage_window() -> void:
	var black: StandardMaterial3D = StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color(.01, .01, .012)
	for index in range(5):
		var figure: Node3D = Node3D.new()
		var body: MeshInstance3D = MeshInstance3D.new()
		var torso: CapsuleMesh = CapsuleMesh.new()
		torso.radius = .2
		torso.height = 1.15
		body.mesh = torso
		body.material_override = black
		body.position.y = .58
		figure.add_child(body)
		var head: MeshInstance3D = MeshInstance3D.new()
		var ball: SphereMesh = SphereMesh.new()
		ball.radius = .14
		ball.height = .28
		head.mesh = ball
		head.material_override = black
		head.position.y = 1.32
		figure.add_child(head)
		incident.add_child(figure)
		figure.global_position = WINDOW + Vector3(0, 0, (index - 2) * .62)
		props.append(figure)
	var warm: OmniLight3D = OmniLight3D.new()
	warm.light_color = Color(1, .8, .55)
	warm.light_energy = 6.0
	warm.omni_range = 7.0
	incident.add_child(warm)
	warm.global_position = WINDOW + Vector3(2.6, 1.4, 0)
	props.append(warm)



func _build_ui() -> void:
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.hide()
	story.add_child(fade)
	titles = Label.new()
	titles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	titles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titles.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_bold.ttf"))
	titles.add_theme_font_size_override("font_size", 64)
	titles.add_theme_color_override("font_color", Color(.95, .93, .9))
	titles.modulate.a = 0.0
	titles.hide()
	story.add_child(titles)
	# In Memoriam: quiet white type, bottom left, no box.
	memorial_name = _memorial(72, -300, 110)
	memorial_line = _memorial(28, -205, 114)
	memory_caption = Label.new()
	memory_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	memory_caption.offset_top = -160
	memory_caption.offset_bottom = -65
	memory_caption.offset_left = 160
	memory_caption.offset_right = -160
	memory_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory_caption.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_semibold.ttf"))
	memory_caption.add_theme_font_size_override("font_size", 27)
	memory_caption.add_theme_color_override("font_color", Color(.85, .82, .75))
	memory_caption.add_theme_constant_override("outline_size", 5)
	memory_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	memory_caption.hide()
	story.add_child(memory_caption)


func _memorial(size: int, top: float, left: float) -> Label:
	var label: Label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	label.offset_left = left
	label.offset_top = top
	label.add_theme_font_override("font", preload("res://assets/fonts/barlow_condensed_semibold.ttf"))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(.96, .95, .92))
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, .6))
	label.hide()
	story.add_child(label)
	return label
