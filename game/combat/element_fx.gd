class_name ElementFx
extends Node3D
## Transient elemental and spell effects. Presentation only: nothing here deals damage or
## changes timing. Each effect is a top-level child of its emitter, frees itself, and is
## removed immediately by the emitter's reset through clear_from().

const CIRCLE_SHADER: Shader = preload("res://game/combat/magic_circle.gdshader")
const SMOKE_TEXTURE: Texture2D = preload("res://assets/effects/kenney_smoke/smoke_puff.png")
const GLOW_TEXTURE: Texture2D = preload("res://assets/effects/kenney_particles/soft_glow.png")
const TRACE_TEXTURE: Texture2D = preload("res://assets/effects/kenney_particles/soft_trace.png")
const DISTORTION: Script = preload("res://game/combat/shockwave_distortion.gd")
static var circle_material: ShaderMaterial
static var glow_material: StandardMaterial3D
static var ribbon_material: StandardMaterial3D
static var paper_material: StandardMaterial3D
static var dust_material: StandardMaterial3D
## The latest freeze-frame; only its own timer restores speed, so nested freezes extend.
static var freeze_token: int = 0
static var freeze_until: int = 0
static var freeze_scale: float = 1.0
static var slow_layers: Dictionary[StringName, float] = {}
## Headless suites step frames, so freezes are off there unless a test opts in.
static var freeze_in_headless: bool = false

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
		disc.set_instance_shader_parameter("fade", smoothstep(0.0, .16, t) * (1.0 - smoothstep(.7, 1.0, t)))
		disc.scale = Vector3.ONE * lerpf(.55, 1.0, ease(minf(1.0, t * 5.0), .4))
	return effect


## An expanding ring: impacts, landings, spell releases.
static func shockwave(emitter: Node, at: Vector3, color: Color, radius: float, duration: float = .45, upright: bool = false) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at + Vector3.UP * .05, duration)
	var ring_color: Color = Color(color.lerp(Color(.3, .28, .26), .25), color.a * .6)
	var disc: MeshInstance3D = _disc(effect, radius, ring_color, 1.0)
	if upright:
		disc.rotation.x = PI * .5
	DISTORTION.emit(effect, radius)
	effect.on_tick = func(t: float) -> void:
		disc.scale = Vector3.ONE * lerpf(.1, 1.0, ease(t, .35))
		disc.set_instance_shader_parameter("fade", 1.0 - smoothstep(0.0, 1.0, t))
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
		var edge: Color = Color(color.r, color.g, color.b, .65)
		mesh.surface_set_uv(Vector2(.32, step / 16.0))
		mesh.surface_set_color(edge)
		mesh.surface_add_vertex(Vector3(sin(angle) * 1.25, 0, -cos(angle) * 1.25 + .9))
		mesh.surface_set_uv(Vector2(.68, step / 16.0))
		mesh.surface_set_color(edge)
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
	var axis: Vector3 = to - from
	var side: Vector3 = axis.cross(Vector3.UP).normalized()
	if side.is_zero_approx():
		side = Vector3.RIGHT
	var lift: Vector3 = axis.cross(side).normalized()
	# A few gentle bends, chosen once and drifting slowly: a soft arc, not a zigzag.
	var bends: Array[Vector2] = []
	var drift: Array[Vector2] = []
	for knot in range(3):
		bends.append(Vector2(randf_range(-1, 1), randf_range(-1, 1)) * axis.length() * .07)
		drift.append(Vector2(randf_range(-1, 1), randf_range(-1, 1)) * axis.length() * .05)
	var redraw: Callable = func(t: float) -> void:
		mesh.clear_surfaces()
		var points: PackedVector3Array = PackedVector3Array()
		var taper: PackedFloat32Array = PackedFloat32Array()
		var steps: int = 24
		for step in range(steps + 1):
			var along: float = float(step) / steps
			# Smooth blend of the bends (cosine-weighted), pinned at both ends.
			var offset: Vector2 = Vector2.ZERO
			for knot in range(3):
				var center: float = (knot + 1) / 4.0
				var weight: float = maxf(0.0, cos(clampf((along - center) * 4.0, -1.0, 1.0) * PI * .5))
				offset += (bends[knot] + drift[knot] * t) * weight
			offset *= sin(along * PI)
			points.append(from + axis * along + side * offset.x + lift * offset.y)
			taper.append(pow(sin(along * PI), .45))
		var fade: float = pow(1.0 - t, 1.6)
		var soft: Color = color.lerp(Color(1, 1, 1), .25)
		# Wide haze, coloured body, bright core; every layer feathers to nothing at its edges.
		for layer: Array in [[width * 4.5, Color(color, .22)], [width * 1.8, Color(soft, .55)], [width * .55, Color(1, 1, 1, .85)]]:
			for plane in [side, lift]:
				for edge in [1.0, -1.0]:
					mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _ribbon())
					for index in range(points.size()):
						var half: float = layer[0] * taper[index]
						var tone: Color = layer[1]
						mesh.surface_set_uv(Vector2(.5, float(index) / (points.size() - 1)))
						mesh.surface_set_color(Color(tone.r, tone.g, tone.b, tone.a * fade))
						mesh.surface_add_vertex(points[index])
						mesh.surface_set_uv(Vector2(.68 if edge > 0.0 else .32, float(index) / (points.size() - 1)))
						mesh.surface_set_color(Color(tone.r, tone.g, tone.b, 0.0))
						mesh.surface_add_vertex(points[index] + plane * half * edge)
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


## Freeze-frame: the whole fight stops for a beat on a big impact. Real-time, nests,
## and hands back to whatever slow motion is still running (or normal speed).
static func freeze(emitter: Node, seconds: float, scale: float = .03) -> void:
	if DisplayServer.get_name() == "headless" and not freeze_in_headless:
		return
	var until: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	if until <= freeze_until:
		return
	freeze_until = until
	freeze_token += 1
	freeze_scale = scale
	var token: int = freeze_token
	_apply_time_scale()
	emitter.get_tree().create_timer(seconds, true, false, true).timeout.connect(func() -> void:
		if token == freeze_token:
			freeze_until = 0
			_apply_time_scale())


static func release_freeze() -> void:
	freeze_until = 0
	freeze_token += 1
	_apply_time_scale()


## Named slow motion (kill cam, ultimate, first sighting). The slowest active request
## wins, so one effect ending never snaps another back to full speed. 1.0 releases.
static func slow_motion(key: StringName, scale: float) -> void:
	if scale >= 1.0:
		slow_layers.erase(key)
	else:
		slow_layers[key] = scale
	_apply_time_scale()


static func clear_slow_motion() -> void:
	slow_layers.clear()
	release_freeze()


static func _apply_time_scale() -> void:
	var scale: float = freeze_scale if freeze_until > 0 else 1.0
	for layer: float in slow_layers.values():
		scale = minf(scale, layer)
	Engine.time_scale = scale


## Screen tremor for the engineer's camera, fading with distance from the source.
static func tremor(emitter: Node, at: Vector3, strength: float, radius: float) -> void:
	var player: Node3D = emitter.get_tree().get_first_node_in_group("players") as Node3D
	if player == null or not player.has_node("CameraRig"):
		return
	var falloff: float = 1.0 - clampf(player.global_position.distance_to(at) / radius, 0.0, 1.0)
	if falloff > 0.0:
		player.get_node("CameraRig").add_tremor(strength * falloff)


## Glowing fractures that split across the floor from a point and fade.
static func cracks(emitter: Node, at: Vector3, color: Color, radius: float, count: int = 7, duration: float = 1.4, highlight: float = .35) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at + Vector3.UP * .03, duration)
	var strand: MeshInstance3D = MeshInstance3D.new()
	strand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh: ImmediateMesh = ImmediateMesh.new()
	strand.mesh = mesh
	effect.add_child(strand)
	var paths: Array[PackedVector3Array] = []
	for index in range(count):
		var angle: float = TAU * index / count + randf_range(-.3, .3)
		var reach: float = radius * randf_range(.6, 1.0)
		var points: PackedVector3Array = PackedVector3Array([Vector3.ZERO])
		for step in range(1, 7):
			var bend: float = angle + randf_range(-.35, .35)
			points.append(Vector3(cos(bend), 0, sin(bend)) * reach * step / 6.0)
		paths.append(points)
	effect.on_tick = func(t: float) -> void:
		mesh.clear_surfaces()
		var grow: float = minf(1.0, t * 7.0)
		var alpha: float = 1.0 - smoothstep(.35, 1.0, t)
		for points in paths:
			mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _ribbon())
			var shown: int = maxi(2, int(ceil(points.size() * grow)))
			for index in range(shown):
				var point: Vector3 = points[index]
				var across: Vector3 = point.normalized().cross(Vector3.UP) if point.length() > .01 else Vector3.RIGHT
				var width: float = .09 * (1.0 - float(index) / points.size()) + .015
				mesh.surface_set_uv(Vector2(.32, float(index) / (points.size() - 1)))
				mesh.surface_set_color(Color(color.r, color.g, color.b, alpha))
				mesh.surface_add_vertex(point + across * width)
				mesh.surface_set_uv(Vector2(.68, float(index) / (points.size() - 1)))
				mesh.surface_set_color(Color(color.r, color.g, color.b, alpha).lerp(Color(1, 1, 1, alpha), highlight))
				mesh.surface_add_vertex(point - across * width)
			mesh.surface_end()
	effect.on_tick.call(0.0)
	return effect


## Floor chunks thrown up by an impact.
static func debris(emitter: Node, at: Vector3, amount: int, speed: float, duration: float = 1.1, color: Color = Color(.32, .31, .3)) -> ElementFx:
	var effect: ElementFx = shards(emitter, at + Vector3.UP * .1, color, amount, speed, duration, Vector3.UP, .17)
	var particles: CPUParticles3D = effect.get_child(0) as CPUParticles3D
	var chunk: BoxMesh = particles.mesh as BoxMesh
	chunk.size = Vector3(.17, .12, .14)
	var stone: StandardMaterial3D = StandardMaterial3D.new()
	stone.albedo_color = color
	stone.roughness = 1.0
	chunk.material = stone
	return effect


## Rolling dust that spreads along the floor (alpha-blended, not glowing).
static func dust(emitter: Node, at: Vector3, radius: float, duration: float = 1.2, color: Color = Color(.38, .35, .32)) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at + Vector3.UP * .25, duration)
	if dust_material == null:
		dust_material = StandardMaterial3D.new()
		dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dust_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		dust_material.vertex_color_use_as_albedo = true
		dust_material.albedo_texture = SMOKE_TEXTURE
		dust_material.albedo_color = Color(.62, .59, .55)
		dust_material.roughness = 1.0
		dust_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * .95
	quad.material = dust_material
	var puffs: CPUParticles3D = _particles(26, duration * .9, quad)
	puffs.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	puffs.emission_ring_axis = Vector3.UP
	puffs.emission_ring_radius = radius * .3
	puffs.emission_ring_inner_radius = radius * .15
	puffs.emission_ring_height = .05
	puffs.direction = Vector3.UP
	puffs.spread = 25.0
	puffs.initial_velocity_min = .25
	puffs.initial_velocity_max = .65
	puffs.radial_accel_min = radius * 1.8
	puffs.radial_accel_max = radius * 2.8
	puffs.damping_min = .5
	puffs.damping_max = 1.0
	puffs.gravity = Vector3(0, -.15, 0)
	puffs.angle_min = -180.0
	puffs.angle_max = 180.0
	puffs.angular_velocity_min = -18.0
	puffs.angular_velocity_max = 18.0
	var expansion: Curve = Curve.new()
	expansion.add_point(Vector2(0, .35))
	expansion.add_point(Vector2(.3, .85))
	expansion.add_point(Vector2(1, 1.4))
	puffs.scale_amount_curve = expansion
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(color.r, color.g, color.b, .0))
	ramp.add_point(.08, Color(color.r, color.g, color.b, .5))
	ramp.set_color(1, Color(color.r, color.g, color.b, 0))
	puffs.color_ramp = ramp
	effect.add_child(puffs)
	puffs.emitting = true
	return effect


## The full ground slam: twin shockwaves, cracks, debris, dust, a flash and tremor.
static func quake(emitter: Node, at: Vector3, color: Color, radius: float, strength: float = .8) -> ElementFx:
	var effect: ElementFx = shockwave(emitter, at, color, radius * 2.0, .5)
	var echoed: Array[bool] = [false]
	var first: Callable = effect.on_tick
	effect.on_tick = func(t: float) -> void:
		first.call(t)
		if t > .3 and not echoed[0]:
			echoed[0] = true
			shockwave(emitter, at, Color(color.lerp(Color(.45, .4, .36), .65), .45), radius * 1.4, .4)
	cracks(emitter, at, Color(color * .55, color.a), radius, 7, 1.4, .12)
	debris(emitter, at, int(10 + radius * 4), 3.5 + radius)
	dust(emitter, at, radius)
	flash(emitter, at + Vector3.UP * .6, color, 1.8, radius * 2.0, .2)
	tremor(emitter, at, strength, radius * 4.0)
	return effect


## A crack that races along the floor from one point to another, rocks erupting behind it.
static func fissure(emitter: Node, from: Vector3, to: Vector3, color: Color, duration: float = .9) -> ElementFx:
	var effect: ElementFx = spawn(emitter, Vector3.ZERO, duration)
	effect.global_position = Vector3.ZERO
	var strand: MeshInstance3D = MeshInstance3D.new()
	strand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh: ImmediateMesh = ImmediateMesh.new()
	strand.mesh = mesh
	effect.add_child(strand)
	var start: Vector3 = Vector3(from.x, from.y + .03, from.z)
	var axis: Vector3 = Vector3(to.x - from.x, 0, to.z - from.z)
	var across: Vector3 = axis.normalized().cross(Vector3.UP)
	var points: PackedVector3Array = PackedVector3Array()
	for step in range(13):
		points.append(start + axis * step / 12.0 + across * (randf_range(-.25, .25) if step > 0 else 0.0))
	var erupted: Array[int] = [0]
	effect.on_tick = func(t: float) -> void:
		var front: int = mini(points.size(), int(ceil(points.size() * minf(1.0, t * 3.0))))
		while erupted[0] < front:
			if erupted[0] % 3 == 1:
				debris(emitter, points[erupted[0]], 4, 4.5, .8)
				motes(emitter, points[erupted[0]], color, 5, 3.0, .45, 2.0, .2)
			erupted[0] += 1
		mesh.clear_surfaces()
		if front < 2:
			return
		var alpha: float = 1.0 - smoothstep(.5, 1.0, t)
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _ribbon())
		for index in range(front):
			var width: float = .12 * sin(PI * (index + .5) / points.size()) + .02
			mesh.surface_set_uv(Vector2(.32, float(index) / (points.size() - 1)))
			mesh.surface_set_color(Color(color.r, color.g, color.b, alpha))
			mesh.surface_add_vertex(points[index] + across * width)
			mesh.surface_set_uv(Vector2(.68, float(index) / (points.size() - 1)))
			mesh.surface_set_color(Color(1, 1, 1, alpha * .7))
			mesh.surface_add_vertex(points[index] - across * width)
		mesh.surface_end()
	return effect


## A beam that hangs over a spot, then slams down after `delay` with a small quake.
static func pillar(emitter: Node, at: Vector3, color: Color, radius: float, delay: float) -> ElementFx:
	var effect: ElementFx = spawn(emitter, at, delay + .45)
	var beam: MeshInstance3D = MeshInstance3D.new()
	var tube: CylinderMesh = CylinderMesh.new()
	tube.top_radius = radius
	tube.bottom_radius = radius
	tube.height = 9.0
	tube.cap_top = false
	tube.cap_bottom = false
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(color.r, color.g, color.b, 0)
	tube.material = material
	beam.mesh = tube
	beam.position.y = 4.5
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effect.add_child(beam)
	var landed: Array[bool] = [false]
	var total: float = delay + .45
	effect.on_tick = func(t: float) -> void:
		var time: float = t * total
		if time < delay:
			beam.scale = Vector3(.15 + .1 * sin(time * 30.0), 1, .15 + .1 * sin(time * 30.0))
			material.albedo_color.a = .25 * time / delay
		else:
			if not landed[0]:
				landed[0] = true
				quake(emitter, at, color, radius, .45)
			var after: float = (time - delay) / .45
			beam.scale = Vector3(lerpf(1.0, .1, after), 1, lerpf(1.0, .1, after))
			material.albedo_color.a = .7 * (1.0 - after)
	return effect


static func _disc(effect: ElementFx, radius: float, color: Color, mode: float) -> MeshInstance3D:
	if circle_material == null:
		circle_material = ShaderMaterial.new()
		circle_material.shader = CIRCLE_SHADER
		circle_material.set_shader_parameter("soft_ring", preload("res://assets/effects/kenney_particles/soft_ring.png"))
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
		glow_material = StandardMaterial3D.new()
		glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		glow_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		glow_material.vertex_color_use_as_albedo = true
		glow_material.albedo_texture = GLOW_TEXTURE
		glow_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		glow_material.texture_repeat = false
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
		ribbon_material.albedo_texture = TRACE_TEXTURE
		ribbon_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		ribbon_material.texture_repeat = false
		ribbon_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return ribbon_material


static func _fade_ramp(start: Color, end: Color) -> Gradient:
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(end.r, end.g, end.b, 1))
	ramp.set_color(1, Color(start.r, start.g, start.b, 0))
	ramp.add_point(.2, Color(start.r, start.g, start.b, .75))
	ramp.add_point(.6, Color(start.r, start.g, start.b, .35))
	return ramp


static func _swell_curve() -> Curve:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0, .3))
	curve.add_point(Vector2(.3, 1))
	curve.add_point(Vector2(1, .1))
	return curve
