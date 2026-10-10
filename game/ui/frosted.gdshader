shader_type canvas_item;
// Frosted glass behind dialogs: blurred, tinted world so text never fights the scene.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur = 3.0;
uniform vec4 tint : source_color = vec4(0.01, 0.015, 0.02, 0.72);

void fragment() {
	vec3 scene = textureLod(screen_tex, SCREEN_UV, blur).rgb;
	COLOR = vec4(mix(scene, tint.rgb, tint.a), 1.0);
}
