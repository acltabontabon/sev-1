extends SceneTree
## Bake existing CC0 coworker motion onto the MakeHuman trial; no runtime retargeting.
const TARGET: String = "res://assets/characters/makehuman_trial/recruiter.glb"
const SOURCE: String = "res://assets/characters/quaternius/suit_male.fbx"
const MOTION: AnimationLibrary = preload("res://game/player/engineer_animations.res")
const OUTPUT: String = "res://assets/characters/makehuman_trial/"
const RATE: float = 30.0
var source_skeleton: Skeleton3D
var target_skeleton: Skeleton3D
var animator: AnimationPlayer
var source_rest: Dictionary = {}
var target_rest: Dictionary = {}
var change: Basis
var ratio: float
var order: Array[int] = []


func _initialize() -> void:
	var source: Node3D = load(SOURCE).instantiate()
	var target: Node3D = load(TARGET).instantiate()
	root.add_child(source)
	root.add_child(target)
	source_skeleton = source.find_child("Skeleton3D", true, false)
	target_skeleton = target.find_child("Skeleton3D", true, false)
	animator = source.find_child("AnimationPlayer", true, false)
	animator.add_animation_library("ual", MOTION)
	for index in source_skeleton.get_bone_count():
		source_rest[source_skeleton.get_bone_name(index)] = source_skeleton.get_bone_global_rest(index)
	for index in target_skeleton.get_bone_count():
		target_rest[target_skeleton.get_bone_name(index)] = target_skeleton.get_bone_global_rest(index)
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool: return _depth(a) < _depth(b))
	change = _frame(target_rest) * _frame(source_rest).inverse()
	ratio = (target_rest.Neck.origin - target_rest.Hips.origin).length() / (source_rest.Neck.origin - source_rest.Hips.origin).length()
	var native: AnimationLibrary = AnimationLibrary.new()
	var gestures: AnimationLibrary = AnimationLibrary.new()
	for name in animator.get_animation_list():
		if name == "RESET":
			continue
		var clip: Animation = _bake(name)
		var error: Error = gestures.add_animation(name.trim_prefix("ual/"), clip) if name.begins_with("ual/") else native.add_animation(name, clip)
		assert(error == OK)
	var error: Error = ResourceSaver.save(native, OUTPUT + "recruiter_native.res", ResourceSaver.FLAG_COMPRESS)
	if error == OK:
		error = ResourceSaver.save(gestures, OUTPUT + "recruiter_gestures.res", ResourceSaver.FLAG_COMPRESS)
	print("MakeHuman retarget: ", native.get_animation_list().size(), " native + ", gestures.get_animation_list().size(), " gestures; ", error_string(error))
	source.free()
	target.free()
	quit(0 if error == OK else 1)


func _frame(rest: Dictionary) -> Basis:
	var x: Vector3 = (rest["UpperArm.R"].origin - rest["UpperArm.L"].origin).normalized()
	var y: Vector3 = (rest.Neck.origin - rest.Hips.origin).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, z.cross(x).normalized(), z)


func _depth(index: int) -> int:
	var depth: int = 0
	while target_skeleton.get_bone_parent(index) >= 0:
		index = target_skeleton.get_bone_parent(index)
		depth += 1
	return depth


func _bake(name: String) -> Animation:
	var original: Animation = animator.get_animation(name)
	var clip: Animation = Animation.new()
	clip.length = original.length
	clip.loop_mode = original.loop_mode
	var tracks: Dictionary = {}
	for index: int in order:
		var bone: String = target_skeleton.get_bone_name(index)
		if not source_rest.has(_source_bone(bone)):
			continue
		var track: int = clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath("CharacterArmature/Skeleton3D:" + bone))
		tracks[bone] = track
	var root_track: int = clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(root_track, NodePath("CharacterArmature/Skeleton3D:Body"))
	var steps: int = maxi(1, int(ceil(clip.length * RATE)))
	var change_q: Quaternion = change.get_rotation_quaternion()
	for step in range(steps + 1):
		var time: float = minf(clip.length, float(step) / RATE)
		var posed: Dictionary = _sample(name, time)
		var global: Dictionary = {}
		for index: int in order:
			var bone: String = target_skeleton.get_bone_name(index)
			var parent: int = target_skeleton.get_bone_parent(index)
			var parent_global: Transform3D = global[target_skeleton.get_bone_name(parent)] if parent >= 0 else Transform3D.IDENTITY
			var local: Transform3D = target_skeleton.get_bone_rest(index)
			if tracks.has(bone):
				var source_bone: String = _source_bone(bone)
				var delta: Quaternion = posed[source_bone].basis.get_rotation_quaternion() * source_rest[source_bone].basis.get_rotation_quaternion().inverse()
				var world: Quaternion = change_q * delta * change_q.inverse() * target_rest[bone].basis.get_rotation_quaternion()
				local.basis = Basis((parent_global.basis.get_rotation_quaternion().inverse() * world).normalized())
				clip.rotation_track_insert_key(tracks[bone], time, local.basis.get_rotation_quaternion())
			if bone == "Body":
				var offset: Vector3 = change * (posed.Body.origin - source_rest.Body.origin) * ratio
				# Coworker roots and pacing are owned by coworkers.gd.
				offset.x = 0.0
				offset.z = 0.0
				local.origin += offset
				clip.position_track_insert_key(root_track, time, local.origin)
			global[bone] = parent_global * local
	return clip


func _sample(name: String, time: float) -> Dictionary:
	source_skeleton.reset_bone_poses()
	animator.play(name, 0.0)
	animator.seek(time, true)
	animator.advance(0.0)
	var out: Dictionary = {}
	for index in source_skeleton.get_bone_count():
		_compose(index, out)
	return out


func _compose(index: int, out: Dictionary) -> Transform3D:
	var bone: String = source_skeleton.get_bone_name(index)
	if out.has(bone):
		return out[bone]
	var parent: int = source_skeleton.get_bone_parent(index)
	var local: Transform3D = source_skeleton.get_bone_pose(index)
	out[bone] = (_compose(parent, out) * local) if parent >= 0 else local
	return out[bone]


func _source_bone(bone: String) -> String:
	return bone.replace("Hand.", "Fist.") if bone.begins_with("Hand.") else bone
