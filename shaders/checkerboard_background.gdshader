shader_type canvas_item;

uniform int bg_mode = 0; // 0: Dark, 1: Light, 2: Checkerboard
uniform vec4 color_dark : source_color = vec4(0.07, 0.07, 0.08, 1.0);
uniform vec4 color_light : source_color = vec4(0.96, 0.96, 0.96, 1.0);
uniform vec4 checker_color1 : source_color = vec4(0.12, 0.12, 0.14, 1.0);
uniform vec4 checker_color2 : source_color = vec4(0.18, 0.18, 0.21, 1.0);
uniform float cell_size = 16.0;

void fragment() {
	if (bg_mode == 0) {
		COLOR = color_dark;
	} else if (bg_mode == 1) {
		COLOR = color_light;
	} else {
		vec2 pos = floor(FRAGCOORD.xy / cell_size);
		float pattern = mod(pos.x + pos.y, 2.0);
		COLOR = mix(checker_color1, checker_color2, pattern);
	}
}
