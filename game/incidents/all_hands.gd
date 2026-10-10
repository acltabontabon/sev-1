extends Node3D
## The victory ending of Incident 001, after the boss's kill cam:
##  "death"     slow motion, low: The Variance comes apart into a burst of receipts; the
##              ledger behind it reconciles one screen at a time.
##  "receipts"  receipts snow over the vault; a low orbit round the engineer as his Unpaid
##              Overtime slowly burns out; one gold receipt drifts down to him.
##  "cent"      close on it: the missing transaction, one cent (the narrator).
##  "memorial"  In Memoriam: a glide past each of the five where they fell.
##  "card"      11:58 PM. Mandatory all-hands.
##  "arrival".. the lobby under the SYNERGEX logo, lit like a keynote, an audience of one
##              in the dark: leadership thanks itself, announces a mandatory fun day,
##              poses ("synergy!") for a LinkedIn post that crops him out (the real frame,
##              cropped), and puts him on call this weekend. The spotlight clunks off.
##  "desk"      back at his desk: a new ticket. Head down.
##  "flyout"    the opening's fly-in in reverse, out of the tower into the night; the
##              narrator; the title card.
## Presentation only, on real time (the photo freezes the world, not the scene). TAB skips.

const ROOT: String = "res://assets/characters/quaternius/"
const MOTION: AnimationLibrary = preload("res://game/player/engineer_animations.res")
const CREW = preload("res://game/incidents/coworkers.gd")
## Leadership: body, palette (shirt, pants, skin, hair), and a spot on the "stage" under
## the logo, 1.6 m apart. They walk in single file from the east, in the order they stand
## (nobody passes anybody), and out to the west the same way.
const LEADERSHIP: Array = [
	["suit_male.fbx", [Color(.12, .12, .14), Color(.1, .1, .12), Color(.86, .66, .52), Color(.55, .5, .45)], Vector3(-.3, 0, 14.0)],
	["suit_female.fbx", [Color(.55, .1, .2), Color(.12, .1, .14), Color(.5, .33, .24), Color(.12, .08, .06)], Vector3(-1.9, 0, 14.0)],
	["casual2_female.fbx", [Color(.95, .85, .4), Color(.3, .32, .38), Color(.78, .58, .45), Color(.6, .35, .2)], Vector3(1.3, 0, 14.0)]]
const WINGS: float = 6.5
## In Memoriam, in the order they fell.
const MEMORIAL: Array = [
	["Manager", "MORGAN", "MANAGER  ·  2019 – TONIGHT", "His calendar is still full."],
	["SRE", "NADIA", "SITE RELIABILITY  ·  2020 – TONIGHT", "Her pager is still ringing."],
	["Designer", "JUN", "PRODUCT DESIGN  ·  2021 – TONIGHT", "The kerning was perfect."],
	["Intern", "JO", "INTERN  ·  TODAY – TONIGHT", "Never got a badge photo."],
	["Director", "VAL", "DIRECTOR  ·  2018 – TONIGHT", "Her deck will be presented by someone else."]]
const MEMORIAL_EACH: float = 2.4
const VAULT_AT: Vector3 = Vector3(9.0, .05, -33.8)
const ENGINEER_AT: Vector3 = Vector3(-.3, .05, 10.2)
## At the end of the line for the photo, just outside the crop.
const PHOTO_EDGE: Vector3 = Vector3(2.9, .05, 13.8)
const WALK_SPEED: float = 1.25
const POST: String = "Humbled to share that our leadership team resolved a SEV-1 tonight.\n\nProud of what we built. Grateful for our people. Thank you to everyone who made this possible (leadership).\n\n#leadership #resilience #weareafamily #grateful"

var story: Node
var incident: Node
var player: CharacterBody3D
var character: Node3D
var beat: String = ""
var beat_at: float = 0.0
var clock: float = 0.0
var done: bool = false
var leaders: Array[Dictionary] = []
var props: Array[Node] = []
var receipt: Node3D
var receipt_from: Vector3
var snow: CPUParticles3D
var spot: SpotLight3D
var rim: OmniLight3D
var focus: CameraAttributesPractical
var saved_attributes: CameraAttributes
var ledger: Array[Array] = []
var desk_texts: Array[String] = []
var fly: Array[Array] = []
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
			character.story_pose = character.Pose.LOOK_DOWN
			character.overtime_fade(5.0)
			_drop_receipt()
		"cent":
			story.say("doc_cent")
		"memorial":
			memorial_name.show()
			memorial_line.show()
		"card":
			memorial_name.hide()
			memorial_line.hide()
			titles.text = "11:58 PM\nMANDATORY ALL-HANDS"
			titles.show()
			fade.show()
			story.sting(preload("res://assets/audio/sfx/low_boom.ogg"), -8)
		"arrival":
			_stage_lobby()
			titles.hide()
			# Leadership, in the wings until now.
			for entry: Array in LEADERSHIP:
				var body: Node3D = load(ROOT + entry[0]).instantiate()
				incident.add_child(body)
				body.scale = Vector3.ONE * .62
				CREW.dress(body, entry[1])
				var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
				animator.add_animation_library("ual", MOTION)
				body.global_position = Vector3(WINGS + (entry[2].x + 1.9) / 1.6 * 1.2, 0, entry[2].z)
				leaders.append({"body": body, "animator": animator, "spot": entry[2], "going": true})
			story.say("allhands_ceo")
			for ping in range(6):
				get_tree().create_timer(ping * .22, false).timeout.connect(story.sting.bind(preload("res://assets/audio/sfx/chat_ping.ogg"), -12))
		"thanks":
			story.say("allhands_vp")
		"fun_day":
			story.say("allhands_people")
		"pose":
			# A cut: he has been waved to the end of the line.
			player.global_position = PHOTO_EDGE
			player.visual.rotation.y = PI
			for leader: Dictionary in leaders:
				leader.going = false
				leader.body.global_position = leader.spot
				leader.body.rotation.y = PI
				leader.animator.play("ual/victory", .2)
			story.say("allhands_photo")
		"photo":
			_snap()
		"leave":
			ElementFx.slow_motion(&"photo", 1.0)
			story.crew_freeze.hide()
			card.hide()
			# The keynote is over: the spotlight clunks off and he is left in the dark.
			spot.visible = false
			story.sting(preload("res://assets/audio/sfx/light_relay.ogg"), -2)
			_exposure(.22)
			player.global_position = ENGINEER_AT
			player.visual.rotation.y = PI
			for leader: Dictionary in leaders:
				leader.going = true
				leader.spot = leader.spot - Vector3(WINGS, 0, 0)
			story.say("allhands_oncall")
		"alone":
			story.say("allhands_engineer")
		"desk":
			# Back at his desk. A new ticket. Head down.
			for leader: Dictionary in leaders:
				leader.body.hide()
			rim.visible = false
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
		"flyout":
			story.say("doc_end")
			# The opening's fly-in, backwards: from his shoulder, out of the window, up.
			fly = [[story.camera.global_position, story.MONITOR]]
			for index in range(story.FLY.size() - 1, -1, -1):
				fly.append(story.FLY[index])


## Returns false when it is over (or skipped).
func tick(delta: float) -> bool:
	if done:
		return false
	var real: float = delta / maxf(Engine.time_scale, .01)
	clock += real
	var t: float = clock - beat_at
	var quiet: bool = story.voice.current_line.is_empty() and story.voice.queue.is_empty()
	incident.main.get_node("HUD").visible = false
	story.caption.text = story.voice.subtitle
	story.panel.visible = not story.voice.subtitle.is_empty() and beat not in ["memorial", "card"]
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
			camera.global_position = at + Vector3(.18, .06, -.95) + Vector3(0, 0, .25) * minf(1.0, t / 4.0)
			camera.look_at(at)
			camera.fov = 34.0
			_focus_far(1.1)
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
				_beat("card")
		"card":
			fade.color.a = 1.0
			titles.modulate.a = smoothstep(0.0, .35, t) * (1.0 - smoothstep(1.7, 2.1, t))
			if t >= 2.2:
				_beat("arrival")
		"arrival":
			# Behind him, low: one silhouette in the dark, the keynote lit up ahead.
			fade.color.a = 1.0 - smoothstep(0.0, .7, t)
			camera.global_position = Vector3(-1.0, 1.05, 8.2) + Vector3(.2, 0, .7) * minf(1.0, t / 6.0)
			camera.look_at(Vector3(-.3, 1.5, 14.0))
			camera.fov = 44.0
			_focus_near(1.6)
			if t >= 4.0 and quiet:
				_beat("thanks")
		"thanks":
			# Close on her in the spotlight.
			camera.global_position = Vector3(-1.45, 1.4, 12.0)
			camera.look_at(Vector3(-1.9, 1.12, 14.0))
			camera.fov = 30.0
			_focus_far(2.4)
			if t >= 1.0 and quiet:
				_beat("fun_day")
		"fun_day":
			# The reverse, from the stage: the whole audience, small, alone, in the dark.
			camera.global_position = Vector3(1.4, 2.1, 13.5)
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
			camera.global_position = engineer + Vector3(-.45, 1.15, 1.35) + Vector3(0, .05, .2) * minf(1.0, t / 2.0)
			camera.look_at(engineer + Vector3.UP * 1.45)
			_focus_far(1.8)
			if t >= 1.0 and quiet:
				_beat("desk")
		"desk":
			# Over his shoulder at the new ticket; then his head goes down on the desk.
			camera.global_position = story.SEAT + Vector3(-.75, 1.55, 1.15) + Vector3(.1, -.05, -.2) * minf(1.0, t / 3.0)
			camera.look_at(story.MONITOR)
			camera.fov = 40.0
			if t - real < 1.6 and t >= 1.6:
				character.story_pose = character.Pose.SLUMP
			if t >= 3.4:
				_beat("flyout")
		"flyout":
			var u: float = smoothstep(0.0, 9.0, t) * (fly.size() - 1)
			var segment: int = mini(int(u), fly.size() - 2)
			var points: Array[Vector3] = []
			var looks: Array[Vector3] = []
			for offset in [-1, 0, 1, 2]:
				var index: int = clampi(segment + offset, 0, fly.size() - 1)
				points.append(fly[index][0])
				looks.append(fly[index][1])
			camera.global_position = story._catmull(points, u - segment)
			camera.look_at(story._catmull(looks, u - segment))
			camera.fov = lerpf(42.0, 32.0, smoothstep(0.0, 9.0, t))
			fade.show()
			fade.color.a = smoothstep(8.2, 9.4, t)
			titles.show()
			titles.text = "INCIDENT 001 — RESOLVED\nProduction recovered. Nobody else did." if t < 12.0 else "NEXT: INCIDENT 002\nMONDAY, 9:00 AM"
			titles.modulate.a = smoothstep(9.4, 9.9, t) * (1.0 - smoothstep(11.6, 12.0, t)) + smoothstep(12.0, 12.4, t) * (1.0 - smoothstep(14.2, 14.6, t))
			if t >= 14.6:
				finish()
				return false
	camera.make_current()
	return true


## Skipped or over: everything it made goes, and the world is left as the ending found it.
func finish() -> void:
	if done:
		return
	done = true
	ElementFx.slow_motion(&"photo", 1.0)
	ElementFx.slow_motion(&"finale", 1.0)
	story.crew_freeze.hide()
	story.panel.hide()
	character.overtime(false)
	character.story_pose = 0
	character.sit = 0.0
	player.global_position = VAULT_AT
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
	for leader: Dictionary in leaders:
		if is_instance_valid(leader.body):
			leader.body.queue_free()
	leaders.clear()
	for node: Node in props + [card, fade, titles, memorial_name, memorial_line]:
		if is_instance_valid(node):
			node.queue_free()
	props.clear()
	queue_free()


func _exit_tree() -> void:
	if not done:
		finish()


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


## The missing transaction, in gold, drifting down to him.
func _drop_receipt() -> void:
	receipt = Node3D.new()
	var slip: MeshInstance3D = MeshInstance3D.new()
	var face: QuadMesh = QuadMesh.new()
	face.size = Vector2(.3, .46)
	slip.mesh = face
	var gold: StandardMaterial3D = StandardMaterial3D.new()
	gold.albedo_color = Color(1, .92, .7)
	gold.cull_mode = BaseMaterial3D.CULL_DISABLED
	gold.emission_enabled = true
	gold.emission = Color(1, .75, .35)
	gold.emission_energy_multiplier = 1.4
	slip.material_override = gold
	receipt.add_child(slip)
	var printed: Label3D = Label3D.new()
	printed.text = "SYNERGEX PAYMENTS\n— — — — — —\nTXN 000001\nAMOUNT  $0.01\nSTATUS  FOUND"
	printed.font = preload("res://assets/fonts/barlow_condensed_semibold.ttf")
	printed.font_size = 40
	printed.pixel_size = .0016
	printed.modulate = Color(.15, .1, .05)
	printed.outline_size = 0
	printed.double_sided = true
	printed.position.z = .002
	receipt.add_child(printed)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.light_color = Color(1, .8, .45)
	glow.light_energy = 1.2
	glow.omni_range = 1.8
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


## The lobby as a keynote: a warm spot on the stage, a LIVE sign, the room dim, a cold
## edge of light on him.
func _stage_lobby() -> void:
	if is_instance_valid(snow):
		snow.emitting = false
	if is_instance_valid(receipt):
		receipt.hide()
	character.story_pose = 0
	player.global_position = ENGINEER_AT
	player.visual.rotation.y = PI
	_exposure(.4)
	spot = SpotLight3D.new()
	spot.light_color = Color(1, .9, .75)
	spot.light_energy = 22.0
	spot.spot_range = 12.0
	spot.spot_angle = 24.0
	spot.shadow_enabled = true
	incident.add_child(spot)
	spot.global_position = Vector3(-.3, 6.2, 10.6)
	spot.look_at(Vector3(-.3, 0, 14.0))
	props.append(spot)
	rim = OmniLight3D.new()
	rim.light_color = Color(.4, .55, 1)
	rim.light_energy = 1.6
	rim.omni_range = 3.5
	incident.add_child(rim)
	rim.global_position = ENGINEER_AT + Vector3(0, 2.0, -1.4)
	props.append(rim)
	var live: Label3D = Label3D.new()
	live.text = "●  LIVE  ·  ALL-HANDS  ·  3,412 WATCHING  ·  3,411 ON MUTE"
	live.font = preload("res://assets/fonts/barlow_condensed_bold.ttf")
	live.font_size = 64
	live.pixel_size = .006
	live.modulate = Color(1, .3, .25)
	live.outline_size = 8
	incident.add_child(live)
	live.global_position = Vector3(-.3, 2.75, 15.5)
	live.rotation.y = PI
	props.append(live)


func _walk(delta: float) -> void:
	for leader: Dictionary in leaders:
		if not leader.going:
			continue
		var body: Node3D = leader.body
		var to: Vector3 = leader.spot - body.global_position
		to.y = 0
		if to.length() < .08:
			leader.going = false
			# On stage, facing the audience (of one).
			body.rotation.y = PI
			leader.animator.play("ual/talking", .3)
			continue
		body.global_position += to.normalized() * minf(to.length(), WALK_SPEED * delta)
		body.rotation.y = lerp_angle(body.rotation.y, atan2(to.x, to.z), 1.0 - exp(-8.0 * delta))
		if leader.animator.assigned_animation != "ual/walk_formal" or not leader.animator.is_playing():
			leader.animator.play("ual/walk_formal", .2)


func _photo_framing(camera: Camera3D) -> void:
	camera.global_position = Vector3(-.15, 1.45, 10.1)
	camera.look_at(Vector3(-.15, 1.3, 13.9))
	camera.fov = 44.0


## Confetti, the flash, the freeze, and the post: the frame itself, cropped to leave him out.
func _snap() -> void:
	for side in [-1.0, 1.0]:
		for colour: Color in [Color(1, .3, .6), Color(.3, .8, 1), Color(1, .85, .2), Color(.5, 1, .5)]:
			ElementFx.shards(incident, Vector3(side * 3.6 - .3, .3, 14.2), colour, 18, 7.0, 2.0, Vector3(-side * .5, 1, 0), .1)
	ElementFx.flash(incident, Vector3(-.15, 1.6, 10.6), Color(1, 1, .95), 8.0, 10.0, .3)
	story.sting(preload("res://assets/audio/sfx/light_relay.ogg"), -2)
	if DisplayServer.get_name() != "headless":
		var frame: Image = get_viewport().get_texture().get_image()
		var size: Vector2i = frame.get_size()
		# The three of them and the logo; the right edge, where he was standing, goes.
		var crop: Image = frame.get_region(Rect2i(int(size.x * .12), int(size.y * .1), int(size.x * .62), int(size.y * .7)))
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
	column.add_child(_text("Brent Fairweather · Chief Synergy Officer at SYNERGEX · 1st\nPosted 11:58 PM · Edited", 15, Color(.35, .37, .4)))
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
