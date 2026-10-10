shader_type spatial;
// Additive overlay pass on each monster's skin (next_pass). Nothing at rest: a charge in
// the archetype's colour while an attack winds up (the tell), a white hit flash, and a
// dull ember while the corpse dissolves.
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

instance uniform vec4 glow : source_color = vec4(1.0, 0.25, 0.3, 1.0);
instance uniform float flash = 0.0;
instance uniform float charge = 0.0;
instance uniform float dissolve = 0.0;

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 color = glow.rgb * rim * charge * 2.4 + vec3(0.5, 0.08, 0.03) * rim * dissolve * 2.0;
	color += glow.rgb * charge * 0.18;
	color += vec3(1.0, 0.96, 0.9) * flash * 0.85;
	ALBEDO = color;
}
