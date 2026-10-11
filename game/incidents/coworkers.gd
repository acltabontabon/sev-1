extends Node3D
## The rest of the Friday-night floor: CC0 office workers on their own overtime routines.
## They have no collision, take no damage and never block the fight.
## Awake coworkers can occasionally patch up a nearby critically wounded engineer.
## They cower while an enemy is engaged, and each has one line for when the engineer
## walks past. When a fight ends, the manager on the call takes the credit.

signal emergency_aid(who: String, amount: int)

@export_range(0.0, 1.0) var aid_threshold: float = .25
@export var aid_health: int = 25
@export_range(1.0, 10.0) var aid_range: float = 6.0
@export_range(0.0, 1.0) var aid_chance: float = .45
@export_range(1.0, 10.0) var aid_check_seconds: float = 2.0
@export_range(1.0, 120.0) var aid_cooldown_seconds: float = 45.0
var aid_cooldown: float = 0.0
var aid_check_left: float = 0.0
var aid_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var aid_label: Label3D

const ROOT: String = "res://assets/characters/quaternius/"
## The boss fight: the night shift charges in to help, and loses, loudly. Who goes, in
## what order, to which of The Variance's moves (a corporate euphemism, done literally),
## and the epitaph and stamp for their casualty cam.
const CAVALRY: Array = [
	["Manager", "delayer", "ESCALATED ONE LAST TIME\nSURVIVED BY 14 RECURRING INVITES", "DELAYERED"],
	["SRE", "decommission", "FINALLY OFF CALL\nPAGER STILL RINGING", "DECOMMISSIONED"],
	["Designer", "pop", "DIED ON BRAND\nLAST FILE: final_FINAL_v4.fig", "MADE IT POP"],
	["Intern", "expose", "TENURE: ONE DAY\nCOMPENSATION: EXPOSURE", "OVEREXPOSED"],
	["Director", "downsize", "VALUE ADDED: ONE (1) DECK\nREPLACED BY: A SLIDE", "DOWNSIZED"]]
## How long each move winds up on its victim before it lands.
const WINDUP: Dictionary = {"delayer": 1.5, "decommission": 1.6, "pop": 1.7, "expose": 2.2, "downsize": 1.6}

const CAVALRY_ENTRY: Vector3 = Vector3(9.0, 0, -24.0)
const CAVALRY_SPEED: float = 5.0
const CAVALRY_FIRST: float = 4.5
const CAVALRY_GAP: float = 3.0
const GORE_LAYER: int = 1 << 7
## Headless suites skip the charge unless a test opts in.
static var cavalry_in_headless: bool = false
var cavalry_target: Node3D
var cavalry_clock: float = -1.0
## Where the monster stood when the gate opened (mid-vault), and whose scene the camera
## and the monster are on: the latest victim to square up, kept until the next one does.
var cavalry_home: Vector3
var spotlight: Dictionary = {}
## Set when the engineer's roar blows it back to the middle of the vault.
var blown_home: bool = false
## The Variance takes them one at a time, each where they make their stand: the manager
## squares up mid-vault, the SRE tries a rollback at the racks, the designer gives notes
## by the ledger, the intern bounces by the west racks, the director tries to leave.
## It leaps across the vault to each ("demon"); the wide shot watches side-on.
const STAGE: Dictionary = {
	"Manager": {"spot": Vector3(9.0, 0, -35.9), "demon": Vector3(9.0, 0, -38.0), "busy": "CharacterArmature|Punch"},
	"SRE": {"spot": Vector3(15.7, 0, -38.0), "demon": Vector3(13.3, 0, -37.4), "busy": "ual/interact", "face": Vector3(1, 0, 0)},
	"Designer": {"spot": Vector3(9.0, 0, -44.0), "demon": Vector3(9.6, 0, -41.7), "busy": "ual/talking"},
	"Intern": {"spot": Vector3(3.6, 0, -40.0), "demon": Vector3(6.0, 0, -38.6), "busy": "ual/jump"},
	"Director": {"spot": Vector3(11.0, 0, -31.4), "demon": Vector3(9.4, 0, -33.6), "busy": "ual/phone", "face": Vector3(0, 0, 1)},
}
## The rest run laps away from wherever it is: round the vault when it is mid-floor, round
## the far side when it is at a wall.
const PANIC_RADIUS: float = 4.3
const FLEE_RADIUS: float = 2.4
const FLEE_OFFSET: float = 3.0
## The intern is paid in exposure: flashes until they are overexposed.
const FLASH_EVERY: float = .26
const PANIC_SPEED: float = 4.2
## One voice at a time, in real time (casualty cams slow the game, not the audio): a line
## waits its turn or is dropped, and only last words cut anyone off.
const VOICE_GAP: float = .15
var voice_until: int = 0
var speaking: AudioStreamPlayer3D
## Bumped on restart and hush so a line queued for later never plays into the wrong scene.
var cue: int = 0
## The Kenney sofa's origin is its front-right corner, not its centre. Local anchor
## centres the sitter between the arms and lifts the clip onto the .23-high cushion.
## SitDown's hips finish behind the body root, so leave room before the backrest.
const SOFA_SEAT: Vector3 = Vector3(.56, .095, .06)
## Office-chair correction for the sitting clip (the engineer's SEATED_OFFSET).
const CHAIR_LIFT: float = .17
const CHAIR_FORWARD: float = .3
## How long a looping gesture (talking) runs before they settle back to idle.
const GESTURE_SECONDS: float = 3.5
const DIALOGUES: Script = preload("res://game/incidents/dialogues.gd")
const MOTION: AnimationLibrary = preload("res://game/player/engineer_animations.res")
const FEMALE_OUTFITS: Dictionary = {
	"casual_female.fbx": preload("res://assets/characters/office_outfits/casual_skirt.res"),
	"casual2_female.fbx": preload("res://assets/characters/office_outfits/blouse_skirt.res"),
	"suit_female.fbx": preload("res://assets/characters/office_outfits/suit_skirt.res"),
}
const DIRECTOR_OUTFIT: ArrayMesh = preload("res://assets/characters/office_outfits/director_skirt.res")
## Routines: asleep / sit (seated), pace / carry (walk to `route` and back), fix (kneeling
## loop), stand (idle with an occasional `gesture`). Palette: shirt, pants, skin, hair.
const CAST: Array[Dictionary] = [
	{"name": "Sleeper", "body": "casual2_male.fbx", "routine": "asleep", "at": Vector3(-9.0, 0, .87), "facing": PI,
		"line": "zZz… LGTM… zZz", "palette": [Color(.42, .3, .5), Color(.12, .13, .2), Color(.82, .62, .48), Color(.2, .12, .08)]},
	{"name": "Bystander", "body": "casual3_male.fbx", "routine": "sit", "at": Vector3(-6.5, 0, -5.13), "facing": PI,
		"line": "Don't look at me. I'm on a different incident.", "palette": [Color(.55, .58, .52), Color(.2, .22, .14), Color(.46, .3, .2), Color(.08, .07, .06)]},
	{"name": "Manager", "body": "suit_female.fbx", "routine": "pace", "at": Vector3(6.2, 0, 7.0), "facing": PI, "route": Vector3(0, 0, -5.0),
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
	{"name": "Recruiter", "body": "suit_male.fbx", "routine": "stand", "at": Vector3(7.0, 1.5, -4.9), "facing": PI * .15, "gesture": "Victory",
		"line": "We're like a family here. A family with KPIs.", "palette": [Color(.55, .12, .18), Color(.1, .1, .12), Color(.62, .44, .32), Color(.08, .06, .05)]},
	{"name": "SRE", "body": "casual2_female.fbx", "routine": "sit", "at": Vector3(-6.5, 0, .87), "facing": PI,
		"line": "I'm not on call. I AM the call.", "palette": [Color(.18, .2, .24), Color(.12, .12, .16), Color(.66, .46, .33), Color(.06, .05, .05)]},
	{"name": "Director", "body": "suit_female.fbx", "outfit": "low_cut", "routine": "pace", "at": Vector3(2.6, 0, -9.0), "facing": 0.0, "route": Vector3(0, 0, 6.5),
		"line": "Love the energy! Can we make it… more?", "palette": [Color(.75, .2, .32), Color(.12, .1, .14), Color(.86, .66, .52), Color(.62, .44, .2)]},
	{"name": "Designer", "body": "casual3_male.fbx", "routine": "stand", "at": Vector3(-11.1, 0, -2.9), "facing": -.9, "gesture": "ual/talking",
		"line": "My husband thinks I'm at the gym. Technically this is cardio.", "palette": [Color(.28, .62, .78), Color(.85, .8, .7), Color(.74, .55, .4), Color(.15, .1, .08)]},
]

var player: Node3D
var incident: Node
var people: Array[Dictionary] = []
var was_fighting: bool = false
## Frozen reveal poses, restored on skip, completion or restart.
var stare_poses: Array[Dictionary] = []


func _ready() -> void:
	aid_rng.randomize()
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
		dress(body, entry.palette, entry.get("outfit", "office"))
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
		if entry.routine == "asleep":
			var snoring: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
			snoring.name = "Snoring"
			snoring.set_script(preload("res://game/incidents/sleeper_snoring.gd"))
			body.add_child(snoring)
		people.append({"entry": entry, "body": body, "animator": animator, "line": line,
			"said": false, "line_left": 0.0, "clock": 0.0, "pause": 0.0, "out": true, "gesture_left": 0.0, "gesture_hold": 0.0,
			"charging": false, "doom": 0.0, "fate": "", "engaged": false, "lapping": false, "fighting_for": 0.0, "wind": -1.0, "orbit": 0.0, "spin": 1.0,
			"dead": false, "pieces": [], "slot": 0, "aid_hold": 0.0})
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
		body.global_position = best.to_global(SOFA_SEAT)


## The reveal turns heads, never the seated root: rotating a sitting body would sweep
## its legs through the desk and move its hips off the chair cushion.
func stare_at(target: Vector3) -> void:
	clear_stare()
	for someone: Dictionary in people:
		var body: Node3D = someone.body
		var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
		var toward: Vector3 = target - body.global_position
		var yaw: float = clampf(wrapf(atan2(toward.x, toward.z) - body.global_rotation.y, -PI, PI), -1.4, 1.4)
		for bone: String in ["Neck", "Head"]:
			var index: int = skeleton.find_bone(bone)
			if index < 0:
				continue
			var original: Quaternion = skeleton.get_bone_pose_rotation(index)
			stare_poses.append({"skeleton": skeleton, "index": index, "rotation": original})
			# Imported bones have their own axes. Convert world-up to the bone's
			# pre-pose frame, so the turn stays horizontal even in a sleeping pose.
			var parent: int = skeleton.get_bone_parent(index)
			var frame: Basis = skeleton.global_basis
			if parent >= 0:
				frame *= skeleton.get_bone_global_pose(parent).basis
			frame *= skeleton.get_bone_rest(index).basis
			var axis: Vector3 = (frame.inverse() * Vector3.UP).normalized()
			var share: float = .6 if bone == "Neck" else .4
			skeleton.set_bone_pose_rotation(index, Quaternion(axis, yaw * share) * original)


func clear_stare() -> void:
	for pose: Dictionary in stare_poses:
		if is_instance_valid(pose.skeleton):
			(pose.skeleton as Skeleton3D).set_bone_pose_rotation(pose.index, pose.rotation)
	stare_poses.clear()


func person(name: String) -> Dictionary:
	for candidate: Dictionary in people:
		if candidate.entry.name == name:
			return candidate
	return {}


func reset() -> void:
	clear_stare()
	aid_cooldown = 0.0
	aid_check_left = 0.0
	if is_instance_valid(aid_label):
		aid_label.queue_free()
	aid_label = null
	ElementFx.clear_from(self)
	was_fighting = false
	cavalry_target = null
	cavalry_clock = -1.0
	spotlight = {}
	blown_home = false
	hush()
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
		someone.engaged = false
		someone.lapping = false
		someone.fighting_for = 0.0
		someone.wind = -1.0
		someone.fate = ""
		body.get_node("Voice").pitch_scale = 1.0
		for mesh: Node in body.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).material_overlay = null
		body.rotation = Vector3.ZERO
		body.show()
		var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
		for bone in ["Abdomen", "UpperLeg.L", "UpperLeg.R"]:
			skeleton.set_bone_pose_scale(skeleton.find_bone(bone), Vector3.ONE)
		body.position = someone.entry.at
		body.scale = Vector3.ONE * .62
		body.rotation.y = someone.entry.facing
		if someone.entry.routine in ["sit", "asleep"]:
			_seat(body)
		someone.aid_hold = 0.0
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
	_emergency_aid(delta, fighting)
	for someone: Dictionary in people:
		someone.clock += delta
		var body: Node3D = someone.body
		var line: Label3D = someone.line
		if player != null and not someone.said and not someone.charging and not someone.dead and player.global_position.distance_to(body.global_position) < 3.6:
			someone.said = true
			someone.line_left = 3.2
		# Lines time out in real time, like the voices they caption (kill cams slow the game).
		someone.line_left = maxf(0.0, someone.line_left - delta / maxf(Engine.time_scale, .01))
		if someone.line_left <= 0.0:
			line.text = someone.entry.line
		line.modulate.a = minf(1.0, someone.line_left * 2.0)
		line.outline_modulate.a = line.modulate.a
		# Remarks stay out of cutscenes and kill cams.
		line.visible = line.modulate.a > .01 and (incident == null or incident.presentation == null or incident.presentation.beat_shot.is_empty())
		if someone.dead:
			continue
		if someone.charging:
			_charge(someone, delta)
			continue
		if someone.aid_hold > 0.0:
			someone.aid_hold = maxf(0.0, someone.aid_hold - delta)
			if someone.aid_hold > 0.0:
				continue
			_routine(someone, false)
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
		_panic_cries(delta)
	if was_fighting and not fighting:
		_applaud()
	was_fighting = fighting


## Checks are per interval, never per frame or per coworker. The shared cooldown
## prevents a crowd from supplying several heals on the same critical-health moment.
func _emergency_aid(delta: float, fighting: bool) -> void:
	if not is_instance_valid(player) or player.health <= 0 or player.narrative_hold or get_tree().paused:
		return
	if incident == null or incident.modal_pending() or (incident.presentation != null and not incident.presentation.beat_shot.is_empty()):
		return
	aid_cooldown = maxf(0.0, aid_cooldown - delta)
	if not fighting or player.health > player.max_health * aid_threshold or aid_cooldown > 0.0:
		aid_check_left = 0.0
		return
	aid_check_left -= delta
	if aid_check_left > 0.0:
		return
	aid_check_left = aid_check_seconds
	var candidates: Array[Dictionary] = []
	for someone: Dictionary in people:
		var body: Node3D = someone.body
		if someone.dead or someone.charging or someone.entry.routine == "asleep" or not body.is_visible_in_tree():
			continue
		if player.global_position.distance_to(body.global_position) > aid_range:
			continue
		# Layer 1 is the office's physical geometry; exclude the engineer's body.
		var sight: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			body.global_position + Vector3.UP * 1.2, player.global_position + Vector3.UP, 1, [player.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(sight).is_empty():
			continue
		candidates.append(someone)
	if candidates.is_empty() or aid_rng.randf() >= aid_chance:
		return
	var helper: Dictionary = candidates[aid_rng.randi_range(0, candidates.size() - 1)]
	var restored: int = mini(maxi(0, aid_health), player.max_health - player.health)
	if restored <= 0:
		return
	player.health += restored
	player.health_changed.emit(player.health)
	aid_cooldown = aid_cooldown_seconds
	helper.aid_hold = 1.4
	helper.line_left = 3.0
	helper.said = true
	(helper.line as Label3D).text = "I've got you. Benefits finally kicked in."
	var body: Node3D = helper.body
	var toward: Vector3 = player.global_position - body.global_position
	body.rotation.y = atan2(toward.x, toward.z)
	# Seated coworkers stay on their furniture; standing helpers reach out.
	if helper.entry.routine != "sit":
		_play(helper, "ual/interact", .15, false)
	_aid_feedback(str(helper.entry.name), restored, body.global_position)
	emergency_aid.emit(str(helper.entry.name), restored)


func _aid_feedback(who: String, amount: int, from: Vector3) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var green: Color = Color(.35, 1.0, .65)
	var at: Vector3 = player.global_position + Vector3.UP
	ElementFx.bolt(self, from + Vector3.UP * 1.2, at, green, .45, .025)
	ElementFx.motes(self, at, green, 14, 1.2, .8, .2, .07)
	if is_instance_valid(aid_label):
		aid_label.queue_free()
	aid_label = Label3D.new()
	aid_label.text = "+%d HP · %s" % [amount, who.to_upper()]
	aid_label.font = preload("res://assets/fonts/inter_variable.ttf")
	aid_label.font_size = 40
	aid_label.pixel_size = .004
	aid_label.outline_size = 10
	aid_label.modulate = green
	aid_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	aid_label.no_depth_test = true
	player.add_child(aid_label)
	aid_label.position = Vector3(0, 2.6, 0)
	var fade: Tween = aid_label.create_tween()
	fade.tween_interval(1.2)
	fade.tween_property(aid_label, "modulate:a", 0.0, .6)
	fade.tween_callback(aid_label.queue_free)


## The gate is open: the night shift sprints past the engineer down the corridor to take
## on The Variance themselves. It takes them on one at a time; the rest panic.
func charge(target: Node3D) -> void:
	if cavalry_clock >= 0.0 or (DisplayServer.get_name() == "headless" and not cavalry_in_headless):
		return
	cavalry_target = target
	cavalry_clock = 0.0
	cavalry_home = target.global_position
	spotlight = {}
	blown_home = false
	for index in range(CAVALRY.size()):
		var someone: Dictionary = person(CAVALRY[index][0])
		if someone.is_empty():
			continue
		var body: Node3D = someone.body
		someone.charging = true
		someone.fate = CAVALRY[index][1]
		someone.slot = index
		someone.engaged = false
		someone.lapping = false
		someone.fighting_for = 0.0
		someone.wind = -1.0
		someone.doom = 0.0
		someone.spin = 1.0 if index % 2 == 0 else -1.0
		someone.line_left = 0.0
		body.position = CAVALRY_ENTRY + Vector3((index - 2) * .9, 0, index * 1.1)
		body.scale = Vector3.ONE * .62
		_play(someone, "ual/sprint", .1, true)
		# Battle cries in turn, front of the pack first.
		_say(someone, "charge", "queue")


func cavalry_fallen() -> int:
	return people.filter(func(someone: Dictionary) -> bool: return someone.dead).size()


func cavalry_standing() -> int:
	return people.filter(func(someone: Dictionary) -> bool: return someone.charging).size()


## Who The Variance is busy with: the first of them still standing.
func victim() -> Dictionary:
	for entry: Array in CAVALRY:
		var someone: Dictionary = person(entry[0])
		if not someone.is_empty() and someone.charging:
			return someone
	return {}


## The victim has been up against it long enough to read, and nobody is talking.
func victim_ready() -> bool:
	var someone: Dictionary = victim()
	return not someone.is_empty() and someone.engaged and someone.fighting_for > .6 and someone.wind < 0.0 \
		and Time.get_ticks_msec() >= voice_until and landed()


## Where the monster should be: on the scene in the spotlight, or blown back mid-vault.
func demon_spot() -> Vector3:
	if blown_home or spotlight.is_empty():
		return cavalry_home
	var spot: Vector3 = STAGE[spotlight.entry.name].demon
	return Vector3(spot.x, cavalry_home.y, spot.z)


func landed() -> bool:
	return is_instance_valid(cavalry_target) and cavalry_target.global_position.distance_to(demon_spot()) < .05


## Where the wide shot watches the scene in the spotlight from, and what it looks at.
## Side-on to the pair, so it never stands between the lens and its victim, from the
## side nearer the middle of the vault (away from the walls). The intern's from low down.
func stage_camera() -> Vector3:
	if spotlight.is_empty():
		return Vector3(14.5, 3.4, -41.0)
	var stage: Dictionary = STAGE[spotlight.entry.name]
	var line: Vector3 = stage.spot - stage.demon
	var middle: Vector3 = (stage.spot + stage.demon) * .5
	var side: Vector3 = line.cross(Vector3.UP).normalized()
	if (middle + side).distance_to(cavalry_home) > (middle - side).distance_to(cavalry_home):
		side = -side
	var low: bool = false
	return middle + side * (6.5 if low else 5.6) + (side.cross(Vector3.UP) * .8) + Vector3.UP * (1.2 if low else 2.6)


func stage_focus() -> Vector3:
	if spotlight.is_empty() or not is_instance_valid(cavalry_target):
		return cavalry_home + Vector3.UP * 1.2
	var body: Node3D = spotlight.body
	var middle: Vector3 = (body.global_position + cavalry_target.global_position) * .5
	# Look up with whoever goes up (the intern's climb).
	return Vector3(middle.x, maxf(1.3, body.global_position.y + .9), middle.z)


## The Variance finishes the victim with their move: it calls it, it winds up on them,
## it lands (see _fall). Returns the move, or "" when nobody is up.
func execute_next() -> String:
	var someone: Dictionary = victim()
	if someone.is_empty() or someone.wind >= 0.0:
		return ""
	someone.wind = 0.0
	if incident != null and incident.get("presentation") != null:
		incident.presentation.boss_move(someone.fate)
	_wind(someone, 0.0)
	return someone.fate


func executing() -> bool:
	return people.any(func(someone: Dictionary) -> bool: return someone.charging and someone.wind >= 0.0)


## Cut everyone off and forget anything waiting to be said (the massacre takes the floor).
func hush() -> void:
	cue += 1
	voice_until = 0
	if is_instance_valid(speaking):
		speaking.stop()
	speaking = null
	for someone: Dictionary in people:
		if someone.charging:
			someone.line_left = 0.0


## The next of them goes down (for the arrival cutscene); "" when nobody is left.
func fall_next() -> String:
	var someone: Dictionary = victim()
	if someone.is_empty():
		return ""
	var centre: Vector3 = cavalry_target.global_position if is_instance_valid(cavalry_target) else someone.body.global_position
	_fall(someone, (someone.body.global_position - centre).normalized())
	return someone.entry.name


## Everyone still standing goes down at once, without ceremony (skips and retries).
func fall_all_now() -> void:
	hush()
	for entry: Array in CAVALRY:
		var someone: Dictionary = person(entry[0])
		if not someone.is_empty() and someone.charging:
			var centre: Vector3 = cavalry_target.global_position if is_instance_valid(cavalry_target) else someone.body.global_position
			var ring: float = someone.slot * TAU / CAVALRY.size() + .4
			someone.body.position = centre + Vector3(sin(ring), 0, cos(ring)) * 2.6
			_fall(someone, (someone.body.global_position - centre).normalized(), true)


## A cavalry line, if it gets the floor. "quiet": only if nobody is talking. "queue": after
## whoever is. "now": cuts them off (last words). Returns whether it will be said.
func _say(someone: Dictionary, moment: String, mode: String = "quiet", variant: int = -1, delay: float = 0.0) -> bool:
	var now: int = Time.get_ticks_msec()
	if mode == "quiet" and now < voice_until:
		return false
	var talk: Dictionary = DIALOGUES.data().get("cavalry", {}).get(someone.entry.name, {})
	var said: Variant = talk.get(moment, "")
	var pick: int = posmod(variant, said.size()) if said is Array else 0
	var text: String = str(said[pick]) if said is Array else str(said)
	var suffix: String = moment if not said is Array else "%s_%d" % [moment, pick]
	var path: String = "res://assets/audio/voices/talk/cavalry_%s_%s.ogg" % [str(someone.entry.name).to_lower(), suffix]
	var stream: AudioStream = load(path) if ResourceLoader.exists(path) else null
	# Timing comes from the recording even headless, so suites see the same turn-taking.
	var length: float = stream.get_length() if stream != null else 1.6
	if mode == "now":
		hush()
	var start: int = (maxi(now, voice_until) if mode == "queue" else now) + int(delay * 1000.0)
	voice_until = start + int((length + VOICE_GAP) * 1000.0)
	var turn: int = cue
	var speak: Callable = func() -> void:
		if turn != cue or (someone.dead and moment != "last"):
			return
		(someone.line as Label3D).text = text
		someone.line_left = length
		if DisplayServer.get_name() == "headless" or stream == null:
			return
		var voice: AudioStreamPlayer3D = someone.body.get_node("Voice")
		voice.stream = stream
		voice.play()
		speaking = voice
	if start > now:
		get_tree().create_timer(float(start - now) / 1000.0, true, false, true).timeout.connect(speak)
	else:
		speak.call()
	return true


func _charge(someone: Dictionary, delta: float) -> void:
	var body: Node3D = someone.body
	if not is_instance_valid(cavalry_target) or not cavalry_target.is_visible_in_tree():
		_play(someone, "Idle", .2, true)
		return
	var centre: Vector3 = cavalry_target.global_position
	var fighting: bool = is_same(someone, victim())
	var stage: Dictionary = STAGE.get(someone.entry.name, {})
	var spot: Vector3
	if body.position.z > cavalry_home.z + 6.5:
		# Through the vault door first, not the wall beside it.
		spot = Vector3(cavalry_home.x + (someone.slot - 2) * .4, 0, cavalry_home.z + 6.0)
	elif fighting:
		spot = stage.spot
	else:
		# Panic: laps away from where it is going, changing their mind about which way is
		# safer. The lap starts where they come in, never across the monster.
		var away: Vector3 = cavalry_home - demon_spot()
		away.y = 0
		var hub: Vector3 = cavalry_home if away.length() < .5 else cavalry_home + away.normalized() * FLEE_OFFSET
		var radius: float = PANIC_RADIUS if away.length() < .5 else FLEE_RADIUS
		if not someone.lapping:
			someone.lapping = true
			someone.orbit = atan2(body.position.x - hub.x, body.position.z - hub.z)
		someone.orbit += someone.spin * PANIC_SPEED / radius * delta
		someone.doom -= delta
		if someone.doom <= 0.0:
			someone.doom = randf_range(1.6, 3.4)
			someone.spin = -someone.spin if randf() < .5 else someone.spin
		var lap: float = radius + sin(someone.clock * .8 + someone.slot) * (.6 if radius == PANIC_RADIUS else .3)
		spot = hub + Vector3(sin(someone.orbit), 0, cos(someone.orbit)) * lap
	spot.y = body.position.y
	var step: Vector3 = spot - body.position
	step.y = 0
	var toward: Vector3 = centre - body.position
	if not fighting or step.length() > .25:
		var speed: float = CAVALRY_SPEED if fighting or step.length() > 1.0 else PANIC_SPEED
		body.position += step.normalized() * minf(step.length(), speed * delta) if step.length() > .01 else Vector3.ZERO
		if step.length() > .01:
			body.rotation.y = lerp_angle(body.rotation.y, atan2(step.x, step.z), 1.0 - exp(-10.0 * delta))
		_play(someone, "ual/sprint", .15, true)
		return
	var facing: Vector3 = stage.get("face", toward)
	body.rotation.y = lerp_angle(body.rotation.y, atan2(facing.x, facing.z), 1.0 - exp(-10.0 * delta))
	if not someone.engaged:
		someone.engaged = true
		someone.doom = .3
		spotlight = someone
	someone.fighting_for += delta
	if someone.wind >= 0.0:
		someone.wind += delta
		if someone.wind >= WINDUP[someone.fate]:
			_fall(someone, (body.position - centre).normalized())
		else:
			_wind(someone, delta)
		return
	# Up close: swing, get hit, scream about it (when nobody else is), swing again.
	someone.doom -= delta
	if someone.doom <= 0.0:
		someone.doom = randf_range(1.3, 2.1)
		someone.animator.play("CharacterArmature|RecieveHit", .05)
		_say(someone, "pain", "quiet", randi())
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
		# Busy with their thing while it comes for them.
		someone.animator.play(stage.get("busy", "CharacterArmature|Punch"), .1)


## Before the engineer walks in, whoever is running laps begs for help when there is a gap.
func _panic_cries(delta: float) -> void:
	if cavalry_standing() < 2 or Time.get_ticks_msec() < voice_until + 700 or randf() > delta * .8:
		return
	if incident != null and incident.get("presentation") != null and not incident.presentation.beat_shot.is_empty():
		return
	var runners: Array = people.filter(func(someone: Dictionary) -> bool: return someone.charging and not is_same(someone, victim()))
	if not runners.is_empty():
		_say(runners.pick_random(), "help", "quiet")


## The wind-up of the move on its victim, frame by frame (`delta` 0 on the first).
func _wind(someone: Dictionary, delta: float) -> void:
	var body: Node3D = someone.body
	var t: float = someone.wind
	var level: Node = incident if incident != null else self
	match someone.fate:
		"delayer":
			# A shadow grows under the manager; they look up at it, then it comes down.
			if delta == 0.0:
				ElementFx.sigil(level, body.global_position, Color(.9, .1, .1), 1.3, WINDUP.delayer, -.6)
				_play(someone, "ual/no", .2, true)
			if t - delta < WINDUP.delayer - .55 and t >= WINDUP.delayer - .55:
				_demon_swing()
		"decommission":
			# A red end-of-life scan sweeps up the SRE, twice.
			if delta == 0.0:
				_play(someone, "Defeat", .2, false)
			var sweep: float = fmod(t * 1.4, 1.0)
			if int(t * 20.0) != int((t - delta) * 20.0):
				var height: float = sweep * 1.3
				var side: Vector3 = body.global_basis.x.normalized() * .55
				ElementFx.bolt(level, body.global_position + Vector3.UP * height - side, body.global_position + Vector3.UP * height + side, Color(1, .15, .1), .08, .03)
			if t - delta < WINDUP.decommission - .4 and t >= WINDUP.decommission - .4:
				_demon_swing()
		"pop":
			# Feedback: the designer inflates, wobbling, until they are very much popping.
			var swell: float = 1.0 + .9 * smoothstep(0.0, WINDUP.pop, t)
			var wobble: float = sin(t * 26.0) * .07 * swell
			body.scale = Vector3(swell + wobble, swell - wobble, swell + wobble) * .62
			if delta == 0.0:
				_play(someone, "ual/hit_chest", .1, false)
		"expose":
			# Paparazzi: flash after flash, +EXPOSURE every time, and the intern loves it
			# (finally, visibility), whiter and whiter.
			if delta == 0.0:
				_play(someone, "ual/yes", .2, true)
			if int(t / FLASH_EVERY) != int((t - delta) / FLASH_EVERY) or delta == 0.0:
				var bulb: Vector3 = body.global_position + Vector3(randf_range(-1.6, 1.6), randf_range(.6, 2.2), randf_range(-1.6, 1.6))
				ElementFx.flash(level, bulb, Color(1, 1, .95), 5.0, 4.0, .08)
				ElementFx.glyphs(level, body.global_position + Vector3(randf_range(-.6, .6), 1.5, randf_range(-.6, .6)), Color(1, .95, .6), ["+EXPOSURE"], .7, .4)
				_shutter(body)
			_expose(body, smoothstep(0.0, WINDUP.expose, t) * .85, Color(1, 1, 1))
		"downsize":
			# A beam from the crown, and the director gets smaller, and smaller.
			if int(t * 8.0) != int((t - delta) * 8.0) and is_instance_valid(cavalry_target):
				ElementFx.bolt(level, cavalry_target.global_position + Vector3.UP * 3.2, body.global_position + Vector3.UP * .5 * body.scale.y / .62, Color(.5, 1, .7), .14, .06)
			body.scale = Vector3.ONE * .62 * lerpf(1.0, .22, smoothstep(0.0, WINDUP.downsize, t))
			if delta == 0.0:
				_play(someone, "Defeat", .2, false)


func _demon_swing() -> void:
	if is_instance_valid(cavalry_target) and cavalry_target.get("animator") != null:
		cavalry_target.animator.play(cavalry_target.clips.attack, .05)


## One of the night shift meets The Variance: the move lands, the casualty cam freezes on
## it, and they get their last words. `quiet` (skips, retries) leaves only the result.
func _fall(someone: Dictionary, away: Vector3, quiet: bool = false) -> void:
	var body: Node3D = someone.body
	someone.charging = false
	someone.dead = true
	someone.wind = -1.0
	away.y = 0
	away = away.normalized() if away.length() > .1 else Vector3.BACK
	var level: Node = incident if incident != null else self
	var floor_at: Vector3 = Vector3(body.global_position.x, 0.0, body.global_position.z)
	# What the casualty cam frames: [focus, height of the camera from it, distance].
	var frame: Array = [body.global_position + Vector3.UP * .9, -.35, 2.4]
	match someone.fate:
		"delayer":
			# Flattened: one fewer layer in the org chart.
			someone.animator.pause()
			body.scale = Vector3(1.7, .07, 1.7) * .62
			ElementFx.quake(level, floor_at, Color(.9, .12, .1), 2.2, .9)
			ElementFx.cracks(level, floor_at, Color(.8, .1, .08), 1.8)
			ElementFx.dust(level, floor_at, 1.6)
			Blood.burst(level, floor_at + Vector3.UP * .1, Vector3.UP, 40)
			Blood.splat(level, floor_at + Vector3.UP * .02, Vector3.UP, 1.8)
			frame = [floor_at + Vector3.UP * .1, 1.7, 1.5]
		"decommission":
			_slice(someone, away)
			# The pager does not know they are off call.
			var beeps: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
			beeps.stream = preload("res://assets/audio/sfx/chat_ping.ogg")
			beeps.bus = &"Effects"
			beeps.pitch_scale = 1.6
			(someone.pieces[0] as Node3D).add_child(beeps)
			if DisplayServer.get_name() != "headless" and not quiet:
				for ring in range(6):
					get_tree().create_timer(1.8 + ring * .7, false).timeout.connect(func() -> void:
						if is_instance_valid(beeps):
							beeps.play())
		"pop":
			# Frozen at full inflation for the cam; then the note lands.
			someone.animator.pause()
			frame = [body.global_position + Vector3.UP * 1.1, -.2, 3.0]
			if quiet:
				_pop(someone)
			else:
				get_tree().create_timer(.35, false).timeout.connect(_pop.bind(someone))
		"expose":
			# One flash too many: everything above the belt goes to ash. The legs stay,
			# smoking, and they still have last words.
			var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
			skeleton.set_bone_pose_scale(skeleton.find_bone("Abdomen"), Vector3.ONE * .001)
			someone.animator.pause()
			_expose(body, .7, Color(.08, .07, .06))
			var waist: Vector3 = body.global_position + Vector3.UP * .55
			ElementFx.flash(level, waist + Vector3.UP * .6, Color(1, 1, .95), 9.0, 9.0, .3)
			ElementFx.shockwave(level, floor_at + Vector3.UP * .05, Color(1, 1, .9), 3.0, .4)
			ElementFx.motes(level, waist + Vector3.UP * .4, Color(.35, .33, .3), 50, 2.0, 2.2, -1.2, .14)
			ElementFx.motes(level, waist, Color(.12, .11, .1), 24, .6, 4.0, -.8, .3)
			Blood.spurt(body, Vector3.UP * .55, Vector3.UP, 1.0)
			Blood.splat(level, floor_at + Vector3.UP * .02, Vector3.UP, 1.1)
			_shutter(body)
			frame = [floor_at + Vector3.UP * .45, .15, 1.6]
		"downsize":
			# Shrunk to a rounding error. Their last words come out squeaky; then a stomp.
			someone.animator.pause()
			body.scale = Vector3.ONE * .62 * .22
			body.get_node("Voice").pitch_scale = 1.8
			frame = [floor_at + Vector3.UP * .2, .25, 1.3]
			if quiet:
				_stomp(someone)
			else:
				get_tree().create_timer(2.2, false).timeout.connect(_stomp.bind(someone))
	if quiet:
		return
	var at: Vector3 = body.global_position + Vector3.UP * .9
	var stamp: String = CAVALRY[someone.slot][3]
	ElementFx.bolt(body, at - away.cross(Vector3.UP) * 1.2, at + away.cross(Vector3.UP) * 1.2, Color(1, .95, .8), .3, .1)
	if incident != null and incident.get("presentation") != null:
		var who: String = DIALOGUES.data().trees.get(someone.entry.name, {}).get("who", str(someone.entry.name).to_upper())
		incident.presentation.casualty(body, who, CAVALRY[someone.slot][2], stamp, frame)
	# Last words: denial, branding and paperwork to the very end.
	_say(someone, "last", "now", -1, .2)


## Wash a body towards `colour` (overexposed white; charred), `amount` 0 to 1.
func _expose(body: Node3D, amount: float, colour: Color) -> void:
	for mesh: Node in body.find_children("*", "MeshInstance3D", true, false):
		var wash: StandardMaterial3D = (mesh as MeshInstance3D).material_overlay as StandardMaterial3D
		if wash == null:
			wash = StandardMaterial3D.new()
			wash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			(mesh as MeshInstance3D).material_overlay = wash
		wash.albedo_color = Color(colour, amount)


func _shutter(body: Node3D) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var click: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	click.stream = preload("res://assets/audio/sfx/light_relay.ogg")
	click.bus = &"Effects"
	click.pitch_scale = randf_range(1.3, 1.6)
	click.unit_size = 8.0
	body.add_child(click)
	click.play()
	click.finished.connect(click.queue_free)


## The designer's note lands: all of them, everywhere, in brand colours.
func _pop(someone: Dictionary) -> void:
	var body: Node3D = someone.body
	if not someone.dead or not body.visible:
		return
	var level: Node = incident if incident != null else self
	var at: Vector3 = body.global_position + Vector3.UP * 1.0
	body.hide()
	Blood.burst(level, at, Vector3.UP, 90)
	for side in range(5):
		var out: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, side * TAU / 5.0)
		Blood.burst(level, at, out + Vector3.UP * .3, 24)
		Blood.splat(level, Vector3(at.x, .02, at.z) + out * randf_range(1.0, 2.6), Vector3.UP, randf_range(.8, 1.4))
	for colour: Color in [Color(1, .3, .7), Color(.3, .8, 1), Color(1, .85, .2)]:
		ElementFx.shards(level, at, colour, 16, 6.0, 1.4)
	ElementFx.shockwave(level, at, Color(1, .4, .6), 2.4, .35)
	ElementFx.flash(level, at, Color(1, .5, .7), 4.0, 6.0, .2)


## The demon steps on what is left of the director.
func _stomp(someone: Dictionary) -> void:
	var body: Node3D = someone.body
	if not someone.dead or not body.visible or body.scale.y < .05:
		return
	_demon_swing()
	var level: Node = incident if incident != null else self
	var floor_at: Vector3 = Vector3(body.global_position.x, 0.0, body.global_position.z)
	body.scale = Vector3(.3, .01, .3)
	Blood.burst(level, floor_at + Vector3.UP * .05, Vector3.UP, 26)
	Blood.splat(level, floor_at + Vector3.UP * .02, Vector3.UP, .9)
	ElementFx.dust(level, floor_at, .8)


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
static func dress(body: Node3D, palette: Array, outfit: String = "office") -> void:
	var names: Dictionary = {"Shirt": palette[0], "Pants": palette[1], "Skirt": palette[1], "OutfitSkin": palette[2], "Skin": palette[2], "Hair": palette[3], "Face": Color(.04, .04, .05)}
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh as MeshInstance3D
		var model: String = body.scene_file_path.get_file()
		if outfit != "athletic" and FEMALE_OUTFITS.has(model) and instance.skin != null:
			for surface in range(instance.mesh.get_surface_count()):
				instance.set_surface_override_material(surface, null)
			instance.mesh = DIRECTOR_OUTFIT if outfit == "low_cut" else FEMALE_OUTFITS[model]
		for surface in instance.mesh.get_surface_count():
			var source: Material = instance.mesh.surface_get_material(surface)
			if source == null or not names.has(source.resource_name):
				continue
			var material: StandardMaterial3D = (source as StandardMaterial3D).duplicate()
			material.albedo_color = names[source.resource_name]
			instance.set_surface_override_material(surface, material)
