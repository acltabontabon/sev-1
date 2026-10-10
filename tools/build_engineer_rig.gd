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
	for name in LOOPING:
		library.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	var error: Error = ResourceSaver.save(library, OUTPUT, ResourceSaver.FLAG_COMPRESS)
	print("engineer animations: ", library.get_animation_list().size(), " clips -> ", OUTPUT, " (", error_string(error), ")")
	body.free()
	action.free()
	quit(0 if error == OK else 1)


func _rest(skeleton: Skeleton3D, bone: String) -> Transform3D:
	return skeleton.get_bone_rest(skeleton.find_bone(bone))
