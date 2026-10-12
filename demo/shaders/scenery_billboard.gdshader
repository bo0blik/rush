shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;
uniform sampler2D atlas : source_color, filter_nearest_mipmap;
uniform vec4 region;
uniform vec2 atlas_size;
uniform bool extended_atlas = false;
uniform vec4 plant_regions[16];
varying flat vec4 sprite_region;
varying vec4 foliage_tint;
varying float camera_distance;
uniform float fade_start = 760.0;
uniform float fade_end = 900.0;
uniform float horizon = 0.0;
uniform float wind_strength = 1.0;
uniform bool far_enabled = true;
uniform float far_start = 100.0;
uniform float far_end = 650.0;
uniform float far_bias = 0.0;
uniform float far_contrast = 0.0;
uniform float far_saturation = 0.0;
uniform float far_emission = 0.0;
uniform float far_haze = 0.0;
uniform float far_alpha = 0.5;

void vertex() {
	foliage_tint = COLOR;
	sprite_region = extended_atlas ? plant_regions[clamp(int(floor(INSTANCE_CUSTOM.z / 6.2831853)), 0, 15)] : region;

	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 facing = normalize(vec3(INV_VIEW_MATRIX[2].x, 0.0, INV_VIEW_MATRIX[2].z));
	vec3 right = normalize(cross(up, facing));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right, 0.0), vec4(up, 0.0), vec4(facing, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	VERTEX.x *= INSTANCE_CUSTOM.x;
	VERTEX.y *= INSTANCE_CUSTOM.y;
	camera_distance = length((VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz + right * VERTEX.x + up * VERTEX.y, 1.0)).xyz);
	VERTEX.x += sin(TIME * 1.2 + INSTANCE_CUSTOM.z) * INSTANCE_CUSTOM.w * wind_strength * pow(1.0 - UV.y, 2.0);
}

void fragment() {
	float compensation = far_enabled ? smoothstep(far_start, max(far_start + 1.0, far_end), camera_distance) : 0.0;
	vec2 atlas_uv = (sprite_region.xy + UV * sprite_region.zw) / atlas_size;
	vec4 color = texture(atlas, atlas_uv, -far_bias * compensation);
	// Preserve filtered alpha coverage when selecting a more detailed color mip.
	if (far_bias > 0.001 && compensation > 0.001) color.a = texture(atlas, atlas_uv).a;
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(vec3(luminance), color.rgb, 1.0 + far_saturation * compensation);
	color.rgb = clamp((color.rgb - 0.4) * (1.0 + far_contrast * compensation) + 0.4, vec3(0.0), vec3(1.0));
	float visibility = 1.0 - smoothstep(fade_start, fade_end, camera_distance);
	// Keep fade coverage attached to the sprite rather than the moving screen grid.
	float grain = fract(sin(dot(floor(UV * sprite_region.zw), vec2(12.9898, 78.233))) * 43758.5453);
	if (visibility <= grain) discard;
	vec3 tint = mix(foliage_tint.rgb, vec3(max(foliage_tint.r, max(foliage_tint.g, foliage_tint.b))), far_haze * compensation * horizon);
	ALBEDO = color.rgb * tint;
	float fill = clamp(horizon * (1.0 - far_haze * compensation) + far_emission * compensation, 0.0, 1.0);
	EMISSION = ALBEDO * fill;
	ALBEDO *= 1.0 - fill;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = mix(0.5, far_alpha, compensation);
	ROUGHNESS = 1.0;
}
