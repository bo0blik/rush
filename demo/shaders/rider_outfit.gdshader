shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;
uniform sampler2D source : source_color, filter_nearest;
uniform int helmet = 0;
uniform int jacket = 0;
uniform int pants = 0;
uniform int boots = 0;
uniform float boots_start_y = 1.0;

void fragment() {
	vec4 color = texture(source, UV);
	vec3 c = color.rgb;
	float brightness = max(c.r, max(c.g, c.b));
	// Distinct source clothing hues preserve folds and outlines when swapping palettes.
	if (c.r > c.g * 1.7 && c.r > c.b * 1.7 && brightness > 0.045 && helmet == 1) {
		c = vec3(0.82, 0.72, 0.52) * brightness;
	} else if (c.g > c.b * 1.3 && c.r < c.g * 1.4 && brightness > 0.025 && jacket == 1) {
		c = vec3(0.22, 0.43, 0.8) * brightness;
	} else if (c.b > c.r * 1.4 && c.b > c.g * 1.15 && pants == 1) {
		c = vec3(0.55, 0.4, 0.26) * brightness;
	} else if (UV.y > boots_start_y && c.r > c.g * 1.2 && c.g > c.b * 1.2 && c.r < c.g * 2.4 && boots == 1) {
		c = vec3(0.35) * brightness;
	}
	ALBEDO = c;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.48;
	ROUGHNESS = 1.0;
}
