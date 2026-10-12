shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

void fragment() {
	vec2 point = (UV - vec2(0.5)) * 2.0;
	float soft_edge = 1.0 - smoothstep(0.20, 0.95, length(point));
	float contact = exp(-dot(point * vec2(2.1, 1.45), point * vec2(2.1, 1.45)) * 4.0);
	ALBEDO = vec3(0.045, 0.058, 0.09);
	ALPHA = soft_edge * 0.13 + contact * 0.25;
}
