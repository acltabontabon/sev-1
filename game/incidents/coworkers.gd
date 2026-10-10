extends Node3D
## The rest of the Friday-night floor: CC0 office workers on their own overtime routines.
## Presentation only. They have no collision, take no damage and never block the fight.
## They cower while an enemy is engaged nearby, and each has one line for when the
## engineer walks past. When a fight ends, the manager on the call takes the credit.

const ROOT: String = "res://assets/characters/quaternius/"
## name, body, routine, position, facing, line, palette (shirt, pants, skin, hair)
const CAST: Array = [
	["Sleeper", "casual2_male.fbx", "asleep", Vector3(-9.0, 0, .87), PI,
		"zZz… LGTM… zZz", [Color(.42, .3, .5), Color(.12, .13, .2), Color(.82, .62, .48), Color(.2, .12, .08)]],
	["Bystander", "casual3_male.fbx", "desk", Vector3(-6.5, 0, -5.13), PI,
		"Don't look at me. I'm on a different incident.", [Color(.55, .58, .52), Color(.2, .22, .14), Color(.46, .3, .2), Color(.08, .07, .06)]],
	["Manager", "suit_male.fbx", "pace", Vector3(6.2, 0, 7.0), PI,
		"Yes, someone's on it. No, I don't know who.", [Color(.2, .22, .3), Color(.1, .1, .14), Color(.9, .72, .6), Color(.45, .36, .2)]],
	["Facilities", "worker_male.fbx", "fix", Vector3(21.6, 0, 10.6), -1.04,
		"Ticket open since 2019. Today's the day. Probably.", [Color(.85, .45, .12), Color(.2, .3, .45), Color(.6, .4, .28), Color(.1, .08, .06)]],
]
const PACE: Vector3 = Vector3(0, 0, -5.0)

var player: Node3D
var incident: Node
var people: Array[Dictionary] = []
var was_fighting: bool = false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("players") as Node3D
	for entry: Array in CAST:
		var body: Node3D = load(ROOT + entry[1]).instantiate()
		body.name = entry[0]
		add_child(body)
		var animator: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
		for clip in ["Idle", "Walk"]:
			animator.get_animation("CharacterArmature|" + clip).loop_mode = Animation.LOOP_LINEAR
		_dress(body, entry[6])
		var line: Label3D = Label3D.new()
		line.text = entry[5]
		line.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		line.font = preload("res://assets/fonts/inter_variable.ttf")
		line.font_size = 34
		line.pixel_size = .0045
		line.outline_size = 10
		line.modulate = Color(.92, .95, 1, 0)
		line.position.y = 2.25
		line.no_depth_test = true
		body.add_child(line)
		people.append({"body": body, "animator": animator, "routine": entry[2], "home": entry[3],
			"facing": entry[4], "line": line, "said": false, "line_left": 0.0, "clock": 0.0, "pause": 0.0, "out": true})
	reset()


func reset() -> void:
	was_fighting = false
	for person: Dictionary in people:
		var body: Node3D = person.body
		body.position = person.home
		body.scale = Vector3.ONE * .62
		body.rotation.y = person.facing
		person.said = false
		person.line_left = 0.0
		person.clock = 0.0
		person.pause = 0.0
		person.out = true
		(person.line as Label3D).modulate.a = 0.0
		(person.line as Label3D).visible = false
		_routine(person, true)


func _process(delta: float) -> void:
	var fighting: bool = _fighting()
	for person: Dictionary in people:
		person.clock += delta
		var body: Node3D = person.body
		var line: Label3D = person.line
		if player != null and not person.said and player.global_position.distance_to(body.global_position) < 3.6:
			person.said = true
			person.line_left = 3.2
		person.line_left = maxf(0.0, person.line_left - delta)
		line.modulate.a = minf(1.0, person.line_left * 2.0)
		line.outline_modulate.a = line.modulate.a
		line.visible = line.modulate.a > .01
		if fighting and person.routine != "asleep":
			_play(person, "Defeat", .25, false)
			continue
		if person.routine == "pace":
			_pace(person, delta)
		elif fighting != was_fighting:
			_routine(person, false)
	if was_fighting and not fighting:
		_applaud()
	was_fighting = fighting


## Someone always takes credit for the engineer's work.
func _applaud() -> void:
	var manager: Dictionary = people[2]
	_play(manager, "Victory", .2, false)
	manager.pause = 2.6
	(manager.line as Label3D).text = "Great teamwork, everyone!"
	manager.line_left = 2.6


func _pace(person: Dictionary, delta: float) -> void:
	var body: Node3D = person.body
	if person.pause > 0:
		person.pause -= delta
		if person.pause <= 0:
			(person.line as Label3D).text = CAST[2][5]
		else:
			if (person.animator as AnimationPlayer).current_animation != "CharacterArmature|Victory":
				_play(person, "Idle", .3, true)
			return
	var goal: Vector3 = person.home + (PACE if person.out else Vector3.ZERO)
	var step: Vector3 = goal - body.position
	if step.length() < .1:
		person.out = not person.out
		person.pause = 1.6
		return
	body.position += step.normalized() * minf(step.length(), 1.1 * delta)
	body.rotation.y = lerp_angle(body.rotation.y, atan2(step.x, step.z), 1.0 - exp(-6.0 * delta))
	_play(person, "Walk", .25, true)


func _routine(person: Dictionary, instant: bool) -> void:
	match person.routine:
		"asleep", "desk":
			var animator: AnimationPlayer = person.animator
			animator.play("CharacterArmature|SitDown", 0.0 if instant else .3)
			animator.seek(animator.current_animation_length - .01, true)
			animator.pause()
			if person.routine == "asleep":
				# Face down on the desk. The paused clip leaves this override in place.
				var skeleton: Skeleton3D = (person.body as Node3D).find_child("Skeleton3D", true, false)
				for bone in ["Neck", "Head"]:
					var index: int = skeleton.find_bone(bone)
					skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.RIGHT, .5) * skeleton.get_bone_pose_rotation(index))
		"fix":
			_play(person, "PickUp", .3, true)
		_:
			_play(person, "Idle", .3, true)


func _play(person: Dictionary, clip: String, blend: float, loop: bool) -> void:
	var animator: AnimationPlayer = person.animator
	var name: String = "CharacterArmature|" + clip
	if animator.current_animation == name and animator.is_playing():
		return
	if not loop and animator.current_animation == name:
		return
	animator.play(name, blend)
	if loop:
		animator.get_animation(name).loop_mode = Animation.LOOP_LINEAR


func _fighting() -> bool:
	if incident == null or not "battle_mode" in incident or incident.battle_mode == null:
		return false
	return incident.battle_mode.engaged


func _dress(body: Node3D, palette: Array) -> void:
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
