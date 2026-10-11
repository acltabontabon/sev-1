class_name Blood
extends RefCounted
## Blood for sliced enemies: a droplet burst from the cut, a short spurt that follows a
## severed half, and splats on the floor that fade after a while. Visual only. Splats are
## capped (oldest go first) and cleared on restart through the "blood" group.

const COLOR: Color = Color(.68, .008, .025)
const MAX_SPLATS: int = 24
const SPLAT_SECONDS: float = 10.0
static var droplet: QuadMesh
static var splat_textures: Array[ImageTexture] = []
static var wet_texture: ImageTexture
static var splats: Array[Decal] = []


## Build the droplet and the splat shapes ahead of the first cut (a few ms, once).
static func prewarm() -> void:
	if droplet == null:
		droplet = QuadMesh.new()
		droplet.size = Vector2.ONE * .065
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		material.vertex_color_use_as_albedo = true
		var round: GradientTexture2D = GradientTexture2D.new()
		round.fill = GradientTexture2D.FILL_RADIAL
		round.fill_from = Vector2(.5, .5)
		round.fill_to = Vector2(1, .5)
		var falloff: Gradient = Gradient.new()
		falloff.set_color(0, Color(1, 1, 1, 1))
		falloff.set_color(1, Color(1, 1, 1, 0))
		falloff.add_point(.7, Color(1, 1, 1, .95))
		round.gradient = falloff
		material.albedo_texture = round
		droplet.material = material
	if splat_textures.is_empty():
		for seed in [3, 11, 29]:
			splat_textures.append(_splat_texture(seed))
	if wet_texture == null:
		var orm: Image = Image.create(4, 4, false, Image.FORMAT_RGB8)
		orm.fill(Color(1, .2, 0))
		wet_texture = ImageTexture.create_from_image(orm)


static func coating(mesh: MeshInstance3D) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://game/combat/blood_coating.gdshader")
	var extent: Vector3 = mesh.get_aabb().size
	material.set_shader_parameter("stain_scale", 12.0 / maxf(.001, maxf(extent.x, maxf(extent.y, extent.z))))
	return material


## An irregular pool with satellite drops and a few streaks thrown along +X.
static func _splat_texture(seed: int) -> ImageTexture:
	var size: int = 128
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 2.2
	var drops: Array = []
	for index in range(rng.randi_range(9, 15)):
		var angle: float = rng.randf_range(-.9, .9) if index < 5 else rng.randf() * TAU
		var reach: float = rng.randf_range(30.0, 58.0)
		drops.append([Vector2(cos(angle), sin(angle)) * reach, rng.randf_range(2.5, 7.0), 1.0 + (2.2 if index < 5 else 0.0)])
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size, size) * .5
	for y in range(size):
		for x in range(size):
			var offset: Vector2 = Vector2(x, y) - center
			var edge: float = 26.0 + 10.0 * noise.get_noise_1d(offset.angle() * 1.6)
			var alpha: float = clampf((edge - offset.length()) / 3.0, 0.0, 1.0)
			for drop: Array in drops:
				# Streaks are drops stretched along their direction.
				var local: Vector2 = offset - drop[0]
				var along: Vector2 = drop[0].normalized()
				var stretched: Vector2 = Vector2(local.dot(along) / drop[2], local.dot(along.orthogonal()))
				alpha = maxf(alpha, clampf((drop[1] - stretched.length()) / 1.5, 0.0, 1.0))
			if alpha > 0:
				var depth: float = clampf(1.0 - offset.length() / 60.0, 0.0, 1.0)
				image.set_pixel(x, y, Color(1, 1, 1, alpha).darkened(.25 * depth))
	return ImageTexture.create_from_image(image)


static func burst(parent: Node, at: Vector3, direction: Vector3, amount: int = 46) -> void:
	prewarm()
	var particles: CPUParticles3D = _droplets(amount)
	particles.add_to_group("blood")
	particles.one_shot = true
	particles.explosiveness = .9
	particles.direction = direction.normalized()
	parent.add_child(particles)
	particles.global_position = at
	particles.emitting = true
	parent.get_tree().create_timer(1.6, false).timeout.connect(particles.queue_free)


## A spurt from a severed half for `seconds`, trailing as it flies (world-space drops).
static func spurt(follow: Node3D, offset: Vector3, direction: Vector3, seconds: float) -> void:
	prewarm()
	var particles: CPUParticles3D = _droplets(30)
	particles.lifetime = .7
	particles.explosiveness = 0.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 4.0
	particles.spread = 25.0
	particles.direction = direction.normalized()
	follow.add_child(particles)
	particles.position = offset
	particles.emitting = true
	# Held weakly: the follower (and its spurt) may be gone before the timer is.
	var spray: WeakRef = weakref(particles)
	follow.get_tree().create_timer(seconds, false).timeout.connect(func() -> void:
		var still: CPUParticles3D = spray.get_ref() as CPUParticles3D
		if still != null:
			still.emitting = false)


static func _droplets(amount: int) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.name = "Blood"
	particles.mesh = droplet
	particles.amount = amount
	particles.lifetime = .9
	particles.local_coords = false
	particles.spread = 55.0
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 7.0
	particles.gravity = Vector3(0, -16, 0)
	particles.scale_amount_min = .5
	particles.scale_amount_max = 1.5
	particles.color = COLOR
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shrink: Curve = Curve.new()
	shrink.add_point(Vector2(0, 1))
	shrink.add_point(Vector2(1, .4))
	particles.scale_amount_curve = shrink
	return particles


## A pool on the floor under `at`, thrown along `direction`; fades after a while.
static func splat(parent: Node, at: Vector3, direction: Vector3, size: float) -> void:
	prewarm()
	var space: PhysicsDirectSpaceState3D = (parent as Node3D).get_world_3d().direct_space_state
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * .5, at - Vector3.UP * 3.0, 1))
	var ground: Vector3 = hit.position if not hit.is_empty() else Vector3(at.x, at.y, at.z)
	while splats.size() >= MAX_SPLATS:
		var oldest: Decal = splats.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var decal: Decal = Decal.new()
	decal.name = "BloodSplat"
	decal.add_to_group("blood")
	decal.texture_albedo = splat_textures[randi() % splat_textures.size()]
	decal.modulate = Color(.76, .012, .035, .98)
	decal.texture_orm = wet_texture
	decal.size = Vector3(size, .8, size)
	decal.upper_fade = .2
	decal.lower_fade = .2
	decal.cull_mask = 1
	parent.add_child(decal)
	decal.global_position = ground + Vector3.UP * .05
	var flat: Vector2 = Vector2(direction.x, direction.z)
	decal.rotation.y = -flat.angle() + randf_range(-.25, .25) if flat.length() > .01 else randf() * TAU
	splats.append(decal)
	decal.tree_exiting.connect(func() -> void: splats.erase(decal))
	var fade: Tween = decal.create_tween()
	fade.tween_interval(SPLAT_SECONDS)
	fade.tween_property(decal, "modulate:a", 0.0, 2.0)
	fade.tween_callback(decal.queue_free)


static func clear(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("blood"):
		node.queue_free()
	splats.clear()
