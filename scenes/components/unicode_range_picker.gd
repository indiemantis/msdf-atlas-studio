class_name UnicodeRangePicker
extends VBoxContainer

@onready var chk_ascii: CheckBox = $PresetContainer/ChkAscii
@onready var chk_latin1: CheckBox = $PresetContainer/ChkLatin1
@onready var chk_latin_ext: CheckBox = $PresetContainer/ChkLatinExt
@onready var chk_cyrillic: CheckBox = $PresetContainer/ChkCyrillic
@onready var chk_greek: CheckBox = $PresetContainer/ChkGreek
@onready var custom_from_edit: LineEdit = $CustomRangeContainer/HBox/FromEdit
@onready var custom_to_edit: LineEdit = $CustomRangeContainer/HBox/ToEdit
@onready var add_custom_btn: Button = $CustomRangeContainer/HBox/AddButton
@onready var feedback_label: Label = $CustomRangeContainer/FeedbackLabel
@onready var active_custom_container: VBoxContainer = $ActiveCustomContainer
@onready var active_custom_list: VBoxContainer = $ActiveCustomContainer/ActiveCustomList
@onready var count_label: Label = $CountLabel

var _updating_ui: bool = false
var _custom_ranges: Array[Vector2i] = []

func _ready() -> void:
	chk_ascii.toggled.connect(func(t): if not _updating_ui: _toggle_range(32, 126, t))
	chk_latin1.toggled.connect(func(t): if not _updating_ui: _toggle_range(160, 255, t))
	chk_latin_ext.toggled.connect(func(t): if not _updating_ui: _toggle_range(256, 383, t))
	chk_cyrillic.toggled.connect(func(t): if not _updating_ui: _toggle_range(1024, 1119, t))
	chk_greek.toggled.connect(func(t): if not _updating_ui: _toggle_range(880, 1023, t))
	add_custom_btn.pressed.connect(_on_add_custom_pressed)

	if AppState:
		AppState.codepoints_changed.connect(_on_codepoints_changed)

	_sync_ui_to_codepoints()

func get_custom_ranges() -> Array[Vector2i]:
	return _custom_ranges.duplicate()

func set_custom_ranges(ranges: Array) -> void:
	_custom_ranges.clear()
	for r in ranges:
		if r is Vector2i:
			_custom_ranges.append(r)
		elif r is Array and r.size() >= 2:
			_custom_ranges.append(Vector2i(int(r[0]), int(r[1])))
		elif r is Dictionary:
			_custom_ranges.append(Vector2i(int(r.get("from", 0)), int(r.get("to", 0))))
	_refresh_custom_ranges_ui()
	_update_count()

func _on_codepoints_changed(_cnt: int = 0) -> void:
	_sync_ui_to_codepoints()

func _has_range(start_cp: int, end_cp: int) -> bool:
	if AppState.selected_codepoints.is_empty():
		return false
	var cp_set: Dictionary = {}
	for cp in AppState.selected_codepoints:
		cp_set[cp] = true
	for cp in range(start_cp, end_cp + 1):
		if not cp_set.has(cp):
			return false
	return true

func _sync_ui_to_codepoints() -> void:
	_updating_ui = true
	chk_ascii.button_pressed = _has_range(32, 126)
	chk_latin1.button_pressed = _has_range(160, 255)
	chk_latin_ext.button_pressed = _has_range(256, 383)
	chk_cyrillic.button_pressed = _has_range(1024, 1119)
	chk_greek.button_pressed = _has_range(880, 1023)
	_update_count()
	_updating_ui = false

func _toggle_range(start_cp: int, end_cp: int, enabled: bool) -> void:
	if enabled:
		AppState.add_range(start_cp, end_cp)
	else:
		AppState.remove_range(start_cp, end_cp)
	_update_count()

func _on_add_custom_pressed() -> void:
	var from_str: String = custom_from_edit.text.strip_edges()
	var to_str: String = custom_to_edit.text.strip_edges()
	if from_str.is_empty() or to_str.is_empty():
		_show_feedback("Please specify both From and To codepoints.", Color(1.0, 0.5, 0.4))
		return

	var from_val: int = _parse_codepoint(from_str)
	var to_val: int = _parse_codepoint(to_str)
	if from_val < 0 or to_val < 0:
		_show_feedback("Invalid codepoint. Use hex (e.g. 0x0100) or decimal.", Color(1.0, 0.4, 0.4))
		return
	if to_val < from_val:
		_show_feedback("Error: 'To' must be >= 'From' (%d < %d)." % [to_val, from_val], Color(1.0, 0.4, 0.4))
		return

	var rng := Vector2i(from_val, to_val)
	if rng in _custom_ranges:
		_show_feedback("Range 0x%04X..0x%04X already added." % [from_val, to_val], Color(1.0, 0.8, 0.3))
		return

	var count: int = to_val - from_val + 1
	_custom_ranges.append(rng)
	AppState.add_range(from_val, to_val)
	_show_feedback("✓ Added 0x%04X..0x%04X (%d glyphs)" % [from_val, to_val, count], Color(0.4, 0.9, 0.5))
	custom_from_edit.text = ""
	custom_to_edit.text = ""
	_refresh_custom_ranges_ui()
	_update_count()

func _remove_custom_range(rng: Vector2i) -> void:
	_custom_ranges.erase(rng)
	AppState.remove_range(rng.x, rng.y)
	_show_feedback("Removed 0x%04X..0x%04X" % [rng.x, rng.y], Color(0.8, 0.8, 0.8))
	_refresh_custom_ranges_ui()
	_update_count()

func _refresh_custom_ranges_ui() -> void:
	for c in active_custom_list.get_children():
		c.queue_free()

	active_custom_container.visible = not _custom_ranges.is_empty()

	for rng in _custom_ranges:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.text = "• 0x%04X - 0x%04X (%d glyphs)" % [rng.x, rng.y, rng.y - rng.x + 1]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
		row.add_child(lbl)

		var del_btn := Button.new()
		del_btn.text = "✕"
		del_btn.custom_minimum_size = Vector2(24, 22)
		del_btn.tooltip_text = "Remove range"
		var target_rng: Vector2i = rng
		del_btn.pressed.connect(func(): _remove_custom_range(target_rng))
		row.add_child(del_btn)

		active_custom_list.add_child(row)

func _show_feedback(msg: String, col: Color) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)
	feedback_label.visible = true

func _parse_codepoint(s: String) -> int:
	if s.begins_with("0x") or s.begins_with("0X"):
		return s.hex_to_int()
	elif s.is_valid_int():
		return s.to_int()
	elif s.length() == 1:
		return s.unicode_at(0)
	return -1

func _update_count() -> void:
	count_label.text = "Selected Codepoints: %d" % AppState.selected_codepoints.size()
