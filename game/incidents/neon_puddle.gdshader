shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// A soft, broken reflection accent over the wet road. No extra render viewport.
uniform vec4 tint : source_color = vec4(1.0, 0.08, 0.4, 1.0);
uniform float phase = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float ripple = sin(UV.y * 72.0 + phase) * 0.12;
	float width = exp(-pow((p.x + ripple) * 2.8, 2.0));
	float fade = (1.0 - smoothstep(0.45, 1.0, abs(p.y)));
	float breaks = smoothstep(-0.25, 0.8, sin(UV.y * 96.0 + phase));
	ALBEDO = tint.rgb;
	ALPHA = width * fade * breaks * 0.18;
}
