shader_type spatial;
render_mode cull_back;
uniform sampler2D source_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool dark_armor = true;

void fragment() {
	vec4 source = texture(source_texture, UV);
	float high = max(source.r, max(source.g, source.b));
	float low = min(source.r, min(source.g, source.b));
	// Neutral atlas ramps belong to steel; the yellow bone and red cloth stay intact.
	float armor = 1.0 - smoothstep(0.045, 0.13, high - low);
	armor *= 1.0 - smoothstep(0.85, 0.97, high);
	if (!dark_armor) { armor = 0.0; }
	ALBEDO = mix(source.rgb, source.rgb * vec3(0.27, 0.31, 0.38), armor);
	ROUGHNESS = mix(0.7, 0.8, armor);
	METALLIC = armor * 0.25;
}
