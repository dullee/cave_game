extends Control
@onready var master_volume_slider = $VBoxContainer/Volume/VolumeSlider
@onready var resume_button: Button = $ResumeButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var current_volume = settings.master_volume
	
	resume_button.pressed.connect(_on_resume_button_pressed)
	master_volume_slider.value_changed.connect(_on_volume_changed)
	master_volume_slider.value = current_volume
	
func _on_volume_changed(value: float):
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_resume_button_pressed() -> void:
	queue_free()
