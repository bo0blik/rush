shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;
uniform sampler2D atlas : source_color, filter_nearest;
uniform vec4 region;
uniform vec2 atlas_size;
varying vec4 foliage_tint;

void vertex() {
	foliage_tint = COLOR;
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
	vec4 color = texture(atlas, (region.xy + UV * region.zw) / atlas_size);
	ALBEDO = color.rgb * foliage_tint.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 1.0;
}
