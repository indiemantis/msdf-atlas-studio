class_name SmoothPanZoom
extends Control

signal zoom_changed(zoom_factor: float)
signal pan_changed(pan_offset: Vector2)

@export var target_node: Control
@export var min_zoom: float = 0.05
@export var max_zoom: float = 64.0
@export var zoom_step: float = 1.15
@export var smooth_speed: float = 24.0

var current_zoom: float = 1.0
var target_zoom: float = 1.0
var current_pan: Vector2 = Vector2.ZERO
var target_pan: Vector2 = Vector2.ZERO

var is_panning: bool = false
var pan_drag_start: Vector2 = Vector2.ZERO
var pan_start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	clip_contents = true
	if target_node:
		target_node.pivot_offset = Vector2.ZERO
		center_view()

func _process(delta: float) -> void:
	var t: float = clamp(delta * smooth_speed, 0.0, 1.0)
	current_zoom = lerp(current_zoom, target_zoom, t)
	current_pan = current_pan.lerp(target_pan, t)

	if target_node:
		target_node.scale = Vector2(current_zoom, current_zoom)
		target_node.position = current_pan

func center_view() -> void:
	if not target_node:
		return
	var content_size: Vector2 = target_node.size
	if content_size == Vector2.ZERO:
		content_size = Vector2(512, 512)
	
	target_zoom = 1.0
	current_zoom = 1.0
	target_pan = (size - content_size) * 0.5
	current_pan = target_pan
	zoom_changed.emit(target_zoom)
	pan_changed.emit(target_pan)

func fit_to_view() -> void:
	if not target_node:
		return
	var content_size: Vector2 = target_node.size
	if content_size.x <= 0 or content_size.y <= 0:
		return
	
	var margin: float = 32.0
	var scale_x: float = (size.x - margin * 2.0) / content_size.x
	var scale_y: float = (size.y - margin * 2.0) / content_size.y
	target_zoom = clamp(min(scale_x, scale_y), min_zoom, max_zoom)
	target_pan = (size - content_size * target_zoom) * 0.5
	zoom_changed.emit(target_zoom)
	pan_changed.emit(target_pan)

func set_zoom_level(p_zoom: float) -> void:
	var center: Vector2 = size * 0.5
	_apply_zoom(p_zoom, center)

func _apply_zoom(new_zoom: float, pivot_point: Vector2) -> void:
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	if is_equal_approx(new_zoom, target_zoom):
		return
	var mouse_in_content: Vector2 = (pivot_point - target_pan) / target_zoom
	target_zoom = new_zoom
	target_pan = pivot_point - mouse_in_content * target_zoom
	zoom_changed.emit(target_zoom)
	pan_changed.emit(target_pan)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		var is_inside: bool = get_global_rect().has_point(mb.global_position)

		if mb.button_index == MOUSE_BUTTON_MIDDLE or (mb.button_index == MOUSE_BUTTON_RIGHT and not Input.is_key_pressed(KEY_CTRL)):
			if mb.pressed and is_inside:
				is_panning = true
				pan_drag_start = mb.global_position
				pan_start_pos = target_pan
				get_viewport().set_input_as_handled()
			elif not mb.pressed and is_panning:
				is_panning = false
				get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SPACE):
			if mb.pressed and is_inside:
				is_panning = true
				pan_drag_start = mb.global_position
				pan_start_pos = target_pan
				get_viewport().set_input_as_handled()
			elif not mb.pressed and is_panning:
				is_panning = false
				get_viewport().set_input_as_handled()
		elif (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN) and mb.pressed:
			if is_inside:
				var factor: float = zoom_step
				if mb.ctrl_pressed:
					factor = pow(zoom_step, 2.0)
				var local_pos: Vector2 = mb.global_position - global_position
				if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
					_apply_zoom(target_zoom * factor, local_pos)
				else:
					_apply_zoom(target_zoom / factor, local_pos)
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		if is_panning:
			var mm: InputEventMouseMotion = event as InputEventMouseMotion
			var drag_delta: Vector2 = mm.global_position - pan_drag_start
			target_pan = pan_start_pos + drag_delta
			pan_changed.emit(target_pan)
			get_viewport().set_input_as_handled()

	elif event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if k.pressed and not k.echo and is_visible_in_tree():
			var mouse_pos: Vector2 = get_global_mouse_position()
			if get_global_rect().has_point(mouse_pos):
				if k.keycode == KEY_F:
					fit_to_view()
					get_viewport().set_input_as_handled()
				elif k.keycode == KEY_HOME:
					center_view()
					get_viewport().set_input_as_handled()
