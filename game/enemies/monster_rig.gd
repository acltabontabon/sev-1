class_name MonsterRig
extends Node3D
## Rigged body for an incident: a CC0 model played from the enemy's own state (pursuit
## speed, melee windows, stagger, casts, manifesting, death). Presentation only: it never
## moves the body, starts attacks or applies damage. Provenance: assets/enemies/README.md.

const OVERLAY: Shader = preload("res://game/enemies/corruption.gdshader")
const FLESH: Shader = preload("res://game/enemies/monster_flesh.gdshader")
## The pack's cheerful flat colours, regraded dark: [colour, roughness, metallic, wet,
## glow]. Unlisted materials are darkened. Eyes glow dimly; nothing is neon.
const PALETTE: Dictionary = {
	"Orc_Main": [Color(.3, .34, .24), .8, 0.0, .3, 0.0],
	"Orc_Secondary": [Color(.16, .2, .13), .85, 0.0, .2, 0.0],
	"Orc_Mouth": [Color(.32, .05, .07), .35, 0.0, .8, 0.0],
	"MushroomKing_Main": [Color(.55, .48, .38), .7, 0.0, .1, 0.0],
	"Belt.001": [Color(.17, .13, .09), .9, 0.0, 0.0, 0.0],
	"Wood": [Color(.22, .15, .09), .9, 0.0, 0.0, 0.0],
	"Metal": [Color(.3, .26, .22), .65, .6, 0.0, 0.0],
	"Yeti_Main": [Color(.38, .36, .32), .95, 0.0, .1, 0.0],
	"Yeti_Secondary": [Color(.19, .14, .17), .6, 0.0, .5, 0.0],
	"Yeti_Teeth": [Color(.58, .47, .3), .5, 0.0, .3, 0.0],
	"Teeth": [Color(.58, .47, .3), .5, 0.0, .3, 0.0],
	"Tongue": [Color(.3, .05, .09), .3, 0.0, .9, 0.0],
	"Dragon_Main": [Color(.28, .09, .06), .7, 0.0, .3, 0.0],
	"Dragon_Secondary": [Color(.13, .05, .07), .6, 0.0, .4, 0.0],
	"Dragon_Horn": [Color(.45, .4, .32), .6, 0.0, .1, 0.0],
	"Green_Main": [Color(.22, .25, .1), .25, 0.0, .9, 0.0],
	"Demon_Main": [Color(.26, .035, .035), .65, 0.0, .3, 0.0],
	"Black": [Color(.05, .04, .04), .5, 0.0, .3, 0.0],
	"Armabee_Main": [Color(.06, .05, .045), .3, .2, .6, 0.0],
	"Armabee_Secondary": [Color(.34, .22, .05), .45, 0.0, .3, 0.0],
	"Wings": [Color(.26, .24, .21), .4, 0.0, .3, 0.0],
	"Eye_White": [Color(.55, .45, .2), .2, 0.0, .8, 1.4],
	"Eye_Black": [Color(.02, 0, 0), .1, 0.0, 1.0, 0.0],
}
## Per kind: model, standing height in metres (for labels and bars), model `scale` (the
## Ultimate Monsters share one authoring scale; skinned bounds understate flyers), optional
## hover `lift`, and clip roles.
## `impact` is the fraction of the attack clip where the blow lands; it is pinned to the
## end of the melee wind-up so the visible hit matches the damage frame.
## Where a humanoid comes apart at the waist: the upper bones vanish from the body that
## stays (legs and hips), the lower ones from the half that flies.
const HUMANOID_CUT: Dictionary = {"upper": ["Abdomen"], "lower": ["UpperLeg.L", "UpperLeg.R", "Foot.L", "Foot.R"], "center": "Torso"}
const KINDS: Dictionary = {
	"record": {"model": "res://assets/enemies/ultimate_monsters/orc_skull.gltf", "height": 2.1, "scale": .65, "slice": HUMANOID_CUT,
		"idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Weapon", "impact": .45,
		"hit": "HitReact", "death": "Death", "cast": ""},
	"blocker": {"model": "res://assets/enemies/ultimate_monsters/yeti.gltf", "height": 2.5, "scale": .88, "slice": HUMANOID_CUT,
		"idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Punch", "impact": .45,
		"hit": "HitReact", "death": "Death", "cast": "Wave"},
	"invite": {"model": "res://assets/enemies/ultimate_monsters/dragon.gltf", "height": 1.8, "scale": .45, "lift": .4,
		"idle": "Flying_Idle", "walk": "Fast_Flying", "run": "Fast_Flying", "attack": "Headbutt", "impact": .45,
		"hit": "HitReact", "death": "Death", "cast": "Punch"},
	"standup": {"model": "res://assets/enemies/ultimate_monsters/squidle.gltf", "height": 2.5, "scale": .85, "lift": .2,
		"palette": {"Squidle_Main": [Color(.24, .16, .19), .55, 0.0, .6, 0.0],
			"Squidle_Secondary": [Color(.12, .07, .09), .6, 0.0, .5, 0.0],
			"Squidle_Horn": [Color(.55, .46, .32), .65, 0.0, .2, 0.0],
			"Eye_White": [Color(.34, .2, .08), .3, 0.0, .7, .6]},
		"idle": "Flying_Idle", "walk": "Fast_Flying", "run": "Fast_Flying", "attack": "Headbutt", "impact": .45,
		"hit": "HitReact", "death": "Death", "cast": "Punch"},
	"scope": {"model": "res://assets/enemies/ultimate_monsters/spiky_blob.gltf", "height": 1.1, "scale": .33,
		"palette": {"Eye_White": [Color(.42, .37, .28), .55, 0.0, .3, 0.0]},
		"idle": "Idle", "walk": "Walk", "run": "Walk", "attack": "Bite_Front", "impact": .45,
		"hit": "HitRecieve", "death": "Death", "cast": ""},
	"variance": {"model": "res://assets/enemies/ultimate_monsters/demon.gltf", "height": 3.2, "scale": 1.0, "slice": HUMANOID_CUT,
		"idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Weapon", "impact": .45,
		"hit": "HitReact", "death": "Death", "cast": "Wave"},
	"bug": {"model": "res://assets/enemies/ultimate_monsters/armabee.gltf", "height": .75, "scale": .35, "lift": .2,
		"idle": "Flying_Idle", "walk": "Fast_Flying", "run": "Fast_Flying", "attack": "Headbutt", "impact": .45,
		"hit": "HitReact", "death": "Death", "cast": ""},
}
const LOOPING: Array[String] = ["idle", "walk", "run", "cast"]
const ROLES: Array[String] = ["idle", "walk", "run", "attack", "hit", "death", "cast", "spawn"]

static var overlay: ShaderMaterial
static var scales: Dictionary = {}
## Deaths are physical in a rendered game: a hard blade kill slices humanoids in half, any
## other kill launches the body tumbling, and data chunks spray from the hit. Headless runs
## keep the plain death unless this is set.
static var gore_in_headless: bool = false
static var gib_mesh: BoxMesh
const GORE_LAYER: int = 1 << 7
const SLICE_DAMAGE: int = 35
var pieces: Array[RigidBody3D] = []
## Skeleton -> bone indices held at zero scale (the parts that went with the other half).
var collapsed: Dictionary = {}
var death_style: String = ""

var kind: String = "record"
var actor: CharacterBody3D
var spec: Dictionary
var model: Node3D
var animator: AnimationPlayer
var clips: Dictionary = {}
var meshes: Array[MeshInstance3D] = []
var cast_left: float = 0.0
## The current stagger's full length: specials stagger far longer than a normal hit.
var stagger_peak: float = 0.0
var last_stagger: float = 0.0
var dying: float = 0.0
var base_scale: float = 1.0


static func create(kind_: String, owner_actor: CharacterBody3D) -> MonsterRig:
	var rig: MonsterRig = MonsterRig.new()
	rig.name = "Rig"
	rig.kind = kind_
	rig.actor = owner_actor
	return rig


func _ready() -> void:
	process_physics_priority = 10
	spec = KINDS[kind]
	model = load(spec.model).instantiate()
	add_child(model)
	model.rotation.y = PI
	animator = model.find_child("AnimationPlayer", true, false)
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for role in ROLES:
		clips[role] = _resolve(spec.get(role, ""))
	for role in LOOPING:
		if clips[role] != "":
			animator.get_animation(clips[role]).loop_mode = Animation.LOOP_LINEAR
	if overlay == null:
		overlay = ShaderMaterial.new()
		overlay.shader = OVERLAY
	# Dark, grimy flesh in place of the pack's flat colours; the overlay pass only adds the
	# fight-readable charge glow and hit flash.
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh as MeshInstance3D
		meshes.append(instance)
		for surface in instance.mesh.get_surface_count():
			var skin: Material = _skin(instance.get_active_material(surface))
			skin.next_pass = overlay
			instance.set_surface_override_material(surface, skin)
	base_scale = _scale()
	reset()


static var skins: Dictionary = {}


## One shared monster material per source material: the flesh shader in its dark palette.
func _skin(source: Material) -> Material:
	var key: String = source.resource_name if source != null else ""
	# A kind can repaint a shared material name (the blob's spikes reuse "Eye_White").
	var overrides: Dictionary = spec.get("palette", {})
	var cache: String = (kind + ":" + key) if overrides.has(key) else key
	if skins.has(cache):
		return skins[cache]
	var skin: ShaderMaterial = ShaderMaterial.new()
	skin.shader = FLESH
	var base: Color = (source as StandardMaterial3D).albedo_color.darkened(.45) if source is StandardMaterial3D else Color(.2, .2, .2)
	var look: Array = overrides.get(key, PALETTE.get(key, [base, .75, 0.0, .2, 0.0]))
	skin.set_shader_parameter("base_color", look[0])
	skin.set_shader_parameter("roughness_base", look[1])
	skin.set_shader_parameter("metallic_base", look[2])
	skin.set_shader_parameter("wet", look[3])
	skin.set_shader_parameter("emission_color", Color(.9, .55, .15))
	skin.set_shader_parameter("emission_strength", look[4])
	skin.set_shader_parameter("detail_scale", 4.0)
	skins[cache] = skin
	return skin


func reset() -> void:
	# A restarted actor gets its body back from any physics it was flung into.
	if model.get_parent() != self:
		model.reparent(self, false)
		model.rotation = Vector3(0, PI, 0)
	for body in pieces:
		if is_instance_valid(body):
			body.queue_free()
	pieces.clear()
	collapsed.clear()
	death_style = ""
	meshes = meshes.filter(func(mesh: MeshInstance3D) -> bool: return is_instance_valid(mesh) and model.is_ancestor_of(mesh))
	dying = 0.0
	cast_left = 0.0
	model.scale = Vector3.ONE * base_scale
	model.position = Vector3(0, spec.get("lift", 0.0), 0)
	animator.play(clips.idle, 0.0)
	animator.seek(randf() * animator.current_animation_length, true)
	_shade(0.0, 0.0, 0.0)


## Raise an arm for a spell (Blocker shield, Meeting Invite booking).
func cast(seconds: float) -> void:
	cast_left = seconds


## Size of the standing body in this node's space (before any growth scale).
func bounds() -> AABB:
	var result: AABB = AABB()
	var first: bool = true
	for mesh in meshes:
		var box: AABB = global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result


## An idle copy wearing `material`: The Variance's false positives.
func projection(material: Material) -> Node3D:
	var copy: Node3D = load(spec.model).instantiate()
	copy.rotation.y = PI
	copy.scale = Vector3.ONE * base_scale
	copy.position.y = spec.get("lift", 0.0)
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
		_die(delta)
		return
	var melee: Node3D = actor.melee
	var charge: float = 0.0
	if actor.awareness == actor.Awareness.MANIFESTING and clips.spawn != "":
		var length: float = animator.get_animation(clips.spawn).length
		_scrub(clips.spawn, (1.0 - actor.awareness_left / .9) * length, 0.0, delta)
	elif melee.attacking and clips.attack != "":
		var length: float = animator.get_animation(clips.attack).length
		var impact: float = length * spec.impact
		var after: float = minf(length, impact + length * .12)
		var time: float
		if melee.elapsed < melee.windup:
			time = lerpf(0.0, impact, ease(melee.elapsed / melee.windup, 2.2))
			charge = melee.elapsed / melee.windup
		elif melee.elapsed < melee.windup + melee.active_time:
			time = lerpf(impact, after, (melee.elapsed - melee.windup) / melee.active_time)
		else:
			time = lerpf(after, length, clampf((melee.elapsed - melee.windup - melee.active_time) / melee.recovery, 0, 1))
		_scrub(clips.attack, time, .06, delta)
	elif actor.stagger_left > 0 and clips.hit != "":
		var length: float = animator.get_animation(clips.hit).length
		# A fresh stagger (or a new hit during one) starts the reaction over.
		if actor.stagger_left > last_stagger:
			stagger_peak = actor.stagger_left
		_scrub(clips.hit, (1.0 - actor.stagger_left / maxf(stagger_peak, .01)) * length * .5, .05, delta)
	elif cast_left > 0 and clips.cast != "":
		cast_left = maxf(0.0, cast_left - delta)
		charge = .6
		_loop(clips.cast, 1.0, .12, delta)
	else:
		var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
		# Separate thresholds up and down, so a pace near the line doesn't flicker clips.
		var running: bool = animator.current_animation == clips.run
		if speed > (2.6 if running else 3.4) and clips.run != clips.walk:
			_loop(clips.run, clampf(speed / 4.5, .7, 1.6), .2, delta)
		elif speed > .25:
			_loop(clips.walk, clampf(speed / 2.2, .6, 1.8), .2, delta)
		else:
			_loop(clips.idle, 1.0, .25, delta)
	last_stagger = actor.stagger_left
	_shade(1.0 if actor.flash_left > 0 else 0.0, charge, 0.0)


## Death clip, then the corpse sinks through the floor glowing; no clip means a squash.
## With gore on, the body is sliced or launched first and dissolves where it lands.
func _die(delta: float) -> void:
	if dying == 0.0:
		if clips.death != "":
			animator.play(clips.death, .08)
			animator.speed_scale = 1.0
		if DisplayServer.get_name() != "headless" or gore_in_headless:
			_break_apart()
	dying += delta
	var settle: float = animator.get_animation(clips.death).length if clips.death != "" else .12
	if clips.death != "":
		animator.advance(delta)
	elif pieces.is_empty():
		model.scale = Vector3(base_scale * (1.0 + dying), base_scale * maxf(.08, 1.0 - dying * 8.0), base_scale * (1.0 + dying))
	_hold_collapsed()
	if pieces.is_empty():
		var sink: float = clampf((dying - settle) / 1.0, 0.0, 1.0)
		model.position.y = spec.get("lift", 0.0) * (1.0 - minf(1.0, dying * 2.0)) - sink * 1.2
		_shade(0.0, 0.0, sink)
		return
	# The pieces come to rest, then dissolve where they fell; a cut leaves a second pool.
	if dying > 1.6:
		for body in pieces:
			if is_instance_valid(body) and not body.freeze:
				body.freeze = true
				if death_style == "slice":
					Blood.splat(actor.get_parent(), body.global_position, body.linear_velocity, spec.height * .7)
	_shade(0.0, 0.0, clampf((dying - 1.2) / .9, 0.0, 1.0))


func _break_apart() -> void:
	var away: Vector3 = actor.knockback
	away.y = 0
	away = away.normalized() if away.length() > .01 else (actor.global_basis.z if actor != null else Vector3.BACK)
	death_style = str(actor.get_meta("kill_style", ""))
	if death_style.is_empty():
		death_style = "slice" if actor.last_damage >= SLICE_DAMAGE else "tumble"
	if death_style == "slice" and spec.has("slice"):
		_slice(away)
	else:
		if death_style == "slice":
			death_style = "tumble"
		_tumble(away, death_style == "launch")
	_gibs(away)


func _bone_center(skeleton: Skeleton3D, bone: String) -> Vector3:
	var index: int = skeleton.find_bone(bone)
	if index < 0:
		return model.global_position + Vector3.UP * spec.height * .5
	return skeleton.global_transform * skeleton.get_bone_global_pose(index).origin


func _body(center: Vector3, radius: float) -> RigidBody3D:
	var body: RigidBody3D = RigidBody3D.new()
	body.name = "Piece"
	body.top_level = true
	body.collision_layer = GORE_LAYER
	body.collision_mask = 1
	body.mass = 2.0
	body.angular_damp = 1.2
	var shape: CollisionShape3D = CollisionShape3D.new()
	var ball: SphereShape3D = SphereShape3D.new()
	ball.radius = radius
	shape.shape = ball
	body.add_child(shape)
	actor.add_child(body)
	body.global_position = center
	pieces.append(body)
	return body


## The whole body goes flying and rolls, still playing its death.
func _tumble(away: Vector3, launch: bool) -> void:
	var center: Vector3 = model.global_position + Vector3.UP * spec.height * .45
	var body: RigidBody3D = _body(center, spec.height * .28)
	model.reparent(body, true)
	body.linear_velocity = away * (7.0 if launch else 4.5) + Vector3.UP * (8.0 if launch else 3.5)
	body.angular_velocity = away.cross(Vector3.UP) * -randf_range(5.0, 9.0) + Vector3.UP * randf_range(-3.0, 3.0)


## Cut at the waist: the legs stay and crumple; a copy keeps only the upper half and flies.
func _slice(away: Vector3) -> void:
	var cut: Dictionary = spec.slice
	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	var center: Vector3 = _bone_center(skeleton, cut.center)
	var copy: Node3D = load(spec.model).instantiate()
	var body: RigidBody3D = _body(center, spec.height * .2)
	body.add_child(copy)
	copy.global_transform = model.global_transform
	var copy_skeleton: Skeleton3D = copy.find_child("Skeleton3D", true, false)
	var copy_player: AnimationPlayer = copy.find_child("AnimationPlayer", true, false)
	if copy_player != null:
		copy_player.active = false
	for index in skeleton.get_bone_count():
		copy_skeleton.set_bone_pose_position(index, skeleton.get_bone_pose_position(index))
		copy_skeleton.set_bone_pose_rotation(index, skeleton.get_bone_pose_rotation(index))
		copy_skeleton.set_bone_pose_scale(index, skeleton.get_bone_pose_scale(index))
	# Same skin as the body it came from, so the dissolve covers both halves.
	var originals: Array = model.find_children("*", "MeshInstance3D", true, false)
	var halves: Array = copy.find_children("*", "MeshInstance3D", true, false)
	for index in range(mini(originals.size(), halves.size())):
		var source: MeshInstance3D = originals[index]
		var half: MeshInstance3D = halves[index]
		for surface in half.mesh.get_surface_count():
			half.set_surface_override_material(surface, source.get_surface_override_material(surface))
		meshes.append(half)
	collapsed[skeleton] = cut.upper.map(func(bone: String) -> int: return skeleton.find_bone(bone)).filter(func(index: int) -> bool: return index >= 0)
	collapsed[copy_skeleton] = cut.lower.map(func(bone: String) -> int: return copy_skeleton.find_bone(bone)).filter(func(index: int) -> bool: return index >= 0)
	_hold_collapsed()
	body.linear_velocity = away * 3.5 + Vector3.UP * 6.0
	body.angular_velocity = away.cross(Vector3.UP) * -randf_range(6.0, 9.0)
	var side: Vector3 = away.cross(Vector3.UP).normalized()
	ElementFx.bolt(actor, center - side * 1.4, center + side * 1.4, Color(1, .97, .85), .35, .1)
	ElementFx.motes(actor, center, actor.magic_color, 26, 5.0, .7, -6.0, .14)
	# Blood: a burst from the cut, both halves spurting, a pool where it happened.
	var level: Node = actor.get_parent()
	Blood.burst(level, center, away + Vector3.UP * .8, 60)
	Blood.burst(level, center, -away + Vector3.UP * .4, 24)
	Blood.spurt(body, Vector3.ZERO, -Vector3.UP, .9)
	Blood.spurt(actor, Vector3.UP * spec.height * .4, Vector3.UP, .7)
	Blood.splat(level, center + away * .7, away, spec.height * 1.1)


func _hold_collapsed() -> void:
	for skeleton: Skeleton3D in collapsed:
		if is_instance_valid(skeleton):
			for index: int in collapsed[skeleton]:
				skeleton.set_bone_pose_scale(index, Vector3.ONE * .001)


static var meats: Array[StandardMaterial3D] = []


static func _meat(index: int) -> StandardMaterial3D:
	if meats.is_empty():
		for tone: Array in [[Color(.3, .02, .03), .25], [Color(.42, .1, .08), .45], [Color(.22, .01, .02), .2], [Color(.55, .48, .38), .6]]:
			var meat: StandardMaterial3D = StandardMaterial3D.new()
			meat.albedo_color = tone[0]
			meat.roughness = tone[1]
			meats.append(meat)
	return meats[index % meats.size()]


## Chunks spray from the kill and bounce off the floor.
func _gibs(away: Vector3) -> void:
	if gib_mesh == null:
		gib_mesh = BoxMesh.new()
		gib_mesh.size = Vector3.ONE * .13
	var center: Vector3 = actor.global_position + Vector3.UP * spec.height * .5
	var count: int = 6 if spec.height < 1.0 else 12
	for index in range(count):
		var gib: RigidBody3D = RigidBody3D.new()
		gib.name = "Gib"
		gib.set_meta("gib", true)
		gib.top_level = true
		gib.collision_layer = GORE_LAYER
		gib.collision_mask = 1
		gib.mass = .15
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3.ONE * .13
		shape.shape = box
		gib.add_child(shape)
		var chunk: MeshInstance3D = MeshInstance3D.new()
		chunk.mesh = gib_mesh
		chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Meat, blood and the odd bit of bone.
		chunk.material_override = _meat(index % 4)
		chunk.scale = Vector3.ONE * randf_range(.7, 1.6)
		gib.add_child(chunk)
		actor.add_child(gib)
		gib.global_position = center + Vector3(randf_range(-.3, .3), randf_range(-.3, .3), randf_range(-.3, .3))
		var spray: Vector3 = (away * randf_range(1.5, 4.0) + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf_range(1.0, 3.5))
		gib.linear_velocity = spray + Vector3.UP * randf_range(2.5, 6.0)
		gib.angular_velocity = Vector3(randf_range(-12, 12), randf_range(-12, 12), randf_range(-12, 12))
		get_tree().create_timer(randf_range(1.1, 1.7), false).timeout.connect(gib.queue_free)


func _shade(flash: float, charge: float, dissolve: float) -> void:
	var color: Color = actor.magic_color if actor != null else Color(1, .25, .3)
	# Blood spreads over the body as it is hurt; the dead are soaked.
	var hurt: float = 1.0 - clampf(float(actor.health) / maxf(1.0, actor.max_health), 0.0, 1.0) if actor != null else 0.0
	var gore: float = 1.0 if dying > 0.0 else hurt * .85
	for mesh in meshes:
		mesh.set_instance_shader_parameter("gore", gore)
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


func _scale() -> float:
	if spec.has("scale"):
		return spec.scale
	if not scales.has(kind):
		var bounds_: AABB = AABB()
		var first: bool = true
		for mesh in meshes:
			var box: AABB = model.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
			bounds_ = box if first else bounds_.merge(box)
			first = false
		scales[kind] = spec.height / maxf(bounds_.size.y, .001)
	return scales[kind]
