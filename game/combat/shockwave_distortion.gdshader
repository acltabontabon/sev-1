shader_type canvas_item;
render_mode unshaded;
// Adapted from mrsir8433's CC0 Distortion/Shockwave Shader (Godot 4.1.1 revision).
// https://godotshaders.com/shader/distortion/
// SEV-1: corrected aspect/UV math, safe center, four bounded pulses, subtle splitting.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec4 waves[4]; // normalized screen center xy, radius in screen widths, strength
uniform int wave_count = 0;
uniform float aberration : hint_range(0.0, 1.0) = 0.035;

void fragment() {
	vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
	vec2 offset = vec2(0.0);
	for (int i = 0; i < 4; i++) {
		if (i >= wave_count) { break; }
		vec2 delta = (SCREEN_UV - waves[i].xy) * aspect;
		float distance_ = length(delta);
		float width = clamp(waves[i].z * 0.06, 0.003, 0.012);
		float feather = width * 1.8;
		float mask = 1.0 - smoothstep(width, width + feather, abs(distance_ - waves[i].z));
		offset += delta / max(distance_, 0.00001) * waves[i].w * mask / aspect;
	}
	// Stacked boss slams never magnify the displacement beyond a few pixels.
	offset *= min(1.0, 0.0045 / max(length(offset), 0.00001));
	vec2 uv = clamp(SCREEN_UV - offset, vec2(0.0), vec2(1.0));
	vec2 split = offset * aberration;
	COLOR = vec4(texture(screen_texture, uv + split).r,
		texture(screen_texture, uv).g, texture(screen_texture, uv - split).b, 1.0);
}
