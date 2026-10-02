class_name BMFontExporter
extends RefCounted

static func export_text(path: String, metadata: Dictionary, image_filename: String, font_name: String = "MSDF_Font") -> Error:
	var content: String = generate_text(metadata, image_filename, font_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.close()
	return OK

static func export_xml(path: String, metadata: Dictionary, image_filename: String, font_name: String = "MSDF_Font") -> Error:
	var content: String = generate_xml(metadata, image_filename, font_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.close()
	return OK

static func generate_text(metadata: Dictionary, image_filename: String, font_name: String = "MSDF_Font") -> String:
	var atlas: Dictionary = metadata.get("atlas", {})
	var metrics: Dictionary = metadata.get("metrics", {})
	var glyphs: Array = metadata.get("glyphs", [])
	var kerning: Array = metadata.get("kerning", [])

	var size: float = atlas.get("size", 32.0)
	var width: int = atlas.get("width", 1024)
	var height: int = atlas.get("height", 1024)

	var em_size: float = metrics.get("emSize", 1.0)
	if em_size <= 0.0: em_size = 1.0
	var scale_factor: float = size / em_size

	var ascender: float = metrics.get("ascender", 0.8) * scale_factor
	var line_height: int = int(round(metrics.get("lineHeight", 1.2) * scale_factor))
	var base: int = int(round(ascender))

	var lines: PackedStringArray = []
	lines.append("info face=\"%s\" size=%d bold=0 italic=0 charset=\"\" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1 outline=0" % [font_name, int(round(size))])
	lines.append("common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0" % [line_height, base, width, height])
	lines.append("page id=0 file=\"%s\"" % [image_filename])
	lines.append("chars count=%d" % [glyphs.size()])

	for g in glyphs:
		var unicode: int = g.get("unicode", 0)
		var advance: float = g.get("advance", 0.0) * size
		var ab: Dictionary = g.get("atlasBounds", {})
		var pb: Dictionary = g.get("planeBounds", {})

		var gx: int = 0
		var gy: int = 0
		var gw: int = 0
		var gh: int = 0
		if ab.has("left") and ab.has("right"):
			gx = int(round(ab["left"]))
			gw = int(round(ab["right"] - ab["left"]))
			gh = int(round(ab["top"] - ab["bottom"]))
			gy = height - int(round(ab["top"]))

		var xoffset: int = 0
		var yoffset: int = 0
		if pb.has("left") and pb.has("top"):
			xoffset = int(round(pb["left"] * size))
			yoffset = int(round(ascender - pb["top"] * size))

		lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=%d yoffset=%d xadvance=%d page=0 chnl=15" % [
			unicode, gx, gy, gw, gh, xoffset, yoffset, int(round(advance))
		])

	if not kerning.is_empty():
		lines.append("kernings count=%d" % [kerning.size()])
		for k in kerning:
			var u1: int = k.get("unicode1", 0)
			var u2: int = k.get("unicode2", 0)
			var adv: int = int(round(k.get("advance", 0.0) * size))
			lines.append("kerning first=%d second=%d amount=%d" % [u1, u2, adv])

	return "\n".join(lines) + "\n"

static func generate_xml(metadata: Dictionary, image_filename: String, font_name: String = "MSDF_Font") -> String:
	var atlas: Dictionary = metadata.get("atlas", {})
	var metrics: Dictionary = metadata.get("metrics", {})
	var glyphs: Array = metadata.get("glyphs", [])
	var kerning: Array = metadata.get("kerning", [])

	var size: float = atlas.get("size", 32.0)
	var width: int = atlas.get("width", 1024)
	var height: int = atlas.get("height", 1024)

	var em_size: float = metrics.get("emSize", 1.0)
	if em_size <= 0.0: em_size = 1.0
	var scale_factor: float = size / em_size

	var ascender: float = metrics.get("ascender", 0.8) * scale_factor
	var line_height: int = int(round(metrics.get("lineHeight", 1.2) * scale_factor))
	var base: int = int(round(ascender))

	var xml: PackedStringArray = []
	xml.append("<?xml version=\"1.0\"?>")
	xml.append("<font>")
	xml.append("  <info face=\"%s\" size=\"%d\" bold=\"0\" italic=\"0\" charset=\"\" unicode=\"1\" stretchH=\"100\" smooth=\"1\" aa=\"1\" padding=\"0,0,0,0\" spacing=\"1,1\" outline=\"0\"/>" % [font_name, int(round(size))])
	xml.append("  <common lineHeight=\"%d\" base=\"%d\" scaleW=\"%d\" scaleH=\"%d\" pages=\"1\" packed=\"0\"/>" % [line_height, base, width, height])
	xml.append("  <pages>")
	xml.append("    <page id=\"0\" file=\"%s\"/>" % [image_filename])
	xml.append("  </pages>")
	xml.append("  <chars count=\"%d\">" % [glyphs.size()])

	for g in glyphs:
		var unicode: int = g.get("unicode", 0)
		var advance: float = g.get("advance", 0.0) * size
		var ab: Dictionary = g.get("atlasBounds", {})
		var pb: Dictionary = g.get("planeBounds", {})

		var gx: int = 0
		var gy: int = 0
		var gw: int = 0
		var gh: int = 0
		if ab.has("left") and ab.has("right"):
			gx = int(round(ab["left"]))
			gw = int(round(ab["right"] - ab["left"]))
			gh = int(round(ab["top"] - ab["bottom"]))
			gy = height - int(round(ab["top"]))

		var xoffset: int = 0
		var yoffset: int = 0
		if pb.has("left") and pb.has("top"):
			xoffset = int(round(pb["left"] * size))
			yoffset = int(round(ascender - pb["top"] * size))

		xml.append("    <char id=\"%d\" x=\"%d\" y=\"%d\" width=\"%d\" height=\"%d\" xoffset=\"%d\" yoffset=\"%d\" xadvance=\"%d\" page=\"0\" chnl=\"15\"/>" % [
			unicode, gx, gy, gw, gh, xoffset, yoffset, int(round(advance))
		])

	xml.append("  </chars>")

	if not kerning.is_empty():
		xml.append("  <kernings count=\"%d\">" % [kerning.size()])
		for k in kerning:
			var u1: int = k.get("unicode1", 0)
			var u2: int = k.get("unicode2", 0)
			var adv: int = int(round(k.get("advance", 0.0) * size))
			xml.append("    <kerning first=\"%d\" second=\"%d\" amount=\"%d\"/>" % [u1, u2, adv])
		xml.append("  </kernings>")

	xml.append("</font>")
	return "\n".join(xml) + "\n"
