shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;
uniform sampler2D atlas : source_color, filter_nearest;
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

void vertex() {
	foliage_tint = COLOR;
	sprite_region = extended_atlas ? plant_regions[clamp(int(floor(INSTANCE_CUSTOM.z / 6.2831853)), 0, 15)] : region;
	camera_distance = length((VIEW_MATRIX * MODEL_MATRIX[3]).xyz);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 facing = normalize(vec3(INV_VIEW_MATRIX[2].x, 0.0, INV_VIEW_MATRIX[2].z));
	vec3 right = normalize(cross(up, facing));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right, 0.0), vec4(up, 0.0), vec4(facing, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	VERTEX.x *= INSTANCE_CUSTOM.x;
	VERTEX.y *= INSTANCE_CUSTOM.y;
	VERTEX.x += sin(TIME * 1.2 + INSTANCE_CUSTOM.z) * INSTANCE_CUSTOM.w * pow(1.0 - UV.y, 2.0);
}

void fragment() {
	vec4 color = texture(atlas, (sprite_region.xy + UV * sprite_region.zw) / atlas_size);
	float visibility = 1.0 - smoothstep(fade_start, fade_end, camera_distance);
	float grain = fract(sin(dot(floor(FRAGCOORD.xy), vec2(12.9898, 78.233))) * 43758.5453);
	if (visibility <= grain) discard;
	ALBEDO = color.rgb * foliage_tint.rgb;
	EMISSION = ALBEDO * horizon;
	ALBEDO *= 1.0 - horizon;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 1.0;
}
