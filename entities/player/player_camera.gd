# world_camera.gd
extends Camera2D

var target: Node2D = null
var follow_speed := 5.0

var _limit_left := 0
var _limit_right := 0
var _limit_top := -350
var _limit_bottom := 0

@export var zoom_speed := 0.1
@export var min_zoom := 0.5
@export var max_zoom := 3.0

var input_manager: InputManager

func _ready() -> void:
	SignalBus.cave_generated.connect(_set_limits)
	
func _unhandled_input(event: InputEvent) -> void:
	if not SignalBus.is_input_enabled():
		return
	if not target:
		return
	if event.is_action_pressed("mouse_wheel_up"):
		_adjust_zoom(zoom_speed)
	if event.is_action_pressed("mouse_wheel_down"):
		_adjust_zoom(-zoom_speed)
		
func _adjust_zoom(amount: float) -> void:
	var new_zoom = clamp(zoom.x + amount, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
	_clamp_to_limits()  # re-clamp immediately after zoom change

func _set_limits() -> void:
	var cave_gen = get_tree().get_first_node_in_group("cave_generator")
	var tilemap = get_tree().get_first_node_in_group("tilemaplayer")
	if not cave_gen or not tilemap:
		return
	var tile_size = tilemap.tile_set.tile_size.x
	_limit_left = 0
	_limit_right = cave_gen.map_width * tile_size
	_limit_top = -350
	_limit_bottom = cave_gen.map_height * tile_size
	# Set built in limits too
	limit_left = _limit_left
	limit_right = _limit_right
	limit_top = _limit_top
	limit_bottom = _limit_bottom

func set_target(node: Node2D) -> void:
	target = node
	make_current()

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		global_position = global_position.lerp(target.global_position, follow_speed * delta)
	_clamp_to_limits()

func _clamp_to_limits() -> void:
	if _limit_right == 0:
		return
	# Get viewport size adjusted for zoom
	var viewport_size = get_viewport_rect().size / zoom
	var half_w = viewport_size.x * 0.5
	var half_h = viewport_size.y * 0.5
	# Clamp so camera never shows outside bounds
	global_position.x = clamp(global_position.x, _limit_left + half_w, _limit_right - half_w)
	global_position.y = clamp(global_position.y, _limit_top + half_h, _limit_bottom - half_h)
	# Also clamp zoom so it never shows outside bounds at max zoom out
	var max_zoom_x = (_limit_right - _limit_left) / get_viewport_rect().size.x
	var max_zoom_y = (_limit_bottom - _limit_top) / get_viewport_rect().size.y
	min_zoom = min(max_zoom_x, max_zoom_y)
	zoom.x = max(zoom.x, min_zoom)
	zoom.y = max(zoom.y, min_zoom)
