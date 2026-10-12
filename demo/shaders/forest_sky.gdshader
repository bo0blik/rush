shader_type sky;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float cloud_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 weight = fract(point);
	weight = weight * weight * (3.0 - 2.0 * weight);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), weight.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), weight.x), weight.y);
}

void sky() {
	vec3 ray = normalize(EYEDIR);
	float height = sqrt(clamp(ray.y, 0.0, 1.0));
	vec3 blue = mix(vec3(0.49, 0.72, 0.99), vec3(0.10, 0.38, 0.86), height);
	vec2 plane = ray.xz / max(ray.y, 0.06);
	plane = floor(plane * 10.0) / 10.0;
	float noise = cloud_noise(plane * 0.3) * 0.7 + cloud_noise(plane * 0.85) * 0.3;
	float cloud = step(0.64, noise) * smoothstep(0.06, 0.15, ray.y);
	vec3 white = mix(vec3(0.79, 0.86, 0.96), vec3(0.98, 0.97, 0.90), step(0.7, noise));
	COLOR = mix(blue, white, cloud);
}
