shader_type canvas_item;

uniform sampler2D screen_texture : filter_nearest, repeat_disable;
uniform vec2 resolution = vec2(320.0, 200.0);
uniform float curvature : hint_range(0.0, 0.5, 0.01) = 0.12;
uniform float scanline_intensity : hint_range(0.0, 1.0, 0.01) = 0.28;
uniform float scanline_count : hint_range(80.0, 800.0, 1.0) = 360.0;
uniform float aberration : hint_range(0.0, 6.0, 0.1) = 1.8;
uniform float vignette : hint_range(0.0, 1.0, 0.01) = 0.42;
uniform float brightness : hint_range(0.5, 2.0, 0.01) = 1.12;
uniform float noise_amount : hint_range(0.0, 0.25, 0.01) = 0.04;
uniform float flicker : hint_range(0.0, 0.15, 0.01) = 0.025;
uniform float phosphor_mix : hint_range(0.0, 1.0, 0.01) = 0.72;
uniform vec3 phosphor_color = vec3(0.72, 1.0, 0.62);

vec2 curve_uv(vec2 uv) {
	vec2 centered = uv * 2.0 - 1.0;
	float r2 = dot(centered, centered);
	centered *= 1.0 + curvature * r2;
	return centered * 0.5 + 0.5;
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = curve_uv(UV);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.02, 0.02, 0.03, 1.0);
		return;
	}

	float px = aberration / resolution.x;
	vec3 col;
	col.r = texture(screen_texture, uv + vec2(px, 0.0)).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv - vec2(px, 0.0)).b;

	float scan = sin(uv.y * scanline_count * 3.14159265) * 0.5 + 0.5;
	col *= 1.0 - scanline_intensity * (1.0 - scan);

	vec2 vig_uv = uv * (1.0 - uv);
	float vig = clamp(pow(vig_uv.x * vig_uv.y * 16.0, 0.22), 0.0, 1.0);
	col *= mix(1.0 - vignette, 1.0, vig);

	float n = hash21(uv * resolution + vec2(TIME * 37.0, TIME * 17.0));
	col += (n - 0.5) * noise_amount;
	col *= 1.0 + (n - 0.5) * flicker;

	vec3 tinted = col * phosphor_color * brightness;
	col = mix(col * brightness, tinted, phosphor_mix);

	COLOR = vec4(col, 1.0);
}
