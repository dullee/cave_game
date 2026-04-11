# game_manager.gd
extends Node

const PORT = 7777
var is_singleplayer := false

func start_singleplayer() -> void:
	is_singleplayer = true
	var peer = OfflineMultiplayerPeer.new()
	get_tree().get_multiplayer().multiplayer_peer = peer
	SceneManager.open_game_world()

func start_multiplayer_host() -> void:
	is_singleplayer = false
	if OS.get_name() == "Web":
		_start_webrtc()
	else:
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(PORT)
		get_tree().get_multiplayer().multiplayer_peer = peer
		SceneManager.open_game_world()

func start_multiplayer_join(ip: String) -> void:
	is_singleplayer = false
	if OS.get_name() == "Web":
		_start_webrtc()
	else:	
		var peer = ENetMultiplayerPeer.new()
		peer.create_client(ip, PORT)
		get_tree().get_multiplayer().multiplayer_peer = peer

# game_manager.gd
func _start_webrtc() -> void:
	if not Webrtc.session_ready.is_connected(_on_webrtc_ready):
		Webrtc.session_ready.connect(_on_webrtc_ready, CONNECT_ONE_SHOT)
	Webrtc.join_session()
	
func _on_webrtc_ready(_my_id: int) -> void:
	SceneManager.open_game_world()

func cleanup() -> void:
	Webrtc.cleanup()
	var mp = get_tree().get_multiplayer()
	if mp.multiplayer_peer:
		mp.multiplayer_peer.close()
		mp.multiplayer_peer = null	
