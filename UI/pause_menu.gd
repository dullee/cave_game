extends Control
@onready var resume_button: Button = $VBoxContainer/HBoxContainer/ResumeButton
@onready var pause_label: Label = $VBoxContainer/HBoxContainer/PauseLabel
@onready var options_button: Button = $VBoxContainer/HBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/HBoxContainer/QuitButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.input_disabled.emit()
	resume_button.pressed.connect(_on_resume)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)

func _unhandled_key_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc"):
		_on_resume()

func _on_resume():
	print("resuming")
	SignalBus.input_enabled.emit()
	queue_free()

func _on_options():
	SceneManager.open_settings()

func _on_quit():
	SceneManager.back_to_start_menu()
	queue_free()
