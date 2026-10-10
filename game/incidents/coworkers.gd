extends Node3D
## The rest of the Friday-night floor: CC0 office workers on their own overtime routines.
## Presentation only. They have no collision, take no damage and never block the fight.
## They cower while an enemy is engaged, and each has one line for when the engineer
## walks past. When a fight ends, the manager on the call takes the credit.

const ROOT: String = "res://assets/characters/quaternius/"
## The boss fight: the night shift charges in to help, and loses, loudly. Who goes, in
## what order, and how: "slice" (in half at the waist) or "fling" (across the vault).
## Each gets an epitaph about their worth for the casualty cam.
const CAVALRY: Array = [
	["Manager", "fling", "ESCALATED ONE LAST TIME\nSURVIVED BY 14 RECURRING INVITES"],
	["SRE", "slice", "FINALLY OFF CALL\nPAGER STILL RINGING"],
	["Designer", "fling", "DIED ON BRAND\nLAST FILE: final_FINAL_v4.fig"],
	["Intern", "slice", "TENURE: ONE DAY\nEXIT INTERVIEW: MONDAY, 9:00"],
	["Director", "slice", "VALUE ADDED: ONE (1) DECK\nREPLACED BY: A SLIDE"]]
const CAVALRY_ENTRY: Vector3 = Vector3(9.0, 0, -24.0)
const CAVALRY_SPEED: float = 5.0
const CAVALRY_FIRST: float = 4.5
const CAVALRY_GAP: float = 3.0
const STAMPS: Array[String] = ["OFFBOARDED", "RIGHT-SIZED", "LAID OFF", "RESTRUCTURED", "PIP'D"]
const GORE_LAYER: int = 1 << 7
## Headless suites skip the charge unless a test opts in.
static var cavalry_in_headless: bool = false
var cavalry_target: Node3D
var cavalry_clock: float = -1.0
## How far forward of the sofa's centre a sitter's hips rest.
const SOFA_FORWARD: float = .12
## Office-chair correction for the sitting clip (the engineer's SEATED_OFFSET).
const CHAIR_LIFT: float = .17
const CHAIR_FORWARD: float = .3
## How long a looping gesture (talking) runs before they settle back to idle.
const GESTURE_SECONDS: float = 3.5
const DIALOGUES: Script = preload("res://game/incidents/dialogues.gd")
const MOTION: AnimationLibrary = preload("res://game/player/engineer_animations.res")
## Routines: asleep / sit (seated), pace / carry (walk to `route` and back), fix (kneeling
## loop), stand (idle with an occasional `gesture`). Palette: shirt, pants, skin, hair.
const CAST: Array[Dictionary] = [
	{"name": "Sleeper", "body": "casual2_male.fbx", "routine": "asleep", "at": Vector3(-9.0, 0, .87), "facing": PI,
		"line": "zZz… LGTM… zZz", "palette": [Color(.42, .3, .5), Color(.12, .13, .2), Color(.82, .62, .48), Color(.2, .12, .08)]},
	{"name": "Bystander", "body": "casual3_male.fbx", "routine": "sit", "at": Vector3(-6.5, 0, -5.13), "facing": PI,
		"line": "Don't look at me. I'm on a different incident.", "palette": [Color(.55, .58, .52), Color(.2, .22, .14), Color(.46, .3, .2), Color(.08, .07, .06)]},
	{"name": "Manager", "body": "suit_male.fbx", "routine": "pace", "at": Vector3(6.2, 0, 7.0), "facing": PI, "route": Vector3(0, 0, -5.0),
		"line": "Yes, someone's on it. No, I don't know who.", "palette": [Color(.2, .22, .3), Color(.1, .1, .14), Color(.9, .72, .6), Color(.45, .36, .2)]},
	{"name": "Facilities", "body": "worker_male.fbx", "routine": "fix", "at": Vector3(21.6, 0, 10.6), "facing": -1.04,
		"line": "Ticket open since 2019. Today's the day. Probably.", "palette": [Color(.85, .45, .12), Color(.2, .3, .45), Color(.6, .4, .28), Color(.1, .08, .06)]},
	{"name": "Standup", "body": "casual3_male.fbx", "routine": "stand", "at": Vector3(-8.5, 0, -12.6), "facing": -.6, "gesture": "ual/talking",
		"line": "Yesterday: meetings. Today: meetings. Blockers: meetings.", "palette": [Color(.2, .55, .35), Color(.15, .14, .12), Color(.7, .5, .36), Color(.35, .2, .1)]},
	{"name": "Intern", "body": "casual2_male.fbx", "routine": "carry", "at": Vector3(-5.2, 0, 12.6), "facing": -PI * .5, "route": Vector3(-6.8, 0, 0),
		"line": "Is it normal to be on call on day one?", "palette": [Color(.95, .55, .2), Color(.18, .2, .3), Color(.55, .36, .25), Color(.12, .09, .07)]},
	{"name": "Remote", "body": "casual2_male.fbx", "routine": "sit", "at": Vector3(9.4, 0, 13.55), "facing": PI,
		"line": "I'm working from home. This is home now.", "palette": [Color(.85, .35, .55), Color(.25, .25, .3), Color(.88, .7, .58), Color(.55, .4, .18)]},
	{"name": "Microwave", "body": "casual3_male.fbx", "routine": "stand", "at": Vector3(24.4, 0, 8.8), "facing": PI * .5, "gesture": "Idle",
		"line": "It said one minute. That was forty minutes ago.", "palette": [Color(.3, .4, .7), Color(.1, .1, .1), Color(.5, .33, .22), Color(.05, .05, .05)]},
	{"name": "Recruiter", "body": "suit_male.fbx", "routine": "stand", "at": Vector3(8.0, 1.5, -9.4), "facing": PI * .15, "gesture": "Victory",
		"line": "We're like a family here. A family with KPIs.", "palette": [Color(.55, .12, .18), Color(.1, .1, .12), Color(.62, .44, .32), Color(.08, .06, .05)]},
	{"name": "SRE", "body": "casual_female.fbx", "routine": "sit", "at": Vector3(-6.5, 0, .87), "facing": PI,
		"line": "I'm not on call. I AM the call.", "palette": [Color(.18, .2, .24), Color(.12, .12, .16), Color(.66, .46, .33), Color(.06, .05, .05)]},
	{"name": "Director", "body": "suit_female.fbx", "routine": "pace", "at": Vector3(2.6, 0, -9.0), "facing": 0.0, "route": Vector3(0, 0, 6.5),
		"line": "Love the energy! Can we make it… more?", "palette": [Color(.75, .2, .32), Color(.12, .1, .14), Color(.86, .66, .52), Color(.62, .44, .2)]},
	{"name": "Designer", "body": "casual3_male.fbx", "routine": "stand", "at": Vector3(-11.1, 0, -2.9), "facing": -.9, "gesture": "ual/talking",
		"line": "My husband thinks I'm at the gym. Technically this is cardio.", "palette": [Color(.28, .62, .78), Color(.85, .8, .7), Color(.74, .55, .4), Color(.15, .1, .08)]},
]

var player: Node3D
var incident: Node
var people: Array[Dictionary] = []
var was_fighting: bool = false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("players") as Node3D
	for entry: Dictionary in CAST:
		var body: Node3D = load(ROOT + entry.body).instantiate()
		body.name = entry.name
		add_child(body)
		var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
		# The same rig as the engineer: his retargeted library (talking, phone, repairs).
		animator.add_animation_library("ual", MOTION)
		for clip in ["Idle", "Walk", "Walk_Carry", "PickUp"]:
			animator.get_animation("CharacterArmature|" + clip).loop_mode = Animation.LOOP_LINEAR
		dress(body, entry.palette)
		var line: Label3D = Label3D.new()
		line.text = entry.line
		line.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		line.font = preload("res://assets/fonts/inter_variable.ttf")
		line.font_size = 34
		line.pixel_size = .0045
		line.outline_size = 10
		line.modulate = Color(.92, .95, 1, 0)
		line.position.y = 2.25
		line.no_depth_test = true
		body.add_child(line)
		var voice: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		voice.name = "Voice"
		voice.bus = &"Voice"
		voice.unit_size = 6.0
		voice.position.y = 1.5
		body.add_child(voice)
		people.append({"entry": entry, "body": body, "animator": animator, "line": line,
			"said": false, "line_left": 0.0, "clock": 0.0, "pause": 0.0, "out": true, "gesture_left": 0.0, "gesture_hold": 0.0,
			"charging": false, "doom": 0.0, "fate": "", "cried": false, "dead": false, "pieces": [], "slot": 0})
	reset()


## Sitters sit on the furniture nearest their spot: an office chair (facing its desk)
## or the lounge sofa, never on the air in front of it.
func _seat(body: Node3D) -> void:
	if incident == null or not "room" in incident:
		return
	var best: Node3D = null
	for node in incident.room.find_children("*", "Node3D", true, false):
		var seat: Node3D = node
		var chair: bool = seat.scene_file_path.ends_with("chair.tscn")
		if not chair and not str(seat.name).begins_with("LoungeSofa"):
			continue
		var gap: float = Vector2(seat.global_position.x - body.position.x, seat.global_position.z - body.position.z).length()
		if gap < 1.6 and (best == null or gap < Vector2(best.global_position.x - body.position.x, best.global_position.z - body.position.z).length()):
			best = seat
	if best == null:
		return
	var turn: float = best.global_rotation.y
	if best.scene_file_path.ends_with("chair.tscn"):
		# Office chairs face their desk down -Z; bodies face +Z. The sitting clip was made
		# for a lower stool set further back (as for the engineer): lift onto the cushion
		# and forward off the backrest.
		body.rotation.y = turn + PI
		var ahead: Vector3 = Vector3(sin(body.rotation.y), 0, cos(body.rotation.y))
		body.position = best.global_position + Vector3.UP * CHAIR_LIFT + ahead * CHAIR_FORWARD
	else:
		body.rotation.y = turn
		body.position = best.global_position + Vector3(sin(turn), 0, cos(turn)) * SOFA_FORWARD


func person(name: String) -> Dictionary:
	for candidate: Dictionary in people:
		if candidate.entry.name == name:
			return candidate
	return {}


func reset() -> void:
	was_fighting = false
	cavalry_target = null
	cavalry_clock = -1.0
	for index in range(people.size()):
		var someone: Dictionary = people[index]
		var body: Node3D = someone.body
		for piece: Node in someone.pieces:
			if is_instance_valid(piece):
				piece.queue_free()
		# Stamps, slashes and spurts left on a fallen body go with the restart.
		ElementFx.clear_from(body)
		for child in body.get_children():
			if child is CPUParticles3D or child is GPUParticles3D:
				child.queue_free()
		someone.pieces = []
		someone.charging = false
		someone.dead = false
		someone.cried = false
		someone.fate = ""
		body.show()
		var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
		for bone in ["Abdomen", "UpperLeg.L", "UpperLeg.R"]:
			skeleton.set_bone_pose_scale(skeleton.find_bone(bone), Vector3.ONE)
		body.position = someone.entry.at
		body.scale = Vector3.ONE * .62
		body.rotation.y = someone.entry.facing
		if someone.entry.routine in ["sit", "asleep"]:
			_seat(body)
		someone.said = false
		someone.line_left = 0.0
		someone.clock = 0.0
		someone.pause = 0.0
		someone.out = true
		someone.gesture_left = 4.0 + index * 1.3
		(someone.line as Label3D).text = someone.entry.line
		(someone.line as Label3D).modulate.a = 0.0
		(someone.line as Label3D).visible = false
		_routine(someone, true)


func _process(delta: float) -> void:
	var fighting: bool = _fighting()
	for someone: Dictionary in people:
		someone.clock += delta
		var body: Node3D = someone.body
		var line: Label3D = someone.line
		if player != null and not someone.said and player.global_position.distance_to(body.global_position) < 3.6:
			someone.said = true
			someone.line_left = 3.2
		someone.line_left = maxf(0.0, someone.line_left - delta)
		line.modulate.a = minf(1.0, someone.line_left * 2.0)
		line.outline_modulate.a = line.modulate.a
		# Remarks stay out of cutscenes and kill cams.
		line.visible = line.modulate.a > .01 and (incident == null or incident.presentation == null or incident.presentation.beat_shot.is_empty())
		if someone.dead:
			continue
		if someone.charging:
			_charge(someone, delta)
			continue
		var routine: String = someone.entry.routine
		if fighting and routine != "asleep" and routine != "sit":
			_play(someone, "Defeat", .25, false)
			continue
		match routine:
			"pace", "carry":
				_walk(someone, delta)
			"stand":
				_gesture(someone, delta)
			_:
				# The kneeling repair is a one-shot clip: start it over rather than freeze, and
				# go back to it after a conversation.
				var repairing: bool = someone.animator.is_playing() and someone.animator.assigned_animation == "ual/fixing"
				if fighting != was_fighting or routine == "fix" and not repairing:
					_routine(someone, false)
	if cavalry_clock >= 0.0:
		cavalry_clock += delta
	if was_fighting and not fighting:
		_applaud()
	was_fighting = fighting


## The gate is open: the night shift sprints past the engineer down the corridor to take
## on The Variance themselves. They fight it (badly, loudly) until the engineer arrives.
func charge(target: Node3D) -> void:
	if cavalry_clock >= 0.0 or (DisplayServer.get_name() == "headless" and not cavalry_in_headless):
		return
	cavalry_target = target
	cavalry_clock = 0.0
	for index in range(CAVALRY.size()):
		var someone: Dictionary = person(CAVALRY[index][0])
		if someone.is_empty():
			continue
		var body: Node3D = someone.body
		someone.charging = true
		someone.fate = CAVALRY[index][1]
		someone.slot = index
		someone.cried = false
		someone.doom = randf_range(1.5, 3.5) + index * .7
		someone.line_left = 0.0
		body.position = CAVALRY_ENTRY + Vector3((index - 2) * .9, 0, index * 1.1)
		body.scale = Vector3.ONE * .62
		_play(someone, "ual/sprint", .1, true)
		_say(someone, "charge", "", .4 * index)


func cavalry_fallen() -> int:
	return people.filter(func(someone: Dictionary) -> bool: return someone.dead).size()


func cavalry_standing() -> int:
	return people.filter(func(someone: Dictionary) -> bool: return someone.charging).size()


## The next of them goes down (for the arrival cutscene); "" when nobody is left.
func fall_next() -> String:
	for entry: Array in CAVALRY:
		var someone: Dictionary = person(entry[0])
		if not someone.is_empty() and someone.charging:
			var centre: Vector3 = cavalry_target.global_position if is_instance_valid(cavalry_target) else someone.body.global_position
			_fall(someone, (someone.body.global_position - centre).normalized())
			return entry[0]
	return ""


## Everyone still standing goes down at once, without ceremony (skips and retries).
func fall_all_now() -> void:
	for entry: Array in CAVALRY:
		var someone: Dictionary = person(entry[0])
		if not someone.is_empty() and someone.charging:
			var centre: Vector3 = cavalry_target.global_position if is_instance_valid(cavalry_target) else someone.body.global_position
			var ring: float = someone.slot * TAU / CAVALRY.size() + .4
			someone.body.position = centre + Vector3(sin(ring), 0, cos(ring)) * 2.6
			_fall(someone, (someone.body.global_position - centre).normalized(), true)


func _say(someone: Dictionary, moment: String, shown: String, delay: float = 0.0, variant: int = -1) -> void:
	var talk: Dictionary = DIALOGUES.data().get("cavalry", {}).get(someone.entry.name, {})
	var said: Variant = talk.get(moment, shown)
	var text: String = str(said[variant % said.size()]) if said is Array else str(said)
	var suffix: String = moment if not said is Array else "%s_%d" % [moment, variant % said.size()]
	(someone.line as Label3D).text = text
	someone.line_left = 2.4
	var voice: AudioStreamPlayer3D = someone.body.get_node("Voice")
	var path: String = "res://assets/audio/voices/talk/cavalry_%s_%s.ogg" % [str(someone.entry.name).to_lower(), suffix]
	if DisplayServer.get_name() == "headless" or not ResourceLoader.exists(path):
		return
	voice.stream = load(path)
	if delay > 0.0:
		get_tree().create_timer(delay, false).timeout.connect(voice.play)
	else:
		voice.play()


func _charge(someone: Dictionary, delta: float) -> void:
	var body: Node3D = someone.body
	if not is_instance_valid(cavalry_target) or not cavalry_target.is_visible_in_tree():
		_play(someone, "Idle", .2, true)
		return
	var centre: Vector3 = cavalry_target.global_position
	var angle: float = someone.slot * TAU / CAVALRY.size() + .4
	var spot: Vector3 = centre + Vector3(sin(angle), 0, cos(angle)) * 2.6
	spot.y = body.position.y
	var step: Vector3 = spot - body.position
	step.y = 0
	var toward: Vector3 = centre - body.position
	if step.length() > .25:
		body.position += step.normalized() * minf(step.length(), CAVALRY_SPEED * delta)
		body.rotation.y = lerp_angle(body.rotation.y, atan2(step.x, step.z), 1.0 - exp(-10.0 * delta))
		_play(someone, "ual/sprint", .15, true)
		return
	body.rotation.y = lerp_angle(body.rotation.y, atan2(toward.x, toward.z), 1.0 - exp(-10.0 * delta))
	# In the ring: swing, get hit, howl about it, swing again.
	someone.doom -= delta
	if someone.doom <= 0.0:
		someone.doom = randf_range(2.6, 4.6)
		someone.animator.play("CharacterArmature|RecieveHit", .05)
		_say(someone, "pain", "", 0.0, randi())
		ElementFx.flash(body, body.global_position + Vector3.UP * 1.0, Color(1, .3, .2), 2.0, 3.0, .12)
		Blood.burst(incident if incident != null else self, body.global_position + Vector3.UP * 1.0, (body.global_position - centre).normalized() + Vector3.UP * .5, 14)
		var hit: AudioStreamPlayer3D = body.get_node("Voice")
		if DisplayServer.get_name() != "headless":
			var thud: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
			thud.stream = preload("res://assets/audio/sfx/heavy_impact.ogg")
			thud.bus = &"Effects"
			thud.unit_size = 5.0
			body.add_child(thud)
			thud.position = hit.position
			thud.play()
			thud.finished.connect(thud.queue_free)
	elif not someone.animator.is_playing() or someone.animator.assigned_animation == "ual/sprint":
		someone.animator.play("CharacterArmature|Punch", .1)


## One of the night shift meets The Variance.
func _fall(someone: Dictionary, away: Vector3, quiet: bool = false) -> void:
	var body: Node3D = someone.body
	someone.charging = false
	someone.dead = true
	away.y = 0
	away = away.normalized() if away.length() > .1 else Vector3.BACK
	var at: Vector3 = body.global_position + Vector3.UP * .9
	var level: Node = incident if incident != null else self
	var stamp: String = STAMPS[someone.slot % STAMPS.size()]
	if not quiet:
		ElementFx.glyphs(body, at + Vector3.UP * 1.3, Color(1, .3, .25), [stamp], 1.4, 0.0)
	if not quiet and incident != null and incident.get("presentation") != null:
		var who: String = DIALOGUES.data().trees.get(someone.entry.name, {}).get("who", str(someone.entry.name).to_upper())
		incident.presentation.casualty(body, who, CAVALRY[someone.slot][2], stamp)
	# Their last words are for the engineer: sorry, and it's all on you now.
	if not quiet:
		_say(someone, "sorry", "", .2)
	ElementFx.bolt(body, at - away.cross(Vector3.UP) * 1.2, at + away.cross(Vector3.UP) * 1.2, Color(1, .95, .8), .3, .1)
	if someone.fate == "slice":
		_slice(someone, away)
	else:
		# Thrown: knocked across the vault and left where they land.
		someone.animator.play("ual/hit_knockback", .05)
		var landing: Vector3 = body.position + away * 4.5
		var throw: Tween = body.create_tween()
		throw.tween_property(body, "position", landing + Vector3.UP * 1.4, .3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		throw.tween_property(body, "position", landing, .3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		throw.tween_callback(func() -> void: someone.animator.play("ual/death_ual", .1))
		Blood.burst(level, at, away + Vector3.UP * .6, 30)
		Blood.splat(level, body.global_position + away * 4.5, away, 1.2)


## In half at the waist: the legs stay standing a moment; the rest goes flying.
func _slice(someone: Dictionary, away: Vector3) -> void:
	var body: Node3D = someone.body
	var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
	var centre: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Torso")).origin
	someone.animator.pause()
	var upper: RigidBody3D = RigidBody3D.new()
	upper.top_level = true
	upper.collision_layer = GORE_LAYER
	upper.collision_mask = 1
	upper.mass = 2.0
	upper.angular_damp = 1.2
	var shape: CollisionShape3D = CollisionShape3D.new()
	var ball: SphereShape3D = SphereShape3D.new()
	ball.radius = .3
	shape.shape = ball
	upper.add_child(shape)
	add_child(upper)
	upper.global_position = centre
	var copy: Node3D = body.duplicate(0)
	copy.scale = Vector3.ONE
	for child in copy.get_children():
		if child is Label3D or child is AudioStreamPlayer3D:
			child.queue_free()
	upper.add_child(copy)
	copy.global_transform = body.global_transform
	var copy_skeleton: Skeleton3D = copy.find_child("Skeleton3D", true, false)
	var copy_player: AnimationPlayer = copy.find_child("AnimationPlayer", true, false)
	if copy_player != null:
		copy_player.active = false
	for index in skeleton.get_bone_count():
		copy_skeleton.set_bone_pose_position(index, skeleton.get_bone_pose_position(index))
		copy_skeleton.set_bone_pose_rotation(index, skeleton.get_bone_pose_rotation(index))
	# The legs keep the hips; the flying half keeps everything above them.
	skeleton.set_bone_pose_scale(skeleton.find_bone("Abdomen"), Vector3.ONE * .001)
	for bone in ["UpperLeg.L", "UpperLeg.R"]:
		copy_skeleton.set_bone_pose_scale(copy_skeleton.find_bone(bone), Vector3.ONE * .001)
	upper.linear_velocity = away * 4.0 + Vector3.UP * 6.5
	upper.angular_velocity = away.cross(Vector3.UP) * -8.0
	someone.pieces = [upper]
	var level: Node = incident if incident != null else self
	Blood.burst(level, centre, away + Vector3.UP * .8, 60)
	Blood.burst(level, centre, -away + Vector3.UP * .4, 24)
	Blood.spurt(upper, Vector3.ZERO, -Vector3.UP, .9)
	Blood.spurt(body, Vector3.UP * .9, Vector3.UP, .8)
	Blood.splat(level, centre + away * .7, away, 1.4)


## Someone always takes credit for the engineer's work.
func _applaud() -> void:
	var manager: Dictionary = person("Manager")
	if manager.is_empty() or manager.dead or manager.charging:
		return
	_play(manager, "Victory", .2, false)
	manager.pause = 2.6
	(manager.line as Label3D).text = "Great teamwork, everyone!"
	manager.line_left = 2.6


func _walk(someone: Dictionary, delta: float) -> void:
	var body: Node3D = someone.body
	var carrying: bool = someone.entry.routine == "carry"
	if someone.pause > 0:
		someone.pause -= delta
		if someone.pause <= 0:
			(someone.line as Label3D).text = someone.entry.line
		elif not (someone.animator as AnimationPlayer).current_animation.ends_with("Victory"):
			# The manager takes a call between laps: "Yes, someone's on it."
			_play(someone, "ual/phone" if someone.entry.name == "Manager" else "Idle", .3, true)
		return
	var goal: Vector3 = someone.entry.at + (someone.entry.route if someone.out else Vector3.ZERO)
	var step: Vector3 = goal - body.position
	step.y = 0
	if step.length() < .1:
		someone.out = not someone.out
		someone.pause = 1.6
		return
	body.position += step.normalized() * minf(step.length(), (.9 if carrying else 1.1) * delta)
	body.rotation.y = lerp_angle(body.rotation.y, atan2(step.x, step.z), 1.0 - exp(-6.0 * delta))
	_play(someone, "Walk_Carry" if carrying else "Walk", .25, true)


func _gesture(someone: Dictionary, delta: float) -> void:
	someone.gesture_left -= delta
	someone.gesture_hold = maxf(0.0, someone.gesture_hold - delta)
	var animator: AnimationPlayer = someone.animator
	if someone.gesture_left <= 0:
		someone.gesture_left = randf_range(5.0, 8.0)
		someone.gesture_hold = GESTURE_SECONDS
		_play(someone, someone.entry.gesture, .25, false)
	elif not animator.is_playing() or animator.current_animation.ends_with("Defeat") or someone.gesture_hold <= 0:
		# Looping gestures (talking) never finish on their own: they get a few seconds.
		_play(someone, "Idle", .3, true)


func _routine(someone: Dictionary, instant: bool) -> void:
	match someone.entry.routine:
		"asleep", "sit":
			var animator: AnimationPlayer = someone.animator
			animator.play("CharacterArmature|SitDown", 0.0 if instant else .3)
			animator.seek(animator.current_animation_length - .01, true)
			animator.pause()
			if someone.entry.routine == "asleep":
				# Face down on the desk. The paused clip leaves this override in place.
				var skeleton: Skeleton3D = (someone.body as Node3D).find_child("Skeleton3D", true, false)
				for bone in ["Neck", "Head"]:
					var index: int = skeleton.find_bone(bone)
					skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.RIGHT, .5) * skeleton.get_bone_pose_rotation(index))
		"fix":
			_play(someone, "ual/fixing", .3, true)
		_:
			_play(someone, "Idle", .3, true)


func _play(someone: Dictionary, clip: String, blend: float, loop: bool) -> void:
	var animator: AnimationPlayer = someone.animator
	var name: String = clip if clip.begins_with("ual/") else "CharacterArmature|" + clip
	# A finished one-shot clears current_animation; assigned_animation remembers it, so a
	# cower or gesture is not replayed every time it ends.
	if animator.assigned_animation == name and (animator.is_playing() or not loop):
		return
	animator.play(name, blend)


func _fighting() -> bool:
	if incident == null or not "battle_mode" in incident or incident.battle_mode == null:
		return false
	return incident.battle_mode.engaged


## Recolour a Quaternius office body: shirt, pants, skin, hair (shared with the hosts).
static func dress(body: Node3D, palette: Array) -> void:
	var names: Dictionary = {"Shirt": palette[0], "Pants": palette[1], "Skin": palette[2], "Hair": palette[3], "Face": Color(.04, .04, .05)}
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh as MeshInstance3D
		for surface in instance.mesh.get_surface_count():
			var source: Material = instance.mesh.surface_get_material(surface)
			if source == null or not names.has(source.resource_name):
				continue
			var material: StandardMaterial3D = (source as StandardMaterial3D).duplicate()
			material.albedo_color = names[source.resource_name]
			instance.set_surface_override_material(surface, material)
