class_name ElementFx
extends Node3D
## Transient elemental and spell effects. Presentation only: nothing here deals damage or
## changes timing. Each effect is a top-level child of its emitter, frees itself, and is
## removed immediately by the emitter's reset through clear_from().

const CIRCLE_SHADER: Shader = preload("res://game/combat/magic_circle.gdshader")
static var circle_material: ShaderMaterial
static var glow_material: StandardMaterial3D
static var ribbon_material: StandardMaterial3D
static var paper_material: StandardMaterial3D
static var soft_dot: GradientTexture2D

var life: float = 1.0
var age: float = 0.0
## Called every frame with progress 0..1.
var on_tick: Callable


func _process(delta: float) -> void:
	age += delta
	if on_tick.is_valid():
		on_tick.call(minf(1.0, age / life))
	if age >= life:
		queue_free()


static func clear_from(emitter: Node) -> void:
	var effects: Array[Node] = []
	for child in emitter.get_children():
		if child is ElementFx:
			effects.append(child)
	for effect in effects:
		emitter.remove_child(effect)
		effect.free()


static func spawn(emitter: Node, at: Vector3, duration: float) -> ElementFx:
	var effect: ElementFx = ElementFx.new()
	effect.top_level = true
	effect.life = duration
	emitter.add_child(effect)
	effect.global_position = at
	return effect


## A spinning spell circle on the floor. Reads as "something is being cast here".
static func sigil(emitter: Node, at: Vector3, color: Color, radius: float, duration: float, spin_rate: float = 1.4) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at + Vector3.UP * .04, duration)
	var disc: MeshInstance3D = _disc(effect, radius, color, 0.0)
	disc.set_instance_shader_parameter("seed", randf() * 100.0)
	effect.on_tick = func(t: float) -> void:
		disc.set_instance_shader_parameter("spin", t * duration * spin_rate)
		disc.set_instance_shader_parameter("fade", minf(1.0, t * 6.0) * minf(1.0, (1.0 - t) * 4.0))
		disc.scale = Vector3.ONE * lerpf(.55, 1.0, ease(minf(1.0, t * 5.0), .4))
	return effect


## An expanding ring: impacts, landings, spell releases.
static func shockwave(emitter: Node, at: Vector3, color: Color, radius: float, duration: float = .45, upright: bool = false) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at + Vector3.UP * .05, duration)
	var disc: MeshInstance3D = _disc(effect, radius, color, 1.0)
	if upright:
		disc.rotation.x = PI * .5
	effect.on_tick = func(t: float) -> void:
		disc.scale = Vector3.ONE * lerpf(.1, 1.0, ease(t, .35))
		disc.set_instance_shader_parameter("fade", 1.0 - t)
	return effect


## One-shot burst of soft glowing motes.
static func motes(emitter: Node, at: Vector3, color: Color, amount: int, speed: float, duration: float, gravity: float = 0.0, size: float = .14, direction: Vector3 = Vector3.UP, spread: float = 180.0) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at, duration)
	var particles: CPUParticles3D = _particles(amount, duration * .85, _dot_mesh(size))
	particles.direction = direction
	particles.spread = spread
	particles.initial_velocity_min = speed * .5
	particles.initial_velocity_max = speed
	particles.gravity = Vector3(0, gravity, 0)
	particles.damping_min = speed * .6
	particles.damping_max = speed * 1.2
	particles.color_ramp = _fade_ramp(color, color.lerp(Color.WHITE, .5))
	effect.add_child(particles)
	particles.emitting = true
	return effect


## Square paper or data shards that tumble and fall.
static func shards(emitter: Node, at: Vector3, color: Color, amount: int, speed: float, duration: float, direction: Vector3 = Vector3.UP, size: float = .09) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at, duration)
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(size, size, size * .15)
	if paper_material == null:
		paper_material = StandardMaterial3D.new()
		paper_material.vertex_color_use_as_albedo = true
		paper_material.emission_enabled = true
		paper_material.emission_energy_multiplier = .6
		paper_material.roughness = .8
	box.material = paper_material
	var particles: CPUParticles3D = _particles(amount, duration * .9, box)
	particles.direction = direction
	particles.spread = 55.0
	particles.initial_velocity_min = speed * .5
	particles.initial_velocity_max = speed
	particles.gravity = Vector3(0, -7.0, 0)
	particles.angular_velocity_min = -540.0
	particles.angular_velocity_max = 540.0
	particles.particle_flag_rotate_y = true
	particles.color = color
	effect.add_child(particles)
	particles.emitting = true
	return effect


## Floating words that rise and fade: glitches, calendar slots, sticky-note demands.
static func glyphs(emitter: Node, at: Vector3, color: Color, words: Array, duration: float = 1.0, spread: float = .7) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at, duration)
	var labels: Array[Label3D] = []
	var drift: Array[Vector3] = []
	for word in words:
		var label: Label3D = Label3D.new()
		label.text = str(word)
		label.font_size = 40
		label.pixel_size = .0042
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.modulate = color
		label.outline_modulate = Color(0, 0, 0, .8)
		label.outline_size = 10
		label.position = Vector3(randf_range(-spread, spread), randf_range(0, .4), randf_range(-spread, spread) * .4)
		effect.add_child(label)
		labels.append(label)
		drift.append(Vector3(randf_range(-.3, .3), randf_range(.7, 1.3), 0))
	effect.on_tick = func(t: float) -> void:
		for index in range(labels.size()):
			labels[index].position += drift[index] * .016
			labels[index].modulate.a = color.a * minf(1.0, (1.0 - t) * 3.0)
			labels[index].scale = Vector3.ONE * lerpf(.6, 1.0, minf(1.0, t * 6.0))
	return effect


## A short-lived light pulse.
static func flash(emitter: Node, at: Vector3, color: Color, energy: float = 3.0, radius: float = 5.0, duration: float = .25) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at, duration)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = color
	light.omni_range = radius
	light.light_energy = energy
	light.shadow_enabled = false
	effect.add_child(light)
	effect.on_tick = func(t: float) -> void:
		light.light_energy = energy * (1.0 - t) * (1.0 - t)
	return effect


## Wind: a crescent of air flung forward along `basis` -Z, trailing streaks.
static func gust(emitter: Node, at: Vector3, basis: Basis, color: Color, distance: float = 4.0, duration: float = .38) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at, duration)
	effect.global_basis = basis.orthonormalized()
	var crescent: MeshInstance3D = MeshInstance3D.new()
	crescent.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh: ImmediateMesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _ribbon())
	for step in range(17):
		var angle: float = lerpf(-1.25, 1.25, step / 16.0)
		var width: float = sin(step / 16.0 * PI) * .32
		var edge: Color = Color(color.r, color.g, color.b, 0.0)
		mesh.surface_set_color(edge)
		mesh.surface_add_vertex(Vector3(sin(angle) * 1.25, 0, -cos(angle) * 1.25 + .9))
		mesh.surface_set_color(Color(color.r, color.g, color.b, .9))
		mesh.surface_add_vertex(Vector3(sin(angle) * (1.25 - width), 0, -cos(angle) * (1.25 - width) + .9))
	mesh.surface_end()
	crescent.mesh = mesh
	effect.add_child(crescent)
	var streaks: CPUParticles3D = _particles(14, duration, _dot_mesh(.07))
	streaks.direction = Vector3.FORWARD
	streaks.spread = 30.0
	streaks.initial_velocity_min = 7.0
	streaks.initial_velocity_max = 11.0
	streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	streaks.emission_box_extents = Vector3(.9, .4, .1)
	streaks.color_ramp = _fade_ramp(color, Color.WHITE)
	effect.add_child(streaks)
	streaks.emitting = true
	effect.on_tick = func(t: float) -> void:
		crescent.position = Vector3(0, 0, -distance * ease(t, .5))
		crescent.scale = Vector3(lerpf(.7, 1.5, t), 1, lerpf(.7, 1.2, t))
		crescent.transparency = t * t
	return effect


## Lightning: a jagged bolt that re-forks every frame for its brief life.
static func bolt(emitter: Node, from: Vector3, to: Vector3, color: Color, duration: float = .2, width: float = .04) -> ElementFx:
	var effect: ElementFx = spawn(emitter, Vector3.ZERO, duration)
	effect.global_position = Vector3.ZERO
	var strand: MeshInstance3D = MeshInstance3D.new()
	strand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh: ImmediateMesh = ImmediateMesh.new()
	strand.mesh = mesh
	effect.add_child(strand)
	var redraw: Callable = func(t: float) -> void:
		mesh.clear_surfaces()
		var axis: Vector3 = to - from
		var side: Vector3 = axis.cross(Vector3.UP).normalized()
		if side.is_zero_approx():
			side = Vector3.RIGHT
		var lift: Vector3 = axis.cross(side).normalized()
		var points: PackedVector3Array = PackedVector3Array()
		for step in range(9):
			var along: float = step / 8.0
			var jitter: float = sin(along * PI) * axis.length() * .12
			points.append(from + axis * along + side * randf_range(-jitter, jitter) + lift * randf_range(-jitter, jitter))
		var alpha: float = (1.0 - t) * (.6 + randf() * .4)
		for plane in [side, lift]:
			mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _ribbon())
			for point in points:
				mesh.surface_set_color(Color(1, 1, 1, alpha * .8))
				mesh.surface_add_vertex(point + plane * width * .35)
				mesh.surface_set_color(Color(color.r, color.g, color.b, alpha))
				mesh.surface_add_vertex(point - plane * width)
			mesh.surface_end()
	redraw.call(0.0)
	effect.on_tick = redraw
	return effect


## Fire: a ring of flame that leaps outward from the caster, embers and heat light.
static func flame_ring(emitter: Node, at: Vector3, radius: float, duration: float = .7) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at + Vector3.UP * .05, duration)
	var flames: CPUParticles3D = _particles(60, duration * .7, _dot_mesh(.32))
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	flames.emission_ring_axis = Vector3.UP
	flames.emission_ring_radius = radius * .35
	flames.emission_ring_inner_radius = radius * .25
	flames.emission_ring_height = .05
	flames.direction = Vector3.UP
	flames.spread = 25.0
	flames.initial_velocity_min = 1.5
	flames.initial_velocity_max = 3.5
	flames.radial_accel_min = 9.0
	flames.radial_accel_max = 14.0
	flames.gravity = Vector3(0, 2.0, 0)
	flames.scale_amount_curve = _swell_curve()
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(1, .95, .6, 1))
	ramp.set_color(1, Color(.8, .1, .02, 0))
	ramp.add_point(.35, Color(1, .55, .12, .95))
	flames.color_ramp = ramp
	effect.add_child(flames)
	flames.emitting = true
	motes(emitter, at + Vector3.UP * .4, Color(1, .6, .2), 26, 6.0, duration * 1.4, 3.0, .07)
	shockwave(emitter, at, Color(1, .5, .15), radius * 2.0, duration * .7)
	flash(emitter, at + Vector3.UP, Color(1, .55, .2), 5.0, radius * 3.0, duration * .6)
	return effect


static func _disc(effect: ElementFx, radius: float, color: Color, mode: float) -> MeshInstance3D:
	if circle_material == null:
		circle_material = ShaderMaterial.new()
		circle_material.shader = CIRCLE_SHADER
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2.ONE * radius * 2.0
	var disc: MeshInstance3D = MeshInstance3D.new()
	disc.mesh = plane
	disc.material_override = circle_material
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effect.add_child(disc)
	disc.set_instance_shader_parameter("tint", color)
	disc.set_instance_shader_parameter("mode", mode)
	disc.set_instance_shader_parameter("fade", 0.0)
	return disc


static func _particles(amount: int, lifetime: float, mesh: Mesh) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = .92
	particles.amount = maxi(1, amount)
	particles.lifetime = maxf(.05, lifetime)
	particles.mesh = mesh
	particles.local_coords = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.scale_amount_min = .6
	particles.scale_amount_max = 1.2
	return particles


static func _dot_mesh(size: float) -> QuadMesh:
	if glow_material == null:
		soft_dot = GradientTexture2D.new()
		soft_dot.fill = GradientTexture2D.FILL_RADIAL
		soft_dot.fill_from = Vector2(.5, .5)
		soft_dot.fill_to = Vector2(1, .5)
		soft_dot.width = 64
		soft_dot.height = 64
		var falloff: Gradient = Gradient.new()
		falloff.set_color(0, Color(1, 1, 1, 1))
		falloff.set_color(1, Color(1, 1, 1, 0))
		soft_dot.gradient = falloff
		glow_material = StandardMaterial3D.new()
		glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		glow_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		glow_material.vertex_color_use_as_albedo = true
		glow_material.albedo_texture = soft_dot
		glow_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * size
	quad.material = glow_material
	return quad


static func _ribbon() -> StandardMaterial3D:
	if ribbon_material == null:
		ribbon_material = StandardMaterial3D.new()
		ribbon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ribbon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ribbon_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		ribbon_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		ribbon_material.vertex_color_use_as_albedo = true
		ribbon_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return ribbon_material


static func _fade_ramp(start: Color, end: Color) -> Gradient:
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(end.r, end.g, end.b, 1))
	ramp.set_color(1, Color(start.r, start.g, start.b, 0))
	ramp.add_point(.3, Color(start.r, start.g, start.b, .9))
	return ramp


static func _swell_curve() -> Curve:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0, .3))
	curve.add_point(Vector2(.3, 1))
	curve.add_point(Vector2(1, .1))
	return curve
