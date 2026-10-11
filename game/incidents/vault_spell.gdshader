shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// A bright leading edge and a soft copper wake along an authored crescent.
void fragment() {
	float edge = pow(abs(UV.y - 0.5) * 2.0, 4.0);
	float ends = smoothstep(0.0, 0.12, UV.x) * (1.0 - smoothstep(0.82, 1.0, UV.x));
	float pulse = 0.88 + 0.12 * sin(UV.x * 8.0 - TIME * 4.0);
	vec3 heat = mix(vec3(0.48, 0.015, 0.025), vec3(1.0, 0.50, 0.18), edge);
	ALBEDO = heat;
	EMISSION = heat * (1.0 + edge * 2.0);
	ALPHA = ends * pulse * (0.38 + edge * 0.55);
}
