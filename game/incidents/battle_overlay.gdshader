shader_type canvas_item;
// Battle-mode grade over the 3D view (drawn below the HUD): chromatic split and speed
// lines on the onset, a held vignette while the fight lasts.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette = 0.0;
uniform float aberration = 0.0;
uniform float lines = 0.0;
uniform float flash = 0.0;
uniform float seed = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.2, 0.14, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - 0.5;
	float radius = length(centered * vec2(1.7778, 1.0));
	vec2 split = centered * aberration;
	vec3 color = vec3(texture(screen_tex, uv + split).r, texture(screen_tex, uv).g, texture(screen_tex, uv - split).b);
	float edge = smoothstep(0.42, 1.05, radius) * vignette;
	color = mix(color, color * 0.3 + tint.rgb * 0.22, edge);
	float angle = atan(centered.y, centered.x);
	float streak = step(0.86, fract(sin(floor(angle * 46.0) * 91.7 + seed) * 4375.85));
	color += tint.rgb * streak * smoothstep(0.38, 0.95, radius) * lines * 0.7;
	color += vec3(1.0, 0.9, 0.85) * flash;
	COLOR = vec4(color, 1.0);
}
