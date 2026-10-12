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

void fragment() {
	vec2 cell = floor(SCREEN_UV * pixel_grid);
	vec2 uv = (cell + 0.5) / pixel_grid;
	vec3 color = texture(screen_texture, uv).rgb;
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
	// A small ordered dither keeps gradients readable after palette reduction.
	float pattern = mod(cell.x + mod(cell.y, 2.0) * 2.0, 4.0) / 4.0 - 0.375;
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(luminance), color, saturation);
	color = (color - 0.5) * contrast + 0.5;
	color += vec3(warmth, warmth * 0.23, -warmth * 0.55) * (0.3 + luminance * 0.7);
	if (outline > 0.0) {
		vec3 neighbor = texture(screen_texture, uv + vec2(1.0, 0.0) / pixel_grid).rgb;
		vec3 below = texture(screen_texture, uv + vec2(0.0, 1.0) / pixel_grid).rgb;
		float difference = max(length(color - neighbor), length(color - below));
		color *= 1.0 - smoothstep(0.14, 0.55, difference) * outline;
	}
	if (steps > 0.0) {
		color = floor(clamp(color + pattern * dither / steps, 0.0, 1.0) * steps + 0.5) / steps;
	}
	vec2 offset = (uv - vec2(0.5, 0.40)) * vec2(1.3333, 1.0);
	float radius = length(offset);
	float edge = smoothstep(0.30, 0.66, radius);
	// Peripheral streaks leave the rider, traffic ahead and dashboard clear.
	float road_mask = 1.0 - smoothstep(0.73, 0.79, uv.y);
	color *= 1.0 - edge * (speed_amount * 0.10 * road_mask + vignette);
	COLOR = vec4(color, 1.0);
}
