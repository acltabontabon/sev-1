extends Node3D
## The victory ending of Incident 001, after the duel (duel.gd). The night:
##  "death"     slow motion, low: The Variance comes apart into a burst of receipts; the
##              ledger behind it reconciles one screen at a time.
##  "receipts"  receipts snow over the vault; a low orbit round the engineer, wrecked and
##              bloody, as his Unpaid Overtime slowly burns out; a receipt drifts down.
##  "cent"      close on it: the missing transaction, $0.01, cost: 5 staff (the narrator).
##  "memorial"  In Memoriam: a glide past each of the five where they fell.
##  "desk"      back at his desk: a new ticket. He stands up.
##  "exit"      he walks out across the dark floor to a sad theme; the five come back as
##              fading memories at desks along his way, each a whisper of what they said
##              to him tonight; the motion lights click off behind him.
##  "street"    midnight, street level, rain: he walks out of the tower and away.
##  "window"    up in the one lit window: five silhouettes watching him go. The narrator.
##  "resolved"  INCIDENT 001 — RESOLVED.
## Monday (leadership slept through all of it):
##  "card"      MONDAY, 9:00 AM. Statue unveiling. Attendance mandatory.
##  "arrival".. the lobby under the SYNERGEX logo: a covered statue, leadership, an audience
##              of one (him, cleaned up). The curtain drops on a bronze Chief Synergy
##              Officer standing on The Variance ("WHO SLEW THE VARIANCE · FROM HOME, ON
##              MUTE"). Self-thanks, a mandatory fun day, a photo for LinkedIn that crops
##              him out (the real frame, cropped), on call this weekend; the stream ends.
##  "next"      NEXT: INCIDENT 002.
## Presentation only, on real time (the photo freezes the world, not the scene). TAB skips.

const ROOT: String = "res://assets/characters/quaternius/"
const MOTION: AnimationLibrary = preload("res://game/player/engineer_animations.res")
const CREW = preload("res://game/incidents/coworkers.gd")
## Leadership: body, palette (shirt, pants, skin, hair), and where they stand by the statue.
const LEADERSHIP: Array = [
	["suit_male.fbx", [Color(.12, .12, .14), Color(.1, .1, .12), Color(.86, .66, .52), Color(.55, .5, .45)], Vector3(1.5, 0, 13.5)],
	["suit_female.fbx", [Color(.55, .1, .2), Color(.12, .1, .14), Color(.5, .33, .24), Color(.12, .08, .06)], Vector3(-2.1, 0, 13.5)],
	["casual2_female.fbx", [Color(.95, .85, .4), Color(.3, .32, .38), Color(.78, .58, .45), Color(.6, .35, .2)], Vector3(2.9, 0, 13.3)]]
const STATUE_AT: Vector3 = Vector3(-.3, 0, 14.6)
const PLAQUE: String = "IN HONOUR OF\nBRENT FAIRWEATHER\nCHIEF SYNERGY OFFICER\nWHO SLEW THE VARIANCE\nFRIDAY, 11:58 PM\n(FROM HOME, ON MUTE)"
## In Memoriam, in the order they fell.
const MEMORIAL: Array = [
	["Manager", "MORGAN", "MANAGER  ·  2019 – TONIGHT", "His calendar is still full."],
	["SRE", "NADIA", "SITE RELIABILITY  ·  2020 – TONIGHT", "Her pager is still ringing."],
	["Designer", "JUN", "PRODUCT DESIGN  ·  2021 – TONIGHT", "The kerning was perfect."],
	["Intern", "JO", "INTERN  ·  TODAY – TONIGHT", "Never got a badge photo."],
	["Director", "VAL", "DIRECTOR  ·  2018 – TONIGHT", "Her deck will be presented by someone else."]]
const MEMORIAL_EACH: float = 2.4
## The way out: their memories at desks along his path, doing what they did ([who, where,
## clip, facing]); each whispers the first thing they said to him tonight.
const MEMORIES: Array = [
	["Manager", Vector3(-1.2, 0, 13.4), "ual/phone", PI],
	["SRE", Vector3(.2, 0, 9.7), "ual/interact", 0.0],
	["Designer", Vector3(1.6, 0, 13.5), "ual/talking", PI],
	["Intern", Vector3(3.0, 0, 9.8), "ual/yes", 0.0],
	["Director", Vector3(4.4, 0, 13.5), "ual/phone", PI]]
## What used to play the moment it died, now the epilogue over the report.
const VICTORY_LINES: Array[String] = ["victory_thanks", "victory", "postmortem", "postmortem_owner"]
const VAULT_AT: Vector3 = Vector3(9.0, .05, -33.8)
const ENGINEER_AT: Vector3 = Vector3(-.3, .05, 10.2)
## At the far end of the line for the photo, at the very edge of the frame (cropped).
const PHOTO_EDGE: Vector3 = Vector3(3.6, .05, 13.2)
const WALK_SPEED: float = 1.25
const EXIT_PATH: Array[Vector3] = [Vector3(-2.5, .05, 11.4), Vector3(5.6, .05, 11.8)]
const EXIT_SECONDS: float = 9.0
## The street at the foot of the tower (its west face), and his way away from it.
const STREET_PATH: Array[Vector3] = [Vector3(-15.0, -69.95, 5.0), Vector3(-23.0, -69.95, 8.0)]
const STREET_SECONDS: float = 7.5
## The office's west window, where the night shift stands to watch him go.
const WINDOW: Vector3 = Vector3(-13.3, .05, 2.0)
const POST: String = "Humbled to share that I personally resolved a SEV-1 this weekend. Proud to unveil a small token of our team's gratitude.\n\nGrateful for our people. Thank you to everyone who made this possible (me).\n\n#leadership #courage #fromhome #grateful"
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
var leaders: Array[Dictionary] = []
var memories: Array[Dictionary] = []
var props: Array[Node] = []
var receipt: Node3D
var receipt_from: Vector3
var snow: CPUParticles3D
var spot: SpotLight3D
var live: Label3D
var curtain: MeshInstance3D
var mourn: AudioStreamPlayer
var focus: CameraAttributesPractical
var saved_attributes: CameraAttributes
var ledger: Array[Array] = []
var desk_texts: Array[String] = []
var bloodied: Array[MeshInstance3D] = []
var card: PanelContainer
var photo: TextureRect
var fade: ColorRect
var titles: Label
var memorial_name: Label
var memorial_line: Label


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
	saved_attributes = story.camera.attributes
	focus = CameraAttributesPractical.new()
	story.camera.attributes = focus
	mourn = AudioStreamPlayer.new()
	mourn.bus = &"Music"
	mourn.stream = load("res://assets/audio/music/mourning.wav")
	add_child(mourn)
	player.global_position = VAULT_AT
	player.velocity = Vector3.ZERO
	player.visual.rotation.y = 0.0
	_beat("death")


func _beat(next: String) -> void:
	beat = next
	beat_at = clock
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
		"desk":
			# Back at his desk. A new ticket.
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
			story.desk.alarm_title.text = "SEV-2  ·  COFFEE MACHINE DOWN"
			story.desk.alarm_detail.text = "Owner: YOU  ·  Due: Now  ·  Leadership is aware"
			story.desk.set_live(true)
			story.desk.alarm(true)
			story.sting(preload("res://assets/audio/sfx/chat_ping.ogg"), -4)
		"exit":
			character.story_pose = 0
			character.sit = 0.0
			player.global_position = EXIT_PATH[0]
			if DisplayServer.get_name() != "headless":
				mourn.volume_db = -30.0
				mourn.play()
				mourn.create_tween().tween_property(mourn, "volume_db", -8.0, 2.5)
			_summon_memories()
		"street":
			# A cut to the street: rain, a sodium lamp, the tower going up into the dark.
			for memory: Dictionary in memories:
				memory.body.hide()
			_exposure(.5)
			story._restore_lights()
			_stage_street()
			player.global_position = STREET_PATH[0]
			var away: Vector3 = STREET_PATH[1] - STREET_PATH[0]
			player.visual.rotation.y = atan2(-away.x, -away.z)
			story.say("doc_end")
		"window":
			_stage_window()
		"resolved":
			fade.show()
			titles.show()
			titles.text = "INCIDENT 001 — RESOLVED\nProduction recovered. Nobody else did."
		"card":
			titles.text = "MONDAY, 9:00 AM\nSTATUE UNVEILING  ·  ATTENDANCE MANDATORY"
			if mourn.playing:
				var out: Tween = mourn.create_tween()
				out.tween_property(mourn, "volume_db", -40.0, 1.8)
				out.tween_callback(mourn.stop)
			# Monday: he has showered. He has not slept.
			_unbloody()
		"arrival":
			_stage_unveiling()
			titles.hide()
			story.say("allhands_ceo")
			for ping in range(6):
				get_tree().create_timer(ping * .22, false).timeout.connect(story.sting.bind(preload("res://assets/audio/sfx/chat_ping.ogg"), -12))
		"unveil":
			# The curtain comes down on him: bronze, on top of it.
			var drop: Tween = curtain.create_tween()
			drop.tween_interval(.25)
			drop.tween_property(curtain, "scale:y", .03, .55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			drop.parallel().tween_property(curtain, "position:y", .05, .55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			get_tree().create_timer(.8, false).timeout.connect(_ta_da)
		"thanks":
			story.say("allhands_vp")
		"fun_day":
			story.say("allhands_people")
		"pose":
			# A cut: he has been waved to the far end of the line.
			player.global_position = PHOTO_EDGE
			player.visual.rotation.y = PI
			for leader: Dictionary in leaders:
				leader.animator.play("ual/victory", .2)
			story.say("allhands_photo")
		"photo":
			_snap()
		"leave":
			ElementFx.slow_motion(&"photo", 1.0)
			story.crew_freeze.hide()
			card.hide()
			live.text = "■  STREAM ENDED  ·  0 WATCHING"
			live.modulate = Color(.6, .6, .65)
			story.sting(preload("res://assets/audio/sfx/light_relay.ogg"), -2)
			player.global_position = ENGINEER_AT
			player.visual.rotation.y = PI
			for leader: Dictionary in leaders:
				leader.going = true
				leader.spot = leader.spot - Vector3(7.0, 0, 0)
			story.say("allhands_oncall")
		"alone":
			story.say("allhands_engineer")
		"next":
			titles.text = "NEXT: INCIDENT 002\nMONDAY, 9:05 AM"


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
	_walk(delta)
	var camera: Camera3D = story.camera
	var engineer: Vector3 = player.global_position
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
				_beat("desk")
		"desk":
			# Over his shoulder at the new ticket. He just looks at it.
			camera.global_position = story.SEAT + Vector3(-.75, 1.55, 1.15) + Vector3(.1, -.05, -.2) * minf(1.0, t / 3.0)
			camera.look_at(story.MONITOR)
			camera.fov = 40.0
			if t >= 3.0:
				_beat("exit")
		"exit":
			# Out across the floor, slowly, past them; each light goes out behind him.
			var walk: float = minf(1.0, t / EXIT_SECONDS)
			player.global_position = EXIT_PATH[0].lerp(EXIT_PATH[1], walk)
			var heading: Vector3 = EXIT_PATH[1] - EXIT_PATH[0]
			player.visual.rotation.y = atan2(-heading.x, -heading.z)
			for pool: Light3D in story.pools:
				if pool.light_energy > 0.0 and pool.global_position.x < engineer.x - 1.8 and absf(pool.global_position.z - engineer.z) < 6.0:
					pool.light_energy = 0.0
					story.sting(preload("res://assets/audio/sfx/light_relay.ogg"), -14)
			_haunt(real)
			if t < EXIT_SECONDS * .55:
				# Side on, a little ahead of him: the memories pass between us.
				camera.global_position = engineer + Vector3(1.6, 1.35, -3.4)
				camera.look_at(engineer + Vector3(.8, 1.0, 0))
				camera.fov = 46.0
			else:
				camera.global_position = engineer - heading.normalized() * 3.6 + Vector3(0, 1.5, .5)
				camera.look_at(engineer + Vector3.UP * 1.0 + heading.normalized() * 2.0)
				camera.fov = 48.0
			if t >= EXIT_SECONDS:
				_beat("street")
		"street":
			# Low across the wet street, the tower behind him; he walks out of frame.
			var walk: float = minf(1.0, t / STREET_SECONDS)
			player.global_position = STREET_PATH[0].lerp(STREET_PATH[1], walk)
			camera.global_position = Vector3(-28.0, -69.25, 11.8) + Vector3(.6, .15, -.4) * walk
			camera.look_at(Vector3(-18.0, -67.4, 6.0) + Vector3(0, 2.5, 0) * smoothstep(.6, 1.0, walk))
			camera.fov = 46.0
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
				_beat("arrival")
		"arrival":
			# Behind him, low: one man, a covered statue in a spotlight, leadership beaming.
			fade.color.a = 1.0 - smoothstep(0.0, .7, t)
			camera.global_position = Vector3(-2.6, 1.7, 7.4) + Vector3(.3, 0, .8) * minf(1.0, t / 6.0)
			camera.look_at(STATUE_AT + Vector3(.6, 1.4, 0))
			camera.fov = 46.0
			_focus_near(1.6)
			if t >= 4.0 and quiet:
				_beat("unveil")
		"unveil":
			# Low and slow up the statue as the cloth comes down; then the plaque.
			if t < 2.6:
				var rise: float = smoothstep(.2, 2.6, t)
				camera.global_position = STATUE_AT + Vector3(.9, .4 + rise * .5, -3.2)
				camera.look_at(STATUE_AT + Vector3.UP * lerpf(1.2, 2.6, rise))
				camera.fov = 40.0
			else:
				camera.global_position = STATUE_AT + Vector3(.2, .7, -2.6)
				camera.look_at(STATUE_AT + Vector3(0, .55, -.71))
				camera.fov = 26.0
			if t >= 5.0:
				_beat("thanks")
		"thanks":
			# Her, in the light, the statue over her shoulder.
			camera.global_position = Vector3(-1.2, 1.45, 11.4)
			camera.look_at(Vector3(-2.1, 1.15, 13.5))
			camera.fov = 34.0
			_focus_far(2.6)
			if t >= 1.0 and quiet:
				_beat("fun_day")
		"fun_day":
			# The reverse, from the stage: the whole audience, small, under the statue's gaze.
			camera.global_position = STATUE_AT + Vector3(.6, 2.6, -.9)
			camera.look_at(engineer + Vector3.UP * .9)
			camera.fov = 40.0
			if t >= 1.0 and quiet:
				_beat("pose")
		"pose":
			_photo_framing(camera)
			if t >= 1.0 and quiet:
				_beat("photo")
		"photo":
			_photo_framing(camera)
			if t >= 4.2:
				_beat("leave")
		"leave":
			# Close on him, low, as they walk off behind him.
			camera.global_position = engineer + Vector3(-.45, 1.15, 1.35)
			camera.look_at(engineer + Vector3.UP * 1.45)
			camera.fov = 36.0
			_focus_far(1.8)
			if t >= 1.2 and quiet:
				_beat("alone")
		"alone":
			# Low behind him, looking up past him at it.
			camera.global_position = engineer + Vector3(.5, .7, -1.6)
			camera.look_at(STATUE_AT + Vector3.UP * 2.4)
			camera.fov = 44.0
			if t >= 1.4 and quiet:
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
## Then (unless a restart is ending it) the night's last lines play over the report.
func finish(epilogue: bool = true) -> void:
	if done:
		return
	done = true
	if epilogue:
		story.say_sequence(VICTORY_LINES)
	ElementFx.slow_motion(&"photo", 1.0)
	ElementFx.slow_motion(&"finale", 1.0)
	story.crew_freeze.hide()
	story.panel.hide()
	character.overtime(false)
	character.story_pose = 0
	character.sit = 0.0
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
	# The report follows straight on; the orbit it usually waits for has been had.
	incident.ending_hold = minf(incident.ending_hold, .3)
	for group: Array[Dictionary] in [leaders, memories]:
		for someone: Dictionary in group:
			if is_instance_valid(someone.body):
				someone.body.queue_free()
		group.clear()
	for node: Node in props + [card, fade, titles, memorial_name, memorial_line]:
		if is_instance_valid(node):
			node.queue_free()
	props.clear()
	queue_free()


func _exit_tree() -> void:
	if not done:
		finish(false)


## Wrecked: his clothes dark and wet with it, from the vault to the street.
func _bloody() -> void:
	var gore: StandardMaterial3D = StandardMaterial3D.new()
	gore.albedo_color = Color(.32, .015, .02, .55)
	gore.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gore.roughness = .25
	for mesh: Node in player.visual.find_children("*", "MeshInstance3D", true, false):
		if (mesh as MeshInstance3D).material_overlay == null:
			(mesh as MeshInstance3D).material_overlay = gore
			bloodied.append(mesh)


func _unbloody() -> void:
	for mesh in bloodied:
		if is_instance_valid(mesh):
			mesh.material_overlay = null
	bloodied.clear()


## The five, as he remembers them tonight: pale, translucent, at desks along his way.
func _summon_memories() -> void:
	for entry: Array in MEMORIES:
		var cast: Dictionary = {}
		for member: Dictionary in CREW.CAST:
			if member.name == entry[0]:
				cast = member
		var body: Node3D = load(ROOT + cast.body).instantiate()
		incident.add_child(body)
		body.scale = Vector3.ONE * .62
		body.global_position = entry[1]
		body.rotation.y = entry[3]
		var ghost: StandardMaterial3D = StandardMaterial3D.new()
		ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost.albedo_color = Color(.72, .86, 1.0, 0.0)
		for mesh: Node in body.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).material_override = ghost
			(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
		animator.add_animation_library("ual", MOTION)
		animator.play(entry[2])
		var whisper: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		whisper.bus = &"Voice"
		whisper.stream = load("res://assets/audio/voices/talk/talk_%s_a.ogg" % str(entry[0]).to_lower())
		whisper.pitch_scale = .94
		whisper.unit_size = 4.0
		whisper.position.y = 1.4
		body.add_child(whisper)
		memories.append({"body": body, "ghost": ghost, "whisper": whisper, "seen": false, "glow": 0.0})


## Each memory comes up as he nears it, whispers, and fades once he has passed.
func _haunt(delta: float) -> void:
	for memory: Dictionary in memories:
		var body: Node3D = memory.body
		var along: float = player.global_position.x - body.global_position.x
		var near: bool = along > -2.6 and along < 1.4
		memory.glow = move_toward(memory.glow, .42 if near else 0.0, delta * (.5 if near else .3))
		memory.ghost.albedo_color.a = memory.glow
		if near and not memory.seen:
			memory.seen = true
			if DisplayServer.get_name() != "headless":
				var whisper: AudioStreamPlayer3D = memory.whisper
				whisper.volume_db = -6.0
				whisper.play()
				var hush: Tween = whisper.create_tween()
				hush.tween_interval(1.8)
				hush.tween_property(whisper, "volume_db", -40.0, 1.6)
				hush.tween_callback(whisper.stop)


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


## Monday in the lobby: a statue under red velvet in a spotlight, a LIVE sign, leadership
## either side of it, and him, cleaned up, the whole audience.
func _stage_unveiling() -> void:
	story.desk.alarm(false)
	character.sit = 0.0
	character.story_pose = 0
	player.global_position = ENGINEER_AT
	player.visual.rotation.y = PI
	_exposure(.55)
	var marble: StandardMaterial3D = StandardMaterial3D.new()
	marble.albedo_color = Color(.86, .85, .82)
	marble.roughness = .25
	var pedestal: MeshInstance3D = MeshInstance3D.new()
	var block: BoxMesh = BoxMesh.new()
	block.size = Vector3(1.4, 1.1, 1.4)
	pedestal.mesh = block
	pedestal.material_override = marble
	incident.add_child(pedestal)
	pedestal.global_position = STATUE_AT + Vector3.UP * .55
	props.append(pedestal)
	var plaque: Label3D = Label3D.new()
	plaque.text = PLAQUE
	plaque.font = preload("res://assets/fonts/cinzel_variable.ttf")
	plaque.font_size = 40
	plaque.pixel_size = .0024
	plaque.modulate = Color(.36, .22, .07)
	plaque.outline_size = 0
	plaque.rotation.y = PI
	incident.add_child(plaque)
	plaque.global_position = STATUE_AT + Vector3(0, .55, -.71)
	props.append(plaque)
	var bronze: StandardMaterial3D = StandardMaterial3D.new()
	bronze.albedo_color = Color(.55, .36, .18)
	bronze.metallic = .85
	bronze.roughness = .35
	# The Variance, slain, under his feet.
	var beast: Node3D = load("res://assets/enemies/ultimate_monsters/demon.gltf").instantiate()
	incident.add_child(beast)
	beast.scale = Vector3.ONE * .42
	beast.global_position = STATUE_AT + Vector3(0, 1.1, .15)
	beast.rotation.y = PI * .5
	_freeze_pose(beast, "Death", 1.0)
	_cast(beast, bronze)
	props.append(beast)
	# Him: heroic, a little larger than life, arms up.
	var hero: Node3D = load(ROOT + "suit_male.fbx").instantiate()
	incident.add_child(hero)
	hero.scale = Vector3.ONE * .62 * 1.3
	hero.global_position = STATUE_AT + Vector3(0, 1.32, -.1)
	hero.rotation.y = PI
	var pose: AnimationPlayer = hero.find_child("AnimationPlayer", true, false)
	pose.add_animation_library("ual", MOTION)
	_freeze_pose(hero, "ual/victory", .45)
	_cast(hero, bronze)
	props.append(hero)
	curtain = MeshInstance3D.new()
	var drape: BoxMesh = BoxMesh.new()
	drape.size = Vector3(1.9, 3.8, 1.9)
	curtain.mesh = drape
	var velvet: StandardMaterial3D = StandardMaterial3D.new()
	velvet.albedo_color = Color(.45, .03, .06)
	velvet.roughness = .95
	curtain.material_override = velvet
	incident.add_child(curtain)
	curtain.global_position = STATUE_AT + Vector3.UP * 1.9
	props.append(curtain)
	spot = SpotLight3D.new()
	spot.light_color = Color(1, .9, .75)
	spot.light_energy = 24.0
	spot.spot_range = 12.0
	spot.spot_angle = 26.0
	spot.shadow_enabled = true
	incident.add_child(spot)
	spot.global_position = Vector3(-.3, 6.4, 10.8)
	spot.look_at(STATUE_AT + Vector3.UP * 1.2)
	props.append(spot)
	live = Label3D.new()
	live.text = "●  LIVE  ·  STATUE UNVEILING  ·  3,412 WATCHING  ·  3,411 ON MUTE"
	live.font = preload("res://assets/fonts/barlow_condensed_bold.ttf")
	live.font_size = 64
	live.pixel_size = .0055
	live.modulate = Color(1, .3, .25)
	live.outline_size = 8
	live.rotation.y = PI
	incident.add_child(live)
	live.global_position = Vector3(-.3, 4.4, 15.5)
	props.append(live)
	for entry: Array in LEADERSHIP:
		var body: Node3D = load(ROOT + entry[0]).instantiate()
		incident.add_child(body)
		body.scale = Vector3.ONE * .62
		CREW.dress(body, entry[1])
		var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
		animator.add_animation_library("ual", MOTION)
		body.global_position = entry[2]
		body.rotation.y = PI
		animator.play("ual/talking")
		leaders.append({"body": body, "animator": animator, "spot": entry[2], "going": false})


## Ta-da: confetti from both sides, a flash on the bronze.
func _ta_da() -> void:
	if done:
		return
	story.sting(preload("res://assets/audio/sfx/low_boom.ogg"), -4)
	story.sting(preload("res://assets/audio/sfx/ui_confirm.ogg"), -2)
	ElementFx.flash(incident, STATUE_AT + Vector3.UP * 2.4, Color(1, .85, .55), 6.0, 7.0, .4)
	for side in [-1.0, 1.0]:
		for colour: Color in [Color(1, .3, .6), Color(.3, .8, 1), Color(1, .85, .2), Color(.5, 1, .5)]:
			ElementFx.shards(incident, STATUE_AT + Vector3(side * 2.4, .3, -.6), colour, 18, 7.0, 2.0, Vector3(-side * .4, 1, 0), .1)


## Hold a model in one frame of a clip, as a statue does.
func _freeze_pose(model: Node3D, clip: String, at: float) -> void:
	var animator: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	if animator == null or not animator.has_animation(clip):
		return
	animator.play(clip)
	animator.seek(animator.get_animation(clip).length * at, true)
	animator.pause()


func _cast(model: Node3D, metal: Material) -> void:
	for mesh: Node in model.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = metal


func _walk(delta: float) -> void:
	for leader: Dictionary in leaders:
		if not leader.going:
			continue
		var body: Node3D = leader.body
		var to: Vector3 = leader.spot - body.global_position
		to.y = 0
		if to.length() < .08:
			leader.going = false
			body.hide()
			continue
		body.global_position += to.normalized() * minf(to.length(), WALK_SPEED * delta)
		body.rotation.y = lerp_angle(body.rotation.y, atan2(to.x, to.z), 1.0 - exp(-8.0 * delta))
		if leader.animator.assigned_animation != "ual/walk_formal" or not leader.animator.is_playing():
			leader.animator.play("ual/walk_formal", .2)


func _photo_framing(camera: Camera3D) -> void:
	camera.global_position = Vector3(.4, 1.5, 9.6)
	camera.look_at(Vector3(.4, 1.7, 14.0))
	camera.fov = 60.0


## The flash, the freeze, and the post: the frame itself, cropped to leave him out.
func _snap() -> void:
	ElementFx.flash(incident, Vector3(.4, 1.6, 10.2), Color(1, 1, .95), 8.0, 10.0, .3)
	story.sting(preload("res://assets/audio/sfx/light_relay.ogg"), -2)
	if DisplayServer.get_name() != "headless":
		var frame: Image = get_viewport().get_texture().get_image()
		var size: Vector2i = frame.get_size()
		# Leadership and the statue; the left edge (his end of the line) goes.
		var crop: Image = frame.get_region(Rect2i(int(size.x * .26), int(size.y * .05), int(size.x * .74), int(size.y * .78)))
		photo.texture = ImageTexture.create_from_image(crop)
		story.whiteout(.35)
	story.crew_freeze.visible = true
	(story.crew_freeze.material as ShaderMaterial).set_shader_parameter("amount", .55)
	(story.crew_freeze.material as ShaderMaterial).set_shader_parameter("tint", Color(.8, .82, .9))
	ElementFx.slow_motion(&"photo", .02)
	card.show()
	card.modulate.a = 0.0
	var arrive: Tween = card.create_tween()
	arrive.set_ignore_time_scale(true)
	arrive.tween_interval(.35)
	arrive.tween_property(card, "modulate:a", 1.0, .25)


func _build_ui() -> void:
	card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Off to the right of the frozen frame, which stays in view on the left.
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	card.offset_left = -600
	card.offset_right = -60
	card.offset_top = -300
	card.offset_bottom = 300
	card.rotation = deg_to_rad(-1.5)
	var paper: StyleBoxFlat = StyleBoxFlat.new()
	paper.bg_color = Color(1, 1, 1)
	paper.set_corner_radius_all(10)
	paper.set_content_margin_all(18)
	paper.shadow_color = Color(0, 0, 0, .45)
	paper.shadow_size = 18
	card.add_theme_stylebox_override("panel", paper)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)
	column.add_child(_text("Brent Fairweather · Chief Synergy Officer at SYNERGEX · 1st\nPosted Monday, 9:04 AM · Edited", 15, Color(.35, .37, .4)))
	column.add_child(_text(POST, 17, Color(.1, .1, .12)))
	photo = TextureRect.new()
	photo.custom_minimum_size = Vector2(500, 250)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	column.add_child(photo)
	column.add_child(_text("♥ 4,812   ·   312 comments   ·   97 reposts   ·   1 engineer cropped out", 16, Color(.35, .37, .4)))
	card.hide()
	story.add_child(card)
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


func _text(words: String, size: int, colour: Color) -> Label:
	var label: Label = Label.new()
	label.text = words
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 500
	label.add_theme_font_override("font", preload("res://assets/fonts/inter_variable.ttf"))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label
