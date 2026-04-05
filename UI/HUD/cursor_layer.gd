# cursor_layer.gd
extends CanvasLayer

@onready var custom_cursor: TextureRect = $ReloadCursor/CustomCursor
@onready var reload_bar: TextureProgressBar = $ReloadCursor/ReloadBar
@onready var reload_cursor: Control = $ReloadCursor

var _tween: Tween

func _ready() -> void:
	# Hide system cursor since we're replacing it
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	reload_bar.visible = false
	reload_bar.min_value = 0.0
	reload_bar.max_value = 1.0

func _process(_delta: float) -> void:
	# Follow mouse
	reload_cursor.global_position = get_viewport().get_mouse_position()

func show_reload(duration: float) -> void:
	custom_cursor.visible = false
	reload_bar.visible = true
	reload_bar.value = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(reload_bar, "value", 1.0, duration)

func show_cursor() -> void:
	custom_cursor.visible = true
	reload_bar.visible = false
	reload_bar.value = 0.0
	if _tween:
		_tween.kill()
