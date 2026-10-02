class_name AtlasViewport
extends Control

@onready var pan_zoom: SmoothPanZoom = $PanZoomContainer
@onready var content_container: Control = $PanZoomContainer/Content
@onready var atlas_rect: TextureRect = $PanZoomContainer/Content/AtlasTextureRect
@onready var glyph_highlight: Control = $PanZoomContainer/Content/GlyphHighlightOverlay

@onready var btn_r: Button = $Toolbar/ChannelR
@onready var btn_g: Button = $Toolbar/ChannelG
@onready var btn_b: Button = $Toolbar/ChannelB
@onready var btn_a: Button = $Toolbar/ChannelA
@onready var mode_opt: OptionButton = $Toolbar/ModeOption
@onready var zoom_label: Label = $Toolbar/ZoomLabel
@onready var btn_zoom_in: Button = $Toolbar/ZoomIn
@onready var btn_zoom_out: Button = $Toolbar/ZoomOut
@onready var btn_zoom_fit: Button = $Toolbar/ZoomFit
@onready var btn_zoom_reset: Button = $Toolbar/ZoomReset

var inspector_material: ShaderMaterial
var channel_states = { "r": true, "g": true, "b": true, "a": true }
var selected_glyph_rect: Rect2 = Rect2()

func _ready() -> void:
	inspector_material = ShaderMaterial.new()
	inspector_material.shader = load("res://shaders/raw_atlas_inspector.gdshader")
	atlas_rect.material = inspector_material

	_setup_toolbar()
	pan_zoom.zoom_changed.connect(_on_zoom_changed)
	atlas_rect.gui_input.connect(_on_atlas_gui_input)
	glyph_highlight.draw.connect(_on_highlight_draw)

	if AppState:
		AppState.generation_completed.connect(_on_generation_completed)
		AppState.glyph_selected.connect(_on_glyph_selected)
		if AppState.current_texture:
			_on_generation_completed(null, AppState.current_metadata)

func _setup_toolbar() -> void:
	btn_r.toggle_mode = true
	btn_r.button_pressed = true
	btn_g.toggle_mode = true
	btn_g.button_pressed = true
	btn_b.toggle_mode = true
	btn_b.button_pressed = true
	btn_a.toggle_mode = true
	btn_a.button_pressed = true

	btn_r.toggled.connect(func(p): _set_channel("r", p, btn_r))
	btn_g.toggled.connect(func(p): _set_channel("g", p, btn_g))
	btn_b.toggled.connect(func(p): _set_channel("b", p, btn_b))
	btn_a.toggled.connect(func(p): _set_channel("a", p, btn_a))

	mode_opt.clear()
	mode_opt.add_item("Channels Isolation", 0)
	mode_opt.set_item_tooltip(0, "Isolate RGBA color channels")
	mode_opt.add_item("False-Color Vectors", 1)
	mode_opt.set_item_tooltip(1, "Display MSDF RGB channels as false-color vectors")
	mode_opt.add_item("Median Distance Field", 2)
	mode_opt.set_item_tooltip(2, "Compute median distance field in real time")
	mode_opt.add_item("Whitespace Check", 3)
	mode_opt.set_item_tooltip(3, "Highlight whitespace margins in magenta")
	mode_opt.item_selected.connect(_on_mode_selected)

	btn_zoom_in.pressed.connect(func(): pan_zoom.set_zoom_level(pan_zoom.target_zoom * 1.25))
	btn_zoom_out.pressed.connect(func(): pan_zoom.set_zoom_level(pan_zoom.target_zoom / 1.25))
	btn_zoom_fit.pressed.connect(pan_zoom.fit_to_view)
	btn_zoom_reset.pressed.connect(pan_zoom.center_view)

func _set_channel(ch: String, active: bool, btn: Button) -> void:
	channel_states[ch] = active
	btn.modulate = Color.WHITE if active else Color(0.4, 0.4, 0.4, 1.0)
	inspector_material.set_shader_parameter("channel_" + ch, active)

func _on_mode_selected(idx: int) -> void:
	inspector_material.set_shader_parameter("view_mode", idx)

func _on_zoom_changed(z: float) -> void:
	zoom_label.text = "%d%%" % int(round(z * 100.0))

func _on_generation_completed(_image: Image, metadata: Dictionary) -> void:
	if AppState.current_texture:
		atlas_rect.texture = AppState.current_texture
		var w = metadata.get("atlas", {}).get("width", 1024)
		var h = metadata.get("atlas", {}).get("height", 1024)
		content_container.custom_minimum_size = Vector2(w, h)
		content_container.size = Vector2(w, h)
		atlas_rect.custom_minimum_size = Vector2(w, h)
		atlas_rect.size = Vector2(w, h)
		glyph_highlight.size = Vector2(w, h)
		inspector_material.set_shader_parameter("atlas_texture", AppState.current_texture)
		pan_zoom.fit_to_view()

func _on_atlas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = event.position
		_hit_test_glyph(click_pos)

func _hit_test_glyph(pos: Vector2) -> void:
	var metadata = AppState.current_metadata
	var glyphs: Array = metadata.get("glyphs", [])
	var tex_height: float = metadata.get("atlas", {}).get("height", 1024.0)

	for g in glyphs:
		var ab: Dictionary = g.get("atlasBounds", {})
		if ab.has("left") and ab.has("right"):
			var l: float = ab["left"]
			var r: float = ab["right"]
			var b: float = ab["bottom"]
			var t: float = ab["top"]
			# flip vertical axis for top left screen coordinates
			var top_y: float = tex_height - t
			var bot_y: float = tex_height - b

			if pos.x >= l and pos.x <= r and pos.y >= top_y and pos.y <= bot_y:
				selected_glyph_rect = Rect2(l, top_y, r - l, bot_y - top_y)
				glyph_highlight.queue_redraw()
				AppState.select_glyph_by_unicode(g.get("unicode", 0))
				return

	selected_glyph_rect = Rect2()
	glyph_highlight.queue_redraw()

func _on_glyph_selected(g: Dictionary) -> void:
	var tex_height: float = AppState.current_metadata.get("atlas", {}).get("height", 1024.0)
	var ab: Dictionary = g.get("atlasBounds", {})
	if ab.has("left") and ab.has("right"):
		var l: float = ab["left"]
		var r: float = ab["right"]
		var b: float = ab["bottom"]
		var t: float = ab["top"]
		var top_y: float = tex_height - t
		var bot_y: float = tex_height - b
		selected_glyph_rect = Rect2(l, top_y, r - l, bot_y - top_y)
	else:
		selected_glyph_rect = Rect2()
	glyph_highlight.queue_redraw()

func _on_highlight_draw() -> void:
	if selected_glyph_rect.size.x > 0 and selected_glyph_rect.size.y > 0:
		glyph_highlight.draw_rect(selected_glyph_rect, Color(0.0, 0.9, 1.0, 0.15), true)
		glyph_highlight.draw_rect(selected_glyph_rect, Color(0.0, 0.95, 1.0, 0.9), false, 2.0)
