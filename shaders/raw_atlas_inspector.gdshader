shader_type canvas_item;

uniform sampler2D atlas_texture : filter_nearest;
uniform bool channel_r = true;
uniform bool channel_g = true;
uniform bool channel_b = true;
uniform bool channel_a = true;
uniform int view_mode : hint_range(0, 3) = 0;
uniform float checker_scale = 32.0;

float get_median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

void fragment() {
    vec4 tex = texture(atlas_texture, UV);

    if (view_mode == 0) {
        vec4 col = vec4(0.0, 0.0, 0.0, 1.0);
        int active_count = (channel_r ? 1 : 0) + (channel_g ? 1 : 0) + (channel_b ? 1 : 0) + (channel_a ? 1 : 0);

        if (active_count == 1) {
            // single selected channels are shown in grayscale for better visibility
            float val = 0.0;
            if (channel_r) val = tex.r;
            else if (channel_g) val = tex.g;
            else if (channel_b) val = tex.b;
            else if (channel_a) val = tex.a;
            col = vec4(val, val, val, 1.0);
        } else if (active_count > 1) {
            col.r = channel_r ? tex.r : 0.0;
            col.g = channel_g ? tex.g : 0.0;
            col.b = channel_b ? tex.b : 0.0;
            col.a = 1.0;
        }
        COLOR = col;
    } else if (view_mode == 1) {
        vec3 normal_vec = normalize(max(tex.rgb * 2.0 - 1.0, vec3(0.0001)));
        COLOR = vec4(normal_vec * 0.5 + 0.5, 1.0);
    } else if (view_mode == 2) {
        float med = get_median(tex.r, tex.g, tex.b);
        COLOR = vec4(vec3(med), 1.0);
    } else if (view_mode == 3) {
        // empty space shows a magenta checker pattern to inspect packing efficiency
        bool is_empty = (tex.r < 0.001 && tex.g < 0.001 && tex.b < 0.001 && tex.a < 0.001);
        if (is_empty) {
            vec2 pos = floor(UV * vec2(textureSize(atlas_texture, 0)) / checker_scale);
            float pattern = mod(pos.x + pos.y, 2.0);
            vec4 magenta1 = vec4(0.9, 0.1, 0.8, 1.0);
            vec4 magenta2 = vec4(0.4, 0.05, 0.4, 1.0);
            COLOR = mix(magenta1, magenta2, pattern);
        } else {
            COLOR = tex;
        }
    }
}
