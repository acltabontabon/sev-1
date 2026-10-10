shader_type spatial;
// Night curtain wall for the office tower and the city around it: a grid of dark glass
// panes in thin frames, every floor banded by a slab, and a scatter of offices where
// somebody is still working. Everything comes from world position, so any box becomes
// a building and no two windows repeat. Roofs stay plain dark.

uniform vec2 cell = vec2(1.6, 3.4);
uniform float lit_chance = 0.05;
uniform vec4 glass: source_color = vec4(0.025, 0.04, 0.06, 1.0);
uniform vec4 frame: source_color = vec4(0.012, 0.013, 0.016, 1.0);
uniform float glow = 1.8;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 facing = abs(world_normal);
	if (facing.y > 0.5) {
		ALBEDO = frame.rgb;
		ROUGHNESS = 0.9;
	} else {
		vec2 uv = facing.x > facing.z ? vec2(world_position.z, world_position.y) : vec2(world_position.x, world_position.y);
		vec2 id = floor(uv / cell);
		vec2 f = fract(uv / cell);
		float mullion = 1.0 - step(0.05, f.x) * step(f.x, 0.95);
		float slab = 1.0 - step(0.1, f.y) * step(f.y, 0.94);
		float framed = max(mullion, slab);
		// Whole bays tend to be lit together: somebody's team is still on call.
		float bay = hash(floor(id / vec2(3.0, 1.0)) + 9.1);
		float lit = step(1.0 - lit_chance, hash(id)) + step(0.988, bay) * step(0.4, hash(id + 2.3));
		lit = min(lit, 1.0);
		vec3 warm = vec3(1.0, 0.74, 0.46);
		vec3 cold = vec3(0.6, 0.8, 1.0);
		vec3 light = mix(warm, cold, step(0.55, hash(id + 7.0))) * (0.3 + 0.55 * hash(id + 3.0));
		// Blinds: a lit pane is often only partly open.
		float blind = step(hash(id + 5.0) * 0.6, f.y - 0.1);
		ALBEDO = mix(glass.rgb, frame.rgb, framed);
		METALLIC = mix(0.55, 0.6, framed);
		ROUGHNESS = mix(0.12, 0.45, framed);
		EMISSION = light * lit * blind * (1.0 - framed) * glow;
	}
}
