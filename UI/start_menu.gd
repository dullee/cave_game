extends Control

@onready var singleplayer_button: Button = $VBoxContainer/SingleplayerButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

const _IP = "192.168.1.2"

func _ready() -> void:
	GameManager.cleanup()  # clean up any existing peer
	_setup_buttons()

func _setup_buttons() -> void:
	singleplayer_button.pressed.connect(_on_singleplayer_pressed)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	options_button.pressed.connect(_on_options)
	exit_button.pressed.connect(_on_exit)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
	# On web, replace host/join with single WebRTC button
	if OS.get_name() == "Web":
		host_button.visible = false
		join_button.visible = false
		# Add a "Play Online" button that uses WebRTC
		var online_btn = Button.new()
		online_btn.text = "Play Online"
		online_btn.pressed.connect(GameManager.start_multiplayer_host)
		$VBoxContainer.add_child(online_btn)

func _on_singleplayer_pressed() -> void:
	GameManager.start_singleplayer()

func _on_host_pressed() -> void:
	GameManager.start_multiplayer_host()

func _on_join_pressed() -> void:
	GameManager.start_multiplayer_join(_IP)

func _on_connected() -> void:
	SceneManager.open_game_world()  # only fires for join

func _on_connection_failed() -> void:
	push_error("Connection failed")
	GameManager.cleanup()

func _on_options() -> void:
	SceneManager.open_settings()

func _on_exit() -> void:
	get_tree().quit()
