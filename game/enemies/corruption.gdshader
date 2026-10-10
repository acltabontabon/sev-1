shader_type spatial;
// Incident skin for the CC0 enemy rigs: the original texture under a corrupted-data rim,
// glitch bands that crawl up the body, a hit flash, a telegraph charge and a death
// dissolve. Colour and state are per instance, so each kind shares one material.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform bool use_texture = true;
uniform vec4 base_color : source_color = vec4(1.0);
uniform float metal = 0.35;
instance uniform vec4 glow : source_color = vec4(1.0, 0.25, 0.3, 1.0);
instance uniform float flash = 0.0;
instance uniform float charge = 0.0;
instance uniform float dissolve = 0.0;

varying vec3 world_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = base_color.rgb;
	if (use_texture) {
		base *= texture(albedo_tex, UV).rgb;
	}
	float cell = hash(floor(world_position.xz * 12.0) + floor(world_position.y * 12.0));
	if (cell < dissolve) {
		discard;
	}
	float band_y = fract(world_position.y * 0.55 - TIME * 0.5);
	float band = smoothstep(0.0, 0.015, band_y) * smoothstep(0.05, 0.025, band_y);
	float flicker = step(0.94, hash(vec2(floor(TIME * 14.0), floor(world_position.y * 20.0))));
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.4);
	ALBEDO = mix(base, vec3(1.0), flash);
	ROUGHNESS = 0.55;
	METALLIC = metal;
	vec3 emit = glow.rgb * (rim * (0.35 + charge * 3.0) + band * 1.1 + flicker * 0.2);
	emit += glow.rgb * 4.0 * step(cell, dissolve + 0.06) * step(0.001, dissolve);
	EMISSION = emit + vec3(1.0, 0.95, 0.85) * flash * 1.6;
}
