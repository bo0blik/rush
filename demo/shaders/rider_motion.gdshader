shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;

uniform sampler2D rider_atlas : source_color, filter_nearest_mipmap;
uniform float body_lean = 0.0;
uniform float body_pitch = 0.0;
uniform float wheel_phase = 0.0;
uniform float road_speed = 0.0;
uniform float breathing = 0.0;

void vertex() {
	float angle = -body_lean * 0.29;
	vec2 anchored = VERTEX.xy + vec2(0.0, 1.145);
	VERTEX.xy = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle))) * anchored - vec2(0.0, 1.145);
	// Fixed-Y billboard keeps the sprite facing the chase camera.
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 facing = normalize(vec3(INV_VIEW_MATRIX[2].x, 0.0, INV_VIEW_MATRIX[2].z));
	vec3 right = normalize(cross(up, facing));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right, 0.0), vec4(up, 0.0), vec4(facing, 0.0), MODEL_MATRIX[3]);
}

void fragment() {
	vec2 grid = vec2(4.0, 2.0);
	vec2 cell = floor(UV * grid);
	vec2 local = fract(UV * grid);
	// Leaning is continuous geometry motion; reuse upright art to avoid pose popping.
	if (cell.y > 0.5) {
		cell = vec2(mod(cell.x, 2.0), 0.0);
	}
	vec2 sample_uv = local;
	// Torso weight transfer is stronger at the shoulders than at the seat.
	float torso = (1.0 - smoothstep(0.38, 0.54, local.y)) * smoothstep(0.03, 0.17, local.y);
	sample_uv.x += torso * body_lean * 0.042;
	sample_uv.y += torso * (body_pitch * 0.014 + breathing * 0.002);
	float left_leg = (1.0 - smoothstep(0.31, 0.43, local.x)) * smoothstep(0.47, 0.62, local.y) * (1.0 - smoothstep(0.76, 0.85, local.y));
	float right_leg = smoothstep(0.57, 0.69, local.x) * smoothstep(0.47, 0.62, local.y) * (1.0 - smoothstep(0.76, 0.85, local.y));
	sample_uv.x += left_leg * min(body_lean, 0.0) * 0.024 + right_leg * max(body_lean, 0.0) * 0.024;
	sample_uv.y += (left_leg + right_leg) * body_pitch * 0.007;
	sample_uv.y -= left_leg * (1.0 - smoothstep(0.4, 3.0, road_speed)) * 0.035;
	vec4 texel = texture(rider_atlas, (cell + clamp(sample_uv, vec2(0.002), vec2(0.998))) / grid);
	// Rear-view tire rotation reads as tread moving down the visible tire.
	float wheel = smoothstep(0.72, 0.79, local.y) * (1.0 - smoothstep(0.91, 0.95, local.y));
	wheel *= (1.0 - smoothstep(0.040, 0.072, abs(local.x - 0.5))) * step(road_speed, 100.0) * smoothstep(0.5, 3.0, road_speed);
	float tread = step(0.72, fract(local.y * 45.0 - wheel_phase * 9.0 + abs(local.x - 0.5) * 18.0));
	float dark_rubber = 1.0 - smoothstep(0.12, 0.25, max(texel.r, max(texel.g, texel.b)));
	ALBEDO = mix(texel.rgb, texel.rgb * (0.65 + tread * 0.8), wheel * dark_rubber);
	ALPHA = texel.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 1.0;
}
