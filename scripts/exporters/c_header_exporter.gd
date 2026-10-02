class_name CHeaderExporter
extends RefCounted

static func export_header(path: String, metadata: Dictionary, font_name: String = "msdf_font") -> Error:
	var content: String = generate_header(metadata, font_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.close()
	return OK

static func generate_header(metadata: Dictionary, font_name: String = "msdf_font") -> String:
	var atlas: Dictionary = metadata.get("atlas", {})
	var metrics: Dictionary = metadata.get("metrics", {})
	var glyphs: Array = metadata.get("glyphs", [])
	var kerning: Array = metadata.get("kerning", [])

	var sanitized_name: String = font_name.to_snake_case().replace(" ", "_")
	var upper_name: String = sanitized_name.to_upper()

	var atlas_w: int = atlas.get("width", 1024)
	var atlas_h: int = atlas.get("height", 1024)
	var inv_w: float = 1.0 / float(atlas_w) if atlas_w > 0 else 0.0
	var inv_h: float = 1.0 / float(atlas_h) if atlas_h > 0 else 0.0

	var out: PackedStringArray = []
	out.append("#ifndef %s_MSDF_FONT_H" % [upper_name])
	out.append("#define %s_MSDF_FONT_H" % [upper_name])
	out.append("")
	out.append("#include <stdint.h>")
	out.append("#include <stddef.h>")
	out.append("")
	out.append("#ifdef __cplusplus")
	out.append("extern \"C\" {")
	out.append("#endif")
	out.append("")
	out.append("typedef struct {")
	out.append("    uint32_t unicode;")
	out.append("    float advance;")
	out.append("    float plane_left, plane_bottom, plane_right, plane_top;")
	out.append("    float uv_left, uv_bottom, uv_right, uv_top;")
	out.append("} MSDFAtlas_Glyph;")
	out.append("")
	out.append("typedef struct {")
	out.append("    uint32_t unicode1;")
	out.append("    uint32_t unicode2;")
	out.append("    float advance;")
	out.append("} MSDFAtlas_Kerning;")
	out.append("")
	out.append("typedef struct {")
	out.append("    const char *type;")
	out.append("    float distance_range;")
	out.append("    float font_size;")
	out.append("    int atlas_width;")
	out.append("    int atlas_height;")
	out.append("    float line_height;")
	out.append("    float ascender;")
	out.append("    float descender;")
	out.append("    size_t glyph_count;")
	out.append("    const MSDFAtlas_Glyph *glyphs;")
	out.append("    size_t kerning_count;")
	out.append("    const MSDFAtlas_Kerning *kerning;")
	out.append("} MSDFAtlas_Font;")
	out.append("")

	out.append("static const MSDFAtlas_Glyph %s_glyphs[%d] = {" % [sanitized_name, glyphs.size()])
	for g in glyphs:
		var u: int = g.get("unicode", 0)
		var adv: float = g.get("advance", 0.0)
		var pb: Dictionary = g.get("planeBounds", {})
		var ab: Dictionary = g.get("atlasBounds", {})

		var pl: float = pb.get("left", 0.0)
		var pbot: float = pb.get("bottom", 0.0)
		var pr: float = pb.get("right", 0.0)
		var pt: float = pb.get("top", 0.0)

		var uv_l: float = ab.get("left", 0.0) * inv_w
		var uv_b: float = ab.get("bottom", 0.0) * inv_h
		var uv_r: float = ab.get("right", 0.0) * inv_w
		var uv_t: float = ab.get("top", 0.0) * inv_h

		out.append("    { 0x%04X, %.6ff, %.6ff, %.6ff, %.6ff, %.6ff, %.6ff, %.6ff, %.6ff, %.6ff }," % [
			u, adv, pl, pbot, pr, pt, uv_l, uv_b, uv_r, uv_t
		])
	out.append("};")
	out.append("")

	out.append("static const MSDFAtlas_Kerning %s_kerning[%d] = {" % [sanitized_name, max(1, kerning.size())])
	if kerning.is_empty():
		out.append("    { 0, 0, 0.0f }")
	else:
		for k in kerning:
			out.append("    { 0x%04X, 0x%04X, %.6ff }," % [k.get("unicode1", 0), k.get("unicode2", 0), k.get("advance", 0.0)])
	out.append("};")
	out.append("")

	out.append("static const MSDFAtlas_Font %s = {" % [sanitized_name])
	out.append("    \"%s\"," % [atlas.get("type", "msdf")])
	out.append("    %.4ff," % [atlas.get("distanceRange", 4.0)])
	out.append("    %.4ff," % [atlas.get("size", 32.0)])
	out.append("    %d," % [atlas_w])
	out.append("    %d," % [atlas_h])
	out.append("    %.4ff," % [metrics.get("lineHeight", 1.2)])
	out.append("    %.4ff," % [metrics.get("ascender", 0.8)])
	out.append("    %.4ff," % [metrics.get("descender", -0.2)])
	out.append("    %d," % [glyphs.size()])
	out.append("    %s_glyphs," % [sanitized_name])
	out.append("    %d," % [kerning.size()])
	out.append("    %s_kerning" % [sanitized_name])
	out.append("};")
	out.append("")
	out.append("#ifdef __cplusplus")
	out.append("}")
	out.append("#endif")
	out.append("")
	out.append("#endif")

	return "\n".join(out) + "\n"

static func export_shader_bundle(base_directory: String) -> Error:
	var dir: DirAccess = DirAccess.open(base_directory)
	if not dir:
		return DirAccess.get_open_error()

	var hlsl_code: String = _get_hlsl_shader()
	var glsl_code: String = _get_glsl_shader()
	var godot_code: String = _get_godot_shader()

	var f: FileAccess = FileAccess.open(base_directory.path_join("msdf.hlsl"), FileAccess.WRITE)
	if f: f.store_string(hlsl_code); f.close()

	f = FileAccess.open(base_directory.path_join("msdf.glsl"), FileAccess.WRITE)
	if f: f.store_string(glsl_code); f.close()

	f = FileAccess.open(base_directory.path_join("msdf.gdshader"), FileAccess.WRITE)
	if f: f.store_string(godot_code); f.close()

	return OK

static func _get_hlsl_shader() -> String:
	return """Texture2D msdfTexture : register(t0);
SamplerState msdfSampler : register(s0);

cbuffer MSDFConstants : register(b0) {
    float4 textColor;
    float4 outlineColor;
    float pxRange;
    float outlineThickness;
    float2 textureSize;
};

float median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

float4 PSMain(float4 position : SV_POSITION, float2 uv : TEXCOORD0) : SV_TARGET {
    float4 tex = msdfTexture.Sample(msdfSampler, uv);
    float sd = median(tex.r, tex.g, tex.b);
    float2 unitRange = float2(pxRange, pxRange) / textureSize;
    float2 screenTexSize = float2(1.0, 1.0) / max(fwidth(uv), float2(0.00001, 0.00001));
    float screenPxRange = max(0.5 * dot(unitRange, screenTexSize), 1.0);
    float screenPxDist = screenPxRange * (sd - 0.5);
    float opacity = saturate(screenPxDist + 0.5);

    float4 outCol = textColor;
    outCol.a *= opacity;
    return outCol;
}
"""

static func _get_glsl_shader() -> String:
	return """#version 300 es
precision highp float;

uniform sampler2D msdfTexture;
uniform vec4 textColor;
uniform vec4 outlineColor;
uniform float pxRange;
uniform float outlineThickness;

in vec2 vUV;
out vec4 fragColor;

float median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

void main() {
    vec4 tex = texture(msdfTexture, vUV);
    float sd = median(tex.r, tex.g, tex.b);
    vec2 texSize = vec2(textureSize(msdfTexture, 0));
    vec2 unitRange = vec2(pxRange) / texSize;
    vec2 screenTexSize = vec2(1.0) / max(fwidth(vUV), vec2(0.00001));
    float screenPxRange = max(0.5 * dot(unitRange, screenTexSize), 1.0);
    float screenPxDist = screenPxRange * (sd - 0.5);
    float opacity = clamp(screenPxDist + 0.5, 0.0, 1.0);

    fragColor = vec4(textColor.rgb, textColor.a * opacity);
}
"""

static func _get_godot_shader() -> String:
	return """shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D msdf_texture : filter_linear;
uniform float px_range = 4.0;
uniform vec4 text_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float get_median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

void fragment() {
    vec4 tex = texture(msdf_texture, UV);
    float sd = get_median(tex.r, tex.g, tex.b);
    vec2 tex_size = vec2(textureSize(msdf_texture, 0));
    vec2 unit_range = vec2(px_range) / tex_size;
    vec2 screen_tex_size = vec2(1.0) / max(fwidth(UV), vec2(0.00001));
    float screen_px_range = max(0.5 * dot(unit_range, screen_tex_size), 1.0);
    float screen_px_dist = screen_px_range * (sd - 0.5);
    float text_alpha = clamp(screen_px_dist + 0.5, 0.0, 1.0);

    COLOR = vec4(text_color.rgb, text_color.a * text_alpha);
}
"""
