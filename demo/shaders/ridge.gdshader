shader_type spatial;
render_mode unshaded, cull_disabled;

varying vec3 world_point;

void vertex() {
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 pixel = floor(vec2(atan(world_point.z, world_point.x) * 220.0, world_point.y * 0.5));
	float grain = fract(sin(dot(pixel, vec2(19.13, 63.27))) * 7345.28);
	float crag = sin(pixel.x * 0.24 + pixel.y * 0.16) + sin(pixel.x * 0.41 - pixel.y * 0.27);
	float detail = 0.90 + step(0.9, crag) * 0.15 + grain * 0.05;
	ALBEDO = COLOR.rgb * detail;
}
