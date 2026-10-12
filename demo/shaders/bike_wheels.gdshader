shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;
uniform sampler2D source : source_color, filter_nearest_mipmap;
uniform vec2 atlas_size;
uniform vec4 region;
uniform float wheel_phase;
uniform int view = 0;
uniform bool rear_occlusion_only = false;
uniform float seat_cut_y = 0.35;

void fragment() {
	vec2 local = (UV * atlas_size - region.xy) / region.zw;
	if (rear_occlusion_only && local.y < seat_cut_y) {
		discard;
	}
	vec2 point = local;
	float tire = 0.0;
	if (view == 1) {
		for (int i = 0; i < 2; i++) {
			vec2 center = vec2(i == 0 ? 0.21 : 0.79, 0.75);
			vec2 offset = (local - center) * region.zw;
			float radius = region.w * 0.22;
			if (length(offset) < radius) {
				float angle = wheel_phase * 6.283185;
				mat2 rotation = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
				point = center + rotation * offset / region.zw;
			}
		}
	} else {
		tire = step(0.43, local.x) * step(local.x, 0.57) * step(0.74, local.y);
	}
	vec4 color = texture(source, (region.xy + point * region.zw) / atlas_size);
	ALBEDO = color.rgb * (1.0 + tire * sin(local.y * 75.0 - wheel_phase * 25.13274) * 0.12);
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.48;
	ROUGHNESS = 1.0;
}
