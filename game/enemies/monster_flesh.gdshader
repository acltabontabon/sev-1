shader_type spatial;
// Monster skin for the flat-coloured Ultimate Monsters: the base colour turns into grimy,
// mottled flesh with bruising, darker silhouettes, a wet sheen, and blood that spreads
// over the body as it takes damage (`gore`, 0..1, set per instance by monster_rig.gd).
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.3, 0.3, 0.3);
uniform float roughness_base : hint_range(0.0, 1.0) = 0.75;
uniform float metallic_base : hint_range(0.0, 1.0) = 0.0;
uniform float grime : hint_range(0.0, 1.0) = 0.7;
uniform float wet : hint_range(0.0, 1.0) = 0.25;
uniform float detail_scale = 5.0;
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_strength = 0.0;
uniform vec3 blood_color : source_color = vec3(0.66, 0.008, 0.028);
// Slot 4: the overlay pass (corruption.gdshader) uses instance slots 0-3 on the same mesh.
instance uniform float gore : instance_index(4) = 0.0;

varying vec3 local_position;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int octave = 0; octave < 4; octave++) {
		value += amplitude * noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec3 p = local_position * detail_scale;
	float mottle = fbm(p);
	float bruise = smoothstep(0.48, 0.78, fbm(p * 0.45 + 7.3));
	vec3 color = base_color * mix(1.0 - grime * 0.5, 1.0 + grime * 0.12, mottle);
	color = mix(color, color * vec3(0.5, 0.38, 0.4), bruise * grime * 0.7);
	// Blood soaks in from many small patches as the body takes damage.
	float soak = fbm(p * 0.8 + 19.0);
	float blood = smoothstep(0.72 - gore * 0.4, 0.76 - gore * 0.4, soak) * step(0.001, gore);
	color = mix(color, blood_color * (0.78 + mottle * 0.32), blood);
	// Silhouettes sink into shadow; no rim light, no neon.
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	color *= 1.0 - edge * 0.4;
	ALBEDO = color;
	ROUGHNESS = clamp(mix(roughness_base, 0.18, max(blood * 0.9, wet * mottle)), 0.05, 1.0);
	METALLIC = metallic_base;
	SPECULAR = 0.5 + blood * 0.25;
	EMISSION = emission_color * emission_strength;
}
