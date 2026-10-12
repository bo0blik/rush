shader_type spatial;
render_mode cull_disabled, specular_disabled;

void fragment() {
	float ripple = sin(UV.y * 5.0 - TIME * 1.0 + sin(UV.x * 5.0)) * 0.5 + 0.5;
	float glint = step(0.95, ripple) * step(0.7, sin(UV.y * 13.0 + UV.x * 16.0));
	ALBEDO = mix(vec3(0.07, 0.32, 0.59), vec3(0.15, 0.48, 0.75), floor(ripple * 4.0) / 4.0);
	ALBEDO += vec3(0.22, 0.27, 0.24) * glint;
	ROUGHNESS = 0.85;
}
