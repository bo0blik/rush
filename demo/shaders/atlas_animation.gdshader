shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;

uniform sampler2D atlas : source_color, filter_nearest_mipmap;
uniform sampler2D atlas_b : source_color, filter_nearest_mipmap;
uniform vec2 atlas_size = vec2(1536.0, 1024.0);
uniform vec2 atlas_size_b = vec2(1536.0, 1024.0);
uniform vec4 rect_a;
uniform vec4 rect_b;
uniform vec2 foot_a;
uniform vec2 foot_b;
uniform vec2 quad_size = vec2(2.8, 2.2);
uniform vec2 pixel_scale = vec2(0.01);
uniform vec2 scale_a = vec2(0.01);
uniform vec2 scale_b = vec2(0.01);
uniform float frame_blend = 0.0;
uniform bool mirrored = false;
uniform bool source_flip_a = false;
uniform bool source_flip_b = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform float suspension = 0.0;

void vertex() {
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 facing = normalize(vec3(INV_VIEW_MATRIX[2].x, 0.0, INV_VIEW_MATRIX[2].z));
	vec3 right = normalize(cross(up, facing));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right, 0.0), vec4(up, 0.0), vec4(facing, 0.0), MODEL_MATRIX[3]);
}

vec4 sample_pose(sampler2D source, vec2 size, vec2 point, vec4 region, vec2 foot, vec2 scale, bool source_flip) {
	vec2 pixel = point / scale + foot;
	if (pixel.x < 0.0 || pixel.y < 0.0 || pixel.x >= region.z || pixel.y >= region.w) {
		return vec4(0.0);
	}
	if (source_flip) pixel.x = region.z - pixel.x;
	return texture(source, (region.xy + pixel) / size);
}

void fragment() {
	vec2 point = (UV - vec2(0.5, 1.0)) * quad_size;
	if (mirrored) point.x = -point.x;
	point.y += suspension * smoothstep(0.15, 1.0, -point.y);
	vec4 a = sample_pose(atlas, atlas_size, point, rect_a, foot_a, scale_a, source_flip_a);
	vec4 b = sample_pose(atlas_b, atlas_size_b, point, rect_b, foot_b, scale_b, source_flip_b);
	// Alpha-weighted colors avoid dark fringes while neighboring poses interpolate.
	float alpha = mix(a.a, b.a, frame_blend);
	vec3 color = mix(a.rgb * a.a, b.rgb * b.a, frame_blend) / max(alpha, 0.001);
	ALBEDO = color * tint.rgb;
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = 0.48;
	ROUGHNESS = 1.0;
}
