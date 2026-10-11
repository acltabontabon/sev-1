shader_type canvas_item;
// Light paper-age treatment on the drawing; captions are drawn afterwards.
uniform float memory_time = 0.0;
uniform float dissolve = 0.0;

float grain(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 centred = (UV - .5) * 2.0;
	float edge = smoothstep(.35, 1.3, length(centred));
	vec3 scene = textureLod(TEXTURE, UV, edge * .7).rgb;
	float grey = dot(scene, vec3(.299, .587, .114));
	scene = mix(scene, vec3(grey), .1);
	scene = scene * vec3(1.025, .99, .95) + vec3(.012, .009, .006);
	scene *= 1.0 - edge * .16;
	scene += (grain(FRAGCOORD.xy + floor(memory_time * 12.0)) - .5) * .014;
	COLOR = vec4(mix(scene, vec3(.025, .016, .009), dissolve), 1.0);
}
