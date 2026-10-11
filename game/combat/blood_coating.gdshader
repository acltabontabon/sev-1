shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;
// Original procedural blood: anchored to the mesh so stains follow the animated body.
uniform vec3 fresh_color : source_color = vec3(0.72, 0.012, 0.035);
uniform vec3 pooled_color : source_color = vec3(0.38, 0.004, 0.018);
uniform float stain_scale = 8.0;
varying vec3 stain_position;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x),
		mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
		mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	stain_position = VERTEX;
}

void fragment() {
	vec3 p = stain_position * stain_scale;
	float splash = noise(p + 19.0);
	float specks = smoothstep(0.76, 0.82, noise(p * 4.0));
	float runs = smoothstep(0.64, 0.73, noise(p * vec3(2.5, 0.16, 2.5) + 7.0));
	float mask = max(smoothstep(0.49, 0.57, splash), max(specks, runs * smoothstep(0.3, 0.5, splash)));
	float thickness = smoothstep(0.56, 0.85, splash);
	ALBEDO = mix(fresh_color, pooled_color, thickness * 0.7);
	ALPHA = mask * 0.94;
	ROUGHNESS = mix(0.28, 0.16, thickness);
	METALLIC = 0.0;
	SPECULAR = 0.65;
}
