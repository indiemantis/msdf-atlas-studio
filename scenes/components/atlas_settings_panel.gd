class_name AtlasSettingsPanel
extends VBoxContainer

@onready var field_type_opt: OptionButton = $Grid/FieldTypeOption
@onready var width_opt: OptionButton = $Grid/DimBox/WidthOption
@onready var height_opt: OptionButton = $Grid/DimBox/HeightOption
@onready var auto_size_chk: CheckBox = $Grid/AutoSizeCheck
@onready var px_range_spin: SpinBox = $Grid/PxRangeSpin
@onready var padding_spin: SpinBox = $Grid/PaddingSpin
@onready var angle_spin: SpinBox = $Grid/AngleSpin
@onready var miter_spin: SpinBox = $Grid/MiterSpin
@onready var packing_opt: OptionButton = $Grid/PackingOption

@onready var generate_btn: Button = $ActionContainer/GenerateButton
@onready var cancel_btn: Button = $ActionContainer/CancelButton
@onready var progress_bar: ProgressBar = $ProgressContainer/ProgressBar
@onready var status_label: Label = $ProgressContainer/StatusLabel

func _ready() -> void:
	_populate_options()
	_sync_ui_to_config()

	field_type_opt.item_selected.connect(_on_setting_changed)
	width_opt.item_selected.connect(_on_setting_changed)
	height_opt.item_selected.connect(_on_setting_changed)
	auto_size_chk.toggled.connect(_on_auto_size_toggled)
	px_range_spin.value_changed.connect(_on_setting_changed)
	padding_spin.value_changed.connect(_on_setting_changed)
	angle_spin.value_changed.connect(_on_setting_changed)
	miter_spin.value_changed.connect(_on_setting_changed)
	packing_opt.item_selected.connect(_on_setting_changed)

	generate_btn.pressed.connect(_on_generate_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

	if AppState:
		AppState.generation_started.connect(_on_gen_started)
		AppState.generation_progress.connect(_on_gen_progress)
		AppState.generation_completed.connect(_on_gen_completed)
		AppState.generation_failed.connect(_on_gen_failed)
		AppState.generation_cancelled.connect(_on_gen_cancelled)
		AppState.project_loaded.connect(func(_p): sync_config_to_ui())

func sync_config_to_ui() -> void:
	var cfg = AppState.atlas_config
	var ft = cfg.get("field_type", 2)
	for i in range(field_type_opt.item_count):
		if field_type_opt.get_item_id(i) == ft:
			field_type_opt.select(i)
			break

	var w = cfg.get("texture_width", 1024)
	for i in range(width_opt.item_count):
		if width_opt.get_item_id(i) == w:
			width_opt.select(i)
			break
	var h = cfg.get("texture_height", 1024)
	for i in range(height_opt.item_count):
		if height_opt.get_item_id(i) == h:
			height_opt.select(i)
			break

	auto_size_chk.button_pressed = cfg.get("auto_size", false)
	width_opt.disabled = auto_size_chk.button_pressed
	height_opt.disabled = auto_size_chk.button_pressed

	px_range_spin.value = cfg.get("pixel_range", 4.0)
	padding_spin.value = cfg.get("glyph_padding", 2)
	angle_spin.value = cfg.get("edge_coloring_angle", 3.0)
	miter_spin.value = cfg.get("miter_limit", 1.0)

	var pm = cfg.get("packing_method", 0)
	for i in range(packing_opt.item_count):
		if packing_opt.get_item_id(i) == pm:
			packing_opt.select(i)
			break

func _populate_options() -> void:
	field_type_opt.clear()
	field_type_opt.add_item("SDF (1ch)", 0)
	field_type_opt.add_item("PSDF (1ch)", 1)
	field_type_opt.add_item("MSDF (3ch)", 2)
	field_type_opt.add_item("MTSDF (4ch)", 3)
	field_type_opt.select(2)

	var sizes = [256, 512, 1024, 2048, 4096]
	width_opt.clear()
	height_opt.clear()
	for s in sizes:
		width_opt.add_item(str(s), s)
		height_opt.add_item(str(s), s)
	width_opt.select(2)
	height_opt.select(2)

	packing_opt.clear()
	packing_opt.add_item("MaxRects", 0)
	packing_opt.add_item("Shelf", 1)
	packing_opt.select(0)

func _sync_ui_to_config() -> void:
	var cfg = AppState.atlas_config
	cfg["field_type"] = field_type_opt.get_selected_id()
	cfg["texture_width"] = width_opt.get_selected_id()
	cfg["texture_height"] = height_opt.get_selected_id()
	cfg["auto_size"] = auto_size_chk.button_pressed
	cfg["pixel_range"] = px_range_spin.value
	cfg["glyph_padding"] = int(padding_spin.value)
	cfg["edge_coloring_angle"] = angle_spin.value
	cfg["miter_limit"] = miter_spin.value
	cfg["packing_method"] = packing_opt.get_selected_id()

func _on_setting_changed(_val = null) -> void:
	_sync_ui_to_config()

func _on_auto_size_toggled(pressed: bool) -> void:
	width_opt.disabled = pressed
	height_opt.disabled = pressed
	_sync_ui_to_config()

func _on_generate_pressed() -> void:
	_sync_ui_to_config()
	AppState.start_generation()

func _on_cancel_pressed() -> void:
	AppState.cancel_generation()

func _on_gen_started() -> void:
	generate_btn.disabled = true
	cancel_btn.disabled = false
	progress_bar.value = 0.0
	progress_bar.visible = true
	status_label.text = "Rasterizing glyphs..."

func _on_gen_progress(ratio: float) -> void:
	progress_bar.value = ratio * 100.0
	status_label.text = "Rasterizing: %d%%" % int(ratio * 100.0)

func _on_gen_completed(_img: Image, _meta: Dictionary) -> void:
	generate_btn.disabled = false
	cancel_btn.disabled = true
	progress_bar.value = 100.0
	status_label.text = "Completed in %d ms" % AppState.last_generation_duration_ms

func _on_gen_failed(error_msg: String) -> void:
	generate_btn.disabled = false
	cancel_btn.disabled = true
	status_label.text = "Failed: " + error_msg

func _on_gen_cancelled() -> void:
	generate_btn.disabled = false
	cancel_btn.disabled = true
	progress_bar.value = 0.0
	status_label.text = "Generation cancelled."
