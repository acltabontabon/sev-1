shader_type spatial;
// Procedural spell circle and shockwave ring for ElementFx. Additive and unshaded; every
// value is per instance, so one material serves every caster.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

instance uniform vec4 tint : source_color = vec4(1.0);
instance uniform float fade = 1.0;
instance uniform float spin = 0.0;
// 0: full sigil (rings, ticks, runes, inner triangle). 1: single soft shockwave ring.
instance uniform float mode = 0.0;
instance uniform float seed = 0.0;

float line(float value, float width) {
	return smoothstep(width, 0.0, abs(value));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float mask;
	if (mode > 0.5) {
		mask = line(r - 0.9, 0.08) + line(r - 0.9, 0.025) * 1.5;
	} else {
		float turn = a + spin;
		float segments = 14.0;
		float ring = line(r - 0.94, 0.022) + line(r - 0.8, 0.016) * 0.8 + line(r - 0.47, 0.014) * 0.7;
		float ticks = step(0.55, fract(turn / TAU * segments * 3.0)) * step(abs(r - 0.87), 0.045);
		float index = floor(fract((a - spin * 0.6) / TAU) * segments);
		float cell = fract(fract((a - spin * 0.6) / TAU) * segments);
		float lit = step(0.35, fract(sin(index * 12.9898 + seed) * 43758.5453));
		float runes = lit * step(0.2, cell) * step(cell, 0.75) * step(abs(r - 0.635), 0.07)
			* step(0.3, fract(r * 40.0 + index));
		float star = 0.0;
		for (int i = 0; i < 3; i++) {
			float angle = -spin * 1.6 + float(i) * TAU / 3.0;
			star += line(dot(p, vec2(cos(angle), sin(angle))) - 0.235, 0.012);
		}
		star *= step(r, 0.47);
		float core = smoothstep(0.5, 0.0, r) * 0.18;
		mask = ring + ticks * 0.7 + runes * 0.9 + star * 0.8 + core;
	}
	mask = clamp(mask, 0.0, 1.0) * step(r, 1.0);
	ALBEDO = tint.rgb * 2.2;
	ALPHA = mask * fade * tint.a;
}
