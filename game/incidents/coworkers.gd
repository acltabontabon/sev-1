extends Node3D
## The rest of the Friday-night floor: CC0 office workers on their own overtime routines.
## Presentation only. They have no collision, take no damage and never block the fight.
## They cower while an enemy is engaged, and each has one line for when the engineer
## walks past. When a fight ends, the manager on the call takes the credit.

const ROOT: String = "res://assets/characters/quaternius/"
## Routines: asleep / sit (seated), pace / carry (walk to `route` and back), fix (PickUp
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
	{"name": "Standup", "body": "casual3_male.fbx", "routine": "stand", "at": Vector3(-8.5, 0, -12.6), "facing": -.6, "gesture": "Shoot_OneHanded",
		"line": "Yesterday: meetings. Today: meetings. Blockers: meetings.", "palette": [Color(.2, .55, .35), Color(.15, .14, .12), Color(.7, .5, .36), Color(.35, .2, .1)]},
	{"name": "Intern", "body": "casual2_male.fbx", "routine": "carry", "at": Vector3(-5.2, 0, 12.6), "facing": -PI * .5, "route": Vector3(-6.8, 0, 0),
		"line": "Is it normal to be on call on day one?", "palette": [Color(.95, .55, .2), Color(.18, .2, .3), Color(.55, .36, .25), Color(.12, .09, .07)]},
	{"name": "Remote", "body": "casual2_male.fbx", "routine": "sit", "at": Vector3(9.4, 0, 13.55), "facing": PI,
		"line": "I'm working from home. This is home now.", "palette": [Color(.85, .35, .55), Color(.25, .25, .3), Color(.88, .7, .58), Color(.55, .4, .18)]},
	{"name": "Microwave", "body": "casual3_male.fbx", "routine": "stand", "at": Vector3(24.4, 0, 8.8), "facing": PI * .5, "gesture": "Idle",
		"line": "It said one minute. That was forty minutes ago.", "palette": [Color(.3, .4, .7), Color(.1, .1, .1), Color(.5, .33, .22), Color(.05, .05, .05)]},
	{"name": "Recruiter", "body": "suit_male.fbx", "routine": "stand", "at": Vector3(8.0, 1.5, -9.4), "facing": PI * .15, "gesture": "Victory",
		"line": "We're like a family here. A family with KPIs.", "palette": [Color(.55, .12, .18), Color(.1, .1, .12), Color(.62, .44, .32), Color(.08, .06, .05)]},
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
		people.append({"entry": entry, "body": body, "animator": animator, "line": line,
			"said": false, "line_left": 0.0, "clock": 0.0, "pause": 0.0, "out": true, "gesture_left": 0.0})
	reset()


func person(name: String) -> Dictionary:
	for candidate: Dictionary in people:
		if candidate.entry.name == name:
			return candidate
	return {}


func reset() -> void:
	was_fighting = false
	for index in range(people.size()):
		var someone: Dictionary = people[index]
		var body: Node3D = someone.body
		body.position = someone.entry.at
		body.scale = Vector3.ONE * .62
		body.rotation.y = someone.entry.facing
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
		line.visible = line.modulate.a > .01
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
				if fighting != was_fighting:
					_routine(someone, false)
	if was_fighting and not fighting:
		_applaud()
	was_fighting = fighting


## Someone always takes credit for the engineer's work.
func _applaud() -> void:
	var manager: Dictionary = person("Manager")
	if manager.is_empty():
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
			_play(someone, "Idle", .3, true)
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
	var animator: AnimationPlayer = someone.animator
	if someone.gesture_left <= 0:
		someone.gesture_left = randf_range(5.0, 8.0)
		_play(someone, someone.entry.gesture, .25, false)
	elif not animator.is_playing() or animator.current_animation.ends_with("Defeat"):
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
			_play(someone, "PickUp", .3, true)
		_:
			_play(someone, "Idle", .3, true)


func _play(someone: Dictionary, clip: String, blend: float, loop: bool) -> void:
	var animator: AnimationPlayer = someone.animator
	var name: String = "CharacterArmature|" + clip
	if animator.current_animation == name and (animator.is_playing() or not loop):
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
