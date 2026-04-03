# game_manager.gd
extends Node

const PORT = 7777
var is_singleplayer := false

func _create_server() -> MultiplayerPeer:
	var peer 
	if OS.get_name() == "Web":
		peer = WebSocketMultiplayerPeer.new()
		peer.create_server(PORT)
		return peer
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	return peer

func _create_client(ip: String) -> MultiplayerPeer:
	var peer
	if OS.get_name() == "Web":
		peer = WebSocketMultiplayerPeer.new()
		peer.create_client("ws://%s:%d" % [ip, PORT])
		return peer
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	return peer

func start_singleplayer() -> void:
	is_singleplayer = true
	var peer = OfflineMultiplayerPeer.new()
	get_tree().get_multiplayer().multiplayer_peer = peer
	SceneManager.open_game_world()

func start_multiplayer_host() -> void:
	is_singleplayer = false
	get_tree().get_multiplayer().multiplayer_peer = _create_server()
	SceneManager.open_game_world()

func start_multiplayer_join(ip: String) -> void:
	is_singleplayer = false
	get_tree().get_multiplayer().multiplayer_peer = _create_client(ip)
	# Don't open world here — wait for _on_connected in start menu

func cleanup() -> void:
	var mp = get_tree().get_multiplayer()
	if mp.multiplayer_peer:
		mp.multiplayer_peer.close()
		mp.multiplayer_peer = null
