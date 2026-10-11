shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// A continuous tapered silhouette: slow bending at the base, smaller licks at the tip.
void fragment() {
	float height = 1.0 - UV.y;
	float bend = sin(TIME * 2.3 - height * 4.0) * 0.10 * height;
	bend += sin(TIME * 3.7 - height * 8.0) * 0.025 * height;
	float x = abs(UV.x - 0.5 - bend);
	float width = 0.30 * pow(max(0.0, 1.0 - height), 0.8);
	width *= 0.92 + 0.08 * sin(TIME * 3.0 - height * 7.0);
	float silhouette = 1.0 - smoothstep(width * 0.45, width, x);
	float root = smoothstep(0.0, 0.08, height);
	float tip = 1.0 - smoothstep(0.80, 1.0, height);
	float core = (1.0 - smoothstep(0.0, width * 0.65, x)) * (1.0 - height);
	vec3 heat = mix(vec3(1.0, 0.10, 0.008), vec3(1.0, 0.72, 0.17), core);
	ALBEDO = heat;
	EMISSION = heat * (1.4 + core);
	ALPHA = silhouette * root * tip * 0.85;
}
