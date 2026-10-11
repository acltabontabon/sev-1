extends SceneTree
## Bakes the rigged engineer's animation library. Run after reimporting the Quaternius FBX:
##   sh tools/godot.sh --headless --path . --script tools/build_engineer_rig.gd
## Office clips (sit, stand, hit, victory) come with the body. Action clips (run, roll,
## death, sword idles) come from the CC0 Knight pack: its skeleton shares bone names, so
## each rotation key is re-expressed relative to the body's rest pose and each position key
## is scaled to the shorter body. Output is one deterministic AnimationLibrary resource.

const BODY: String = "res://assets/characters/quaternius/casual_male.fbx"
const ACTION: String = "res://assets/characters/quaternius/knight_animations.fbx"
const OUTPUT: String = "res://game/player/engineer_animations.res"
const NATIVE: Dictionary = {
	"Idle": "idle_casual", "Walk": "walk", "SitDown": "sit_down", "StandUp": "stand_up",
	"Victory": "victory", "RecieveHit": "hit", "Defeat": "defeat", "Punch": "punch",
}
const RETARGETED: Dictionary = {
	"Idle_swordRight": "idle", "Run_swordRight": "run", "Run": "run_free", "Roll": "roll",
	"Death": "death", "Jump": "jump", "swordAttackJump": "jump_attack", "Run_swordAttack": "run_attack",
}
## Quaternius' CC0 Universal Animation Libraries (assets/characters/animations): different
## rigs, retargeted by world-space rotation relative to each rig's T-pose (see _retarget).
const UAL: Array = [
	["res://assets/characters/animations/ual2_standard.glb", {
		"pelvis": "Hips", "spine_01": "Abdomen", "spine_03": "Torso", "neck_01": "Neck", "Head": "Head",
		"clavicle_l": "Shoulder.L", "upperarm_l": "UpperArm.L", "lowerarm_l": "LowerArm.L", "hand_l": "Fist.L",
		"clavicle_r": "Shoulder.R", "upperarm_r": "UpperArm.R", "lowerarm_r": "LowerArm.R", "hand_r": "Fist.R",
		"thigh_l": "UpperLeg.L", "calf_l": "LowerLeg.L", "foot_l": "Foot.L",
		"thigh_r": "UpperLeg.R", "calf_r": "LowerLeg.R", "foot_r": "Foot.R"}, {
		"Sword_Regular_A": "sword_a", "Sword_Regular_A_Rec": "sword_a_rec", "Sword_Regular_B": "sword_b",
		"Sword_Regular_B_Rec": "sword_b_rec", "Sword_Regular_C": "sword_c", "Sword_Regular_Combo": "sword_combo",
		"Sword_Dash_RM": "sword_dash", "Sword_Block": "sword_block", "Melee_Hook": "melee_hook",
		"Idle_FoldArms_Loop": "fold_arms", "Hit_Knockback": "hit_knockback", "Idle_TalkingPhone_Loop": "phone",
		"Zombie_Walk_Fwd_Loop": "zombie_walk", "Zombie_Idle_Loop": "zombie_idle", "Zombie_Scratch": "zombie_scratch",
		"Idle_No_Loop": "no", "Yes": "yes"}],
	["res://assets/characters/animations/ual1_standard.glb", {
		"DEF-hips": "Hips", "DEF-spine.001": "Abdomen", "DEF-spine.003": "Torso", "DEF-neck": "Neck", "DEF-head": "Head",
		"DEF-shoulder.L": "Shoulder.L", "DEF-upper_arm.L": "UpperArm.L", "DEF-forearm.L": "LowerArm.L", "DEF-hand.L": "Fist.L",
		"DEF-shoulder.R": "Shoulder.R", "DEF-upper_arm.R": "UpperArm.R", "DEF-forearm.R": "LowerArm.R", "DEF-hand.R": "Fist.R",
		"DEF-thigh.L": "UpperLeg.L", "DEF-shin.L": "LowerLeg.L", "DEF-foot.L": "Foot.L",
		"DEF-thigh.R": "UpperLeg.R", "DEF-shin.R": "LowerLeg.R", "DEF-foot.R": "Foot.R"}, {
		"Sword_Attack": "sword_attack", "Sword_Idle": "sword_idle", "Jog_Fwd_Loop": "jog", "Sprint_Loop": "sprint",
		"Roll": "roll_ual", "Death01": "death_ual", "Hit_Chest": "hit_chest", "Idle_Talking_Loop": "talking",
		"Sitting_Talking_Loop": "sitting_talking", "Fixing_Kneeling": "fixing", "Interact": "interact",
		"Walk_Formal_Loop": "walk_formal"}],
]
const UAL_LOOPING: Array[String] = ["fold_arms", "phone", "zombie_walk", "zombie_idle", "no", "sword_idle", "jog", "sprint", "talking", "sitting_talking", "walk_formal"]
const UAL_IN_PLACE: Array[String] = ["sword_dash", "jog", "sprint", "roll_ual", "zombie_walk", "walk_formal",
	"sword_a", "sword_a_rec", "sword_b", "sword_b_rec", "sword_c", "sword_combo", "melee_hook", "sword_attack", "hit_knockback", "death_ual", "kevin_2h"]
const SAMPLE_RATE: float = 30.0
## Full-body lunges read as face-plants on the big-headed body: attacks keep their arms and
## torso but only part of the hips' rotation and drop, and most of the spine's.
const DAMPED: Array[String] = ["sword_a", "sword_a_rec", "sword_b", "sword_b_rec", "sword_c", "sword_combo", "melee_hook", "sword_attack", "sword_dash"]
const DAMPING: Dictionary = {"Hips": .35, "Abdomen": .75, "Torso": .75, "Body": .4}
const LOOPING: Array[String] = ["idle", "idle_casual", "walk", "run", "run_free"]
## Clips that must stay in place: the controller already moves the body.
const IN_PLACE: Array[String] = ["roll", "jump_attack", "run_attack", "run", "run_free"]


func _initialize() -> void:
	var body: Node = load(BODY).instantiate()
	var action: Node = load(ACTION).instantiate()
	var body_player: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
	var body_skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
	var action_player: AnimationPlayer = action.find_child("AnimationPlayer", true, false)
	var action_skeleton: Skeleton3D = action.find_child("Skeleton3D", true, false)
	var skeleton_path: String = str(body_player.get_node(body_player.root_node).get_path_to(body_skeleton))
	var library: AnimationLibrary = AnimationLibrary.new()
	for source in NATIVE:
		var clip: Animation = body_player.get_animation("CharacterArmature|" + source).duplicate(true)
		library.add_animation(NATIVE[source], clip)
	var ratio: float = _rest(body_skeleton, "Body").origin.y / _rest(action_skeleton, "Body").origin.y
	for source in RETARGETED:
		var clip: Animation = action_player.get_animation("HumanArmature|" + source).duplicate(true)
		var name: String = RETARGETED[source]
		for track in range(clip.get_track_count() - 1, -1, -1):
			var bone: String = str(clip.track_get_path(track)).get_slice(":", 1)
			var kind: int = clip.track_get_type(track)
			if body_skeleton.find_bone(bone) < 0 or kind == Animation.TYPE_SCALE_3D:
				clip.remove_track(track)
				continue
			clip.track_set_path(track, NodePath(skeleton_path + ":" + bone))
			var from: Transform3D = _rest(action_skeleton, bone)
			var to: Transform3D = _rest(body_skeleton, bone)
			for key in clip.track_get_key_count(track):
				if kind == Animation.TYPE_POSITION_3D:
					var offset: Vector3 = (clip.track_get_key_value(track, key) - from.origin) * ratio
					if name in IN_PLACE and bone == "Body":
						offset = Vector3(0, offset.y, 0)
					clip.track_set_key_value(track, key, to.origin + offset)
				elif kind == Animation.TYPE_ROTATION_3D:
					var delta: Quaternion = from.basis.get_rotation_quaternion().inverse() * clip.track_get_key_value(track, key)
					clip.track_set_key_value(track, key, (to.basis.get_rotation_quaternion() * delta).normalized())
		library.add_animation(name, clip)
	for entry: Array in UAL:
		_retarget(library, body_skeleton, skeleton_path, entry[0], entry[1], entry[2])
	for name in LOOPING + UAL_LOOPING:
		if library.has_animation(name):
			library.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	var error: Error = ResourceSaver.save(library, OUTPUT, ResourceSaver.FLAG_COMPRESS)
	print("engineer animations: ", library.get_animation_list().size(), " clips -> ", OUTPUT, " (", error_string(error), ")")
	body.free()
	action.free()
	quit(0 if error == OK else 1)


## Retarget every listed clip from another rig. For each sample, each mapped source bone's
## world rotation relative to its T-pose (the library's A_TPose clip) is applied to the
## matching body bone's world T-pose (its rest), then turned back into a local rotation down
## the body's hierarchy. The hips carry the root offset (scaled to the body); the feet,
## which hang off the root in this rig, are placed at the end of their leg chains.
func _retarget(library: AnimationLibrary, body: Skeleton3D, skeleton_path: String, path: String, bone_map: Dictionary, clips: Dictionary, reference_clip: String = "A_TPose") -> void:
	var source: Node = load(path).instantiate()
	root.add_child(source)
	var player: AnimationPlayer = source.find_child("AnimationPlayer", true, false)
	var skeleton: Skeleton3D = source.find_child("Skeleton3D", true, false)
	var reference: Dictionary = {}
	if reference_clip.is_empty():
		for index in skeleton.get_bone_count():
			reference[skeleton.get_bone_name(index)] = skeleton.get_bone_global_rest(index)
	else:
		reference = _sample(player, skeleton, reference_clip, 0.0)
	var inverse: Dictionary = {}
	for bone: String in bone_map:
		inverse[bone_map[bone]] = bone
	# Space change from the library's skeleton to the body's, from the T-poses.
	var hips_source: String = inverse["Hips"]
	var source_basis: Basis = _frame(reference[inverse["UpperArm.L"]].origin, reference[inverse["UpperArm.R"]].origin, reference[hips_source].origin, reference[inverse["Neck"]].origin)
	var body_rest: Dictionary = {}
	for index in body.get_bone_count():
		body_rest[body.get_bone_name(index)] = body.get_bone_global_rest(index)
	var body_basis: Basis = _frame(body_rest["UpperArm.L"].origin, body_rest["UpperArm.R"].origin, body_rest["Hips"].origin, body_rest["Neck"].origin)
	var change: Basis = body_basis * source_basis.inverse()
	var change_q: Quaternion = change.get_rotation_quaternion()
	var ratio: float = (body_rest["Neck"].origin - body_rest["Hips"].origin).length() / maxf(.001, (reference[inverse["Neck"]].origin - reference[hips_source].origin).length())
	var order: Array[int] = []
	for index in body.get_bone_count():
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool: return _depth(body, a) < _depth(body, b))
	for clip_name: String in clips:
		var name: String = clips[clip_name]
		if _resolve(player, clip_name).is_empty():
			push_warning("UAL clip missing, skipped: " + clip_name)
			continue
		var length: float = player.get_animation(_resolve(player, clip_name)).length
		var clip: Animation = Animation.new()
		clip.length = length
		var rotation_tracks: Dictionary = {}
		for bone: String in inverse:
			if bone == "Foot.L" or bone == "Foot.R" or body.find_bone(bone) < 0:
				continue
			var track: int = clip.add_track(Animation.TYPE_ROTATION_3D)
			clip.track_set_path(track, NodePath(skeleton_path + ":" + bone))
			rotation_tracks[bone] = track
		var body_track: int = clip.add_track(Animation.TYPE_POSITION_3D)
		clip.track_set_path(body_track, NodePath(skeleton_path + ":Body"))
		var feet: Dictionary = {}
		for foot in ["Foot.L", "Foot.R"]:
			var position_track: int = clip.add_track(Animation.TYPE_POSITION_3D)
			clip.track_set_path(position_track, NodePath(skeleton_path + ":" + foot))
			var rotation_track: int = clip.add_track(Animation.TYPE_ROTATION_3D)
			clip.track_set_path(rotation_track, NodePath(skeleton_path + ":" + foot))
			feet[foot] = [position_track, rotation_track]
		var steps: int = maxi(1, int(ceil(length * SAMPLE_RATE)))
		for step in range(steps + 1):
			var time: float = minf(length, step / SAMPLE_RATE)
			var posed: Dictionary = _sample(player, skeleton, clip_name, time)
			var global: Dictionary = {}
			for index: int in order:
				var bone: String = body.get_bone_name(index)
				var parent: int = body.get_bone_parent(index)
				var parent_global: Transform3D = global[body.get_bone_name(parent)] if parent >= 0 else Transform3D.IDENTITY
				var local: Transform3D = body.get_bone_rest(index)
				if inverse.has(bone):
					var src: String = inverse[bone]
					var delta: Quaternion = posed[src].basis.get_rotation_quaternion() * reference[src].basis.get_rotation_quaternion().inverse()
					if name in DAMPED and DAMPING.has(bone):
						delta = Quaternion.IDENTITY.slerp(delta, DAMPING[bone])
					var world: Quaternion = change_q * delta * change_q.inverse() * body_rest[bone].basis.get_rotation_quaternion()
					local.basis = Basis((parent_global.basis.get_rotation_quaternion().inverse() * world).normalized())
				if bone == "Body":
					var offset: Vector3 = change * (posed[hips_source].origin - reference[hips_source].origin) * ratio
					if name in UAL_IN_PLACE:
						offset = Vector3(0, offset.y, 0)
					if name in DAMPED:
						offset *= DAMPING.Body
					local.origin = body.get_bone_rest(index).origin + parent_global.basis.inverse() * offset
					clip.position_track_insert_key(body_track, time, local.origin)
				global[bone] = parent_global * local
				if rotation_tracks.has(bone):
					clip.rotation_track_insert_key(rotation_tracks[bone], time, local.basis.get_rotation_quaternion())
			for foot: String in feet:
				var side: String = foot.get_slice(".", 1)
				var ankle: Transform3D = global["LowerLeg.%s_end" % side] if global.has("LowerLeg.%s_end" % side) else global["LowerLeg." + side]
				var foot_index: int = body.find_bone(foot)
				var parent_global: Transform3D = global[body.get_bone_name(body.get_bone_parent(foot_index))]
				var src: String = inverse[foot]
				var delta: Quaternion = posed[src].basis.get_rotation_quaternion() * reference[src].basis.get_rotation_quaternion().inverse()
				var world: Quaternion = change_q * delta * change_q.inverse() * body_rest[foot].basis.get_rotation_quaternion()
				clip.position_track_insert_key(feet[foot][0], time, parent_global.affine_inverse() * ankle.origin)
				clip.rotation_track_insert_key(feet[foot][1], time, (parent_global.basis.get_rotation_quaternion().inverse() * world).normalized())
		library.add_animation(name, clip)
	source.queue_free()


## A right-handed frame from the shoulders (right) and hips-to-neck (up).
func _frame(left: Vector3, right: Vector3, hips: Vector3, neck: Vector3) -> Basis:
	var x: Vector3 = (right - left).normalized()
	var y: Vector3 = (neck - hips).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, z.cross(x).normalized(), z)


func _depth(skeleton: Skeleton3D, index: int) -> int:
	var depth: int = 0
	while skeleton.get_bone_parent(index) >= 0:
		index = skeleton.get_bone_parent(index)
		depth += 1
	return depth


## Clip names arrive bare, armature-qualified, or with Godot's "_Loop" suffix stripped.
func _resolve(player: AnimationPlayer, name: String) -> String:
	for wanted in [name, name.trim_suffix("_Loop")]:
		for candidate in player.get_animation_list():
			if candidate == wanted or candidate.ends_with("|" + wanted) or candidate.ends_with("/" + wanted):
				return candidate
	return ""


## The library's skeleton posed by `clip` at `time`: bone name -> skeleton-space transform.
func _sample(player: AnimationPlayer, skeleton: Skeleton3D, clip: String, time: float) -> Dictionary:
	player.play(_resolve(player, clip), 0.0)
	player.seek(time, true)
	player.advance(0.0)
	# Composed by hand from the local poses: outside a running frame the skeleton's cached
	# global poses lag behind seek().
	var out: Dictionary = {}
	var global: Array[Transform3D] = []
	global.resize(skeleton.get_bone_count())
	var done: Array[bool] = []
	done.resize(skeleton.get_bone_count())
	for index in skeleton.get_bone_count():
		_compose(skeleton, index, global, done)
		out[skeleton.get_bone_name(index)] = global[index]
	return out


func _compose(skeleton: Skeleton3D, index: int, global: Array[Transform3D], done: Array[bool]) -> Transform3D:
	if done[index]:
		return global[index]
	var parent: int = skeleton.get_bone_parent(index)
	var local: Transform3D = skeleton.get_bone_pose(index)
	global[index] = (_compose(skeleton, parent, global, done) * local) if parent >= 0 else local
	done[index] = true
	return global[index]


func _rest(skeleton: Skeleton3D, bone: String) -> Transform3D:
	return skeleton.get_bone_rest(skeleton.find_bone(bone))
