shader_type spatial;
render_mode cull_disabled, diffuse_burley;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 pixel = floor(world_position.xz * 3.0);
	float grain = fract(sin(dot(pixel, vec2(12.9898, 78.233))) * 43758.5453);
	float grass = step(COLOR.r * 1.12, COLOR.g) * step(COLOR.b * 1.05, COLOR.g);
	float clump = fract(sin(dot(floor(world_position.xz * 0.6), vec2(43.12, 17.73))) * 9876.21);
	float grass_shade = 0.88 + grain * 0.13 + step(0.70, clump) * 0.13;
	ALBEDO = COLOR.rgb * mix(0.97 + grain * 0.06, grass_shade, grass);
	ROUGHNESS = mix(0.86, 1.0, grass);
	SPECULAR = mix(0.18, 0.0, grass);
}
