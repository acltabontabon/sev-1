class_name MonsterRig
extends Node3D
## Rigged body for an incident: a CC0 Quaternius model played from the enemy's own state
## (pursuit speed, melee windows, stagger, casts, death). Presentation only: it never moves
## the body, starts attacks or applies damage. Provenance: assets/enemies/README.md.

const SHADER: Shader = preload("res://game/enemies/corruption.gdshader")
const ROOT: String = "res://assets/enemies/quaternius/"
## Per kind: model, texture, standing height in metres and clip roles. `impact` is the
## fraction of the attack clip where the blow lands; it is pinned to the end of wind-up.
const KINDS: Dictionary = {
	"record": {"model": "stan.fbx", "texture": "stan_texture.png", "height": 2.05,
		"idle": "Idle", "walk": "Walk", "run": "Run", "attack": "SwordSlash", "impact": .42,
		"hit": "HitRecieve_1", "death": "Death", "cast": "Shoot"},
	"blocker": {"model": "leela.fbx", "texture": "leela_texture.png", "height": 2.3,
		"idle": "Idle", "walk": "Walk", "run": "Walk", "attack": "Punch", "impact": .45,
		"hit": "HitRecieve_2", "death": "Death", "cast": "Shoot"},
	"invite": {"model": "george.fbx", "texture": "george_texture.png", "height": 2.55,
		"idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Kick", "impact": .45,
		"hit": "HitRecieve_1", "death": "Death", "cast": "Shoot"},
	"scope": {"model": "slime.fbx", "texture": "", "height": .95, "color": Color(.62, .95, .32),
		"idle": "Slime_Idle", "walk": "Slime_Walk", "run": "Slime_Walk", "attack": "Slime_Attack", "impact": .5,
		"hit": "", "death": "Slime_Death", "cast": ""},
	"variance": {"model": "mike.fbx", "texture": "mike_texture.png", "height": 3.1,
		"idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Punch", "impact": .45,
		"hit": "HitRecieve_2", "death": "Death", "cast": "Shoot"},
}
const LOOPING: Array[String] = ["idle", "walk", "run", "cast"]

static var materials: Dictionary = {}
static var scales: Dictionary = {}

var kind: String = "record"
var actor: CharacterBody3D
var spec: Dictionary
var model: Node3D
var animator: AnimationPlayer
var clips: Dictionary = {}
var meshes: Array[MeshInstance3D] = []
var cast_left: float = 0.0
var dying: float = 0.0


static func create(kind_: String, owner_actor: CharacterBody3D) -> MonsterRig:
	var rig: MonsterRig = MonsterRig.new()
	rig.name = "Rig"
	rig.kind = kind_
	rig.actor = owner_actor
	return rig


func _ready() -> void:
	process_physics_priority = 10
	spec = KINDS[kind]
	model = load(ROOT + spec.model).instantiate()
	add_child(model)
	model.rotation.y = PI
	animator = model.find_child("AnimationPlayer", true, false)
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for role in ["idle", "walk", "run", "attack", "hit", "death", "cast"]:
		clips[role] = _resolve(spec.get(role, ""))
	for role in LOOPING:
		if clips[role] != "":
			animator.get_animation(clips[role]).loop_mode = Animation.LOOP_LINEAR
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		meshes.append(mesh)
		(mesh as MeshInstance3D).material_override = _material()
	model.scale = Vector3.ONE * _scale()
	reset()


func reset() -> void:
	dying = 0.0
	cast_left = 0.0
	animator.play(clips.idle, 0.0)
	animator.seek(randf() * animator.current_animation_length, true)
	_shade(0.0, 0.0, 0.0)


## Size of the standing body in this node's space (before any growth scale).
func bounds() -> AABB:
	var result: AABB = AABB()
	var first: bool = true
	for mesh in meshes:
		var box: AABB = global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result


## Raise an arm for a spell (Blocker shield, Meeting Invite booking).
func cast(seconds: float) -> void:
	cast_left = seconds


## A walking, idle copy wearing `material`: The Variance's false positives.
func projection(material: Material) -> Node3D:
	var copy: Node3D = load(ROOT + spec.model).instantiate()
	copy.rotation.y = PI
	copy.scale = model.scale
	for mesh in copy.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = material
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var player: AnimationPlayer = copy.find_child("AnimationPlayer", true, false)
	player.play(clips.idle)
	return copy


func _physics_process(delta: float) -> void:
	if actor == null or actor.hitstop_left > 0:
		return
	if actor.health <= 0:
		if dying == 0.0:
			animator.play(clips.death, .1)
			animator.speed_scale = 1.0
		dying += delta
		animator.advance(delta)
		_shade(0.0, 0.0, clampf((dying - 1.5) / 1.3, 0.0, 1.0))
		return
	var melee: Node3D = actor.melee
	var charge: float = 0.0
	if melee.attacking and clips.attack != "":
		var length: float = animator.get_animation(clips.attack).length
		var impact: float = length * spec.impact
		var after: float = minf(length, impact + length * .12)
		var time: float
		if melee.elapsed < melee.windup:
			time = lerpf(0.0, impact, melee.elapsed / melee.windup)
			charge = melee.elapsed / melee.windup
		elif melee.elapsed < melee.windup + melee.active_time:
			time = lerpf(impact, after, (melee.elapsed - melee.windup) / melee.active_time)
		else:
			time = lerpf(after, length, clampf((melee.elapsed - melee.windup - melee.active_time) / melee.recovery, 0, 1))
		_scrub(clips.attack, time, .08, delta)
	elif actor.stagger_left > 0 and clips.hit != "":
		var length: float = animator.get_animation(clips.hit).length
		_scrub(clips.hit, (1.0 - actor.stagger_left / maxf(actor.hit_reaction_duration, .01)) * length * .5, .05, delta)
	elif cast_left > 0 and clips.cast != "":
		cast_left = maxf(0.0, cast_left - delta)
		charge = .6
		_loop(clips.cast, 1.0, .12, delta)
	else:
		var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
		if speed > 3.0 and clips.run != clips.walk:
			_loop(clips.run, clampf(speed / 4.5, .7, 1.6), .2, delta)
		elif speed > .25:
			_loop(clips.walk, clampf(speed / 1.8, .6, 1.8), .2, delta)
		else:
			_loop(clips.idle, 1.0, .25, delta)
	_shade(1.0 if actor.flash_left > 0 else 0.0, charge, 0.0)


func _shade(flash: float, charge: float, dissolve: float) -> void:
	var color: Color = actor.magic_color if actor != null else Color(1, .25, .3)
	for mesh in meshes:
		mesh.set_instance_shader_parameter("glow", color)
		mesh.set_instance_shader_parameter("flash", flash)
		mesh.set_instance_shader_parameter("charge", charge)
		mesh.set_instance_shader_parameter("dissolve", dissolve)


func _scrub(clip: String, time: float, blend: float, delta: float) -> void:
	if animator.current_animation != clip:
		animator.play(clip, blend)
	animator.speed_scale = 1.0
	animator.seek(maxf(0.0, time - delta), false)
	animator.advance(delta)


func _loop(clip: String, rate: float, blend: float, delta: float) -> void:
	if animator.current_animation != clip:
		animator.play(clip, blend)
	animator.speed_scale = rate
	animator.advance(delta)


## Clip names arrive as "Armature|Name" or bare; prefer the armature-qualified one.
func _resolve(role: String) -> String:
	if role == "":
		return ""
	var bare: String = ""
	for name in animator.get_animation_list():
		if name.ends_with("|" + role):
			return name
		if name == role:
			bare = name
	return bare


func _material() -> ShaderMaterial:
	if not materials.has(kind):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = SHADER
		if spec.texture != "":
			material.set_shader_parameter("albedo_tex", load(ROOT + spec.texture))
		else:
			material.set_shader_parameter("use_texture", false)
			material.set_shader_parameter("base_color", spec.get("color", Color.WHITE))
			material.set_shader_parameter("metal", 0.0)
		materials[kind] = material
	return materials[kind]


func _scale() -> float:
	if not scales.has(kind):
		var bounds: AABB = AABB()
		var first: bool = true
		for mesh in meshes:
			var box: AABB = model.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		scales[kind] = spec.height / maxf(bounds.size.y, .001)
	return scales[kind]
