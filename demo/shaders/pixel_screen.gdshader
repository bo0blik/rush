shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;
uniform vec2 pixel_grid = vec2(320.0, 240.0);
uniform float speed_amount = 0.0;
uniform float motion_time = 0.0;
uniform float steps = 32.0;
uniform float dither = 0.0;
uniform float contrast = 1.0;
uniform float saturation = 1.0;
uniform float warmth = 0.0;
uniform float outline = 0.0;
uniform float vignette = 0.0;
uniform float stability = 0.55;
uniform float exposure = 1.0;
uniform float gamma = 1.0;
uniform float far_detail = 1.0;
uniform float far_sharpen = 0.0;
uniform float sharpen = 0.0;
uniform float sharpen_limit = 0.05;
uniform float horizon_line = 0.52;
uniform float bloom = 0.0;
uniform float bloom_threshold = 0.75;
uniform float aberration = 0.0;
uniform float scanlines = 0.0;
uniform float grain = 0.0;
uniform float black_lift = 0.0;
uniform float highlight_rolloff = 0.0;

vec3 stable_sample(vec2 uv, vec2 grid) {
	vec3 center = texture(screen_texture, uv).rgb;
	if (stability <= 0.001) return center;
	vec2 radius = 0.38 / grid;
	vec3 filtered = center * 4.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			if (x != 0 || y != 0) filtered += texture(screen_texture, clamp(uv + vec2(float(x), float(y)) * radius, vec2(0.001), vec2(0.999))).rgb;
		}
	}
	return mix(center, filtered / 12.0, stability);
}

void fragment() {
	vec2 cell = floor(SCREEN_UV * pixel_grid);
	vec2 uv = (cell + 0.5) / pixel_grid;
	vec3 color = stable_sample(uv, pixel_grid);
	// This mask denotes the screen horizon band, not scene depth.
	float far_mask = 1.0 - smoothstep(horizon_line - 0.18, horizon_line, SCREEN_UV.y);
	vec2 fine_grid = pixel_grid * far_detail;
	vec2 fine_uv = (floor(SCREEN_UV * fine_grid) + 0.5) / fine_grid;
	if (far_detail > 1.001 && far_mask > 0.001) color = mix(color, stable_sample(fine_uv, fine_grid), far_mask);
	float sharpen_amount = sharpen + far_sharpen * far_mask;
	if (sharpen_amount > 0.001 || bloom > 0.001) {
		vec2 at = mix(uv, fine_uv, far_mask);
		vec2 step_uv = 1.0 / mix(pixel_grid, fine_grid, far_mask);
		vec3 neighbors = (texture(screen_texture, at + vec2(step_uv.x, 0.0)).rgb
			+ texture(screen_texture, at - vec2(step_uv.x, 0.0)).rgb
			+ texture(screen_texture, at + vec2(0.0, step_uv.y)).rgb
			+ texture(screen_texture, at - vec2(0.0, step_uv.y)).rgb) * 0.25;
		color += clamp(color - neighbors, vec3(-sharpen_limit), vec3(sharpen_limit)) * sharpen_amount;
		color += max(neighbors - vec3(bloom_threshold), vec3(0.0)) * bloom;
	}
	// Radial peripheral blur: the rider and the road ahead remain sharp.
	vec2 radial = uv - vec2(0.5, 0.42);
	float edge_blur = smoothstep(0.24, 0.55, length(radial * vec2(1.1, 1.0)));
	vec2 blur_step = radial * speed_amount * edge_blur * 0.045;
	vec3 blurred = color * 0.2;
	for (int sample_index = 1; sample_index <= 4; sample_index++) {
		vec2 sample_uv = uv - blur_step * float(sample_index);
		sample_uv = (floor(sample_uv * pixel_grid) + 0.5) / pixel_grid;
		blurred += texture(screen_texture, clamp(sample_uv, vec2(0.001), vec2(0.999))).rgb * 0.2;
	}
	color = mix(color, blurred, edge_blur * speed_amount);
	if (aberration > 0.001) {
		vec2 shift = radial * aberration * edge_blur / pixel_grid;
		color.r += texture(screen_texture, uv + shift).r - texture(screen_texture, uv).r;
		color.b += texture(screen_texture, uv - shift).b - texture(screen_texture, uv).b;
	}
	// A small ordered dither keeps gradients readable after palette reduction.
	float pattern = mod(cell.x + mod(cell.y, 2.0) * 2.0, 4.0) / 4.0 - 0.375;
	if (outline > 0.0) {
		vec3 neighbor = stable_sample(uv + vec2(1.0, 0.0) / pixel_grid, pixel_grid);
		vec3 below = stable_sample(uv + vec2(0.0, 1.0) / pixel_grid, pixel_grid);
		float difference = max(length(color - neighbor), length(color - below));
		color *= 1.0 - smoothstep(0.14, 0.55, difference) * outline;
	}
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	color *= exposure;
	color = pow(max(color, vec3(0.0)), vec3(1.0 / max(gamma, 0.1)));
	luminance = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(luminance), color, saturation);
	color = (color - 0.5) * contrast + 0.5;
	color += vec3(warmth, warmth * 0.23, -warmth * 0.55) * (0.3 + luminance * 0.7);

	color = mix(color, color / (vec3(1.0) + max(color - vec3(0.6), vec3(0.0))), highlight_rolloff);
	color = mix(color, vec3(1.0), black_lift);
	if (steps > 0.0) {
		color = floor(clamp(color + pattern * dither / steps, 0.0, 1.0) * steps + 0.5) / steps;
	}
	vec2 offset = (uv - vec2(0.5, 0.40)) * vec2(1.3333, 1.0);
	float radius = length(offset);
	float edge = smoothstep(0.30, 0.66, radius);
	// Peripheral streaks leave the rider, traffic ahead and dashboard clear.
	float road_mask = 1.0 - smoothstep(0.73, 0.79, uv.y);
	color *= 1.0 - edge * (speed_amount * 0.10 * road_mask + vignette);
	color *= 1.0 - scanlines * mod(cell.y, 2.0);
	float noise = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	color += noise * grain;
	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
