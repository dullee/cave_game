# input_component.gd
extends Node
class_name InputManager

var _enabled := true

func _ready() -> void:
	SignalBus.input_disabled.connect(func(): _enabled = false)
	SignalBus.input_enabled.connect(func(): _enabled = true)

func is_enabled() -> bool:
	return SignalBus.is_input_enabled() and get_parent().is_multiplayer_authority()

func is_action_pressed(action: StringName) -> bool:
	return _enabled and Input.is_action_pressed(action)

func is_action_just_pressed(action: StringName) -> bool:
	return _enabled and Input.is_action_just_pressed(action)

func is_action_just_released(action: StringName) -> bool:
	return _enabled and Input.is_action_just_released(action)

func get_axis(negative: StringName, positive: StringName) -> float:
	return Input.get_axis(negative, positive) if _enabled else 0.0
