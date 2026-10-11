extends "res://tools/build_engineer_rig.gd"
## Optional locally licensed motion; never merge it into the public CC0 library.
const TRIAL_PATH: String = "res://assets/characters/kevin_trial/"
const KEVIN_BONES: Dictionary = {
	"B-hips": "Hips", "B-spine": "Abdomen", "B-chest": "Torso", "B-neck": "Neck", "B-head": "Head",
	"B-shoulder.L": "Shoulder.L", "B-upperArm.L": "UpperArm.L", "B-forearm.L": "LowerArm.L", "B-hand.L": "Fist.L",
	"B-shoulder.R": "Shoulder.R", "B-upperArm.R": "UpperArm.R", "B-forearm.R": "LowerArm.R", "B-hand.R": "Fist.R",
	"B-thigh.L": "UpperLeg.L", "B-shin.L": "LowerLeg.L", "B-foot.L": "Foot.L",
	"B-thigh.R": "UpperLeg.R", "B-shin.R": "LowerLeg.R", "B-foot.R": "Foot.R",
}


func _initialize() -> void:
	for file in ["attack_2h.fbx"]:
		if not ResourceLoader.exists(TRIAL_PATH + file):
			push_error("Obtain Kevin's free Godot/Unreal pack first; see " + TRIAL_PATH + "README.md")
			quit(1)
			return
	var body: Node = load(BODY).instantiate()
	var player: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
	var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
	var skeleton_path: String = str(player.get_node(player.root_node).get_path_to(skeleton))
	var library: AnimationLibrary = AnimationLibrary.new()
	_retarget(library, skeleton, skeleton_path, TRIAL_PATH + "attack_2h.fbx", KEVIN_BONES, {"HumanM_Attack2H01": "kevin_2h"}, "")
	if not library.has_animation("kevin_2h"):
		push_error("Expected Kevin's two-handed attack; no output saved")
		quit(1)
		return
	var error: Error = ResourceSaver.save(library, TRIAL_PATH + "sword_trial.res", ResourceSaver.FLAG_COMPRESS)
	print("Local sword trial: ", library.get_animation_list(), " ", error_string(error))
	body.free()
	quit(0 if error == OK else 1)
