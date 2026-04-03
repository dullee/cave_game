# damage_number.gd
extends Node2D

@onready var label: Label = $Label

func setup(amount: int, color: Color = Color.WHITE) -> void:
	label.text = str(amount)
	label.modulate = color
	# Float up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y - 40.0, 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free).set_delay(0.8)
