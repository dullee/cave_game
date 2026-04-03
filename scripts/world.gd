extends Node2D

const PlayerScene = preload("res://scenes/player.tscn")

@onready var player_camera: Camera2D = $Players/PlayerCamera
@onready var players_node: Node = $Players
@onready var loading_overlay: CanvasLayer = $LoadingMenu

func _ready():
	add_to_group("world")
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	SignalBus.player_died.connect(_on_player_died)
	loading_overlay.visible = true
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		await SignalBus.cave_generated
		_spawn_player(1)
		loading_overlay.visible = false
	# Spawn and immediately free a bullet off screen to pre-compile shader
	if OS.get_name() == "Web":
		await get_tree().process_frame
		_prewarm_scenes()
		
func _prewarm_scenes() -> void:
	var scenes_to_prewarm = [
		preload("res://scenes/bullet.tscn"),
		preload("res://scenes/dynamite.tscn"),
	]
	for scene in scenes_to_prewarm:
		var instance = scene.instantiate()
		instance.global_position = Vector2(-99999, -99999)
		add_child(instance)
		await get_tree().process_frame
		instance.queue_free()
	print("Prewarm done") 
		
func _on_peer_connected(id: int):
	print("Peer connected: ", id)

func _on_peer_disconnected(id: int):
	var player = players_node.get_node_or_null(str(id))
	if player:
		player.queue_free()

func spawn_player(id: int):
	_spawn_player(id)
	_hide_loading.rpc_id(id)

@rpc("any_peer", "reliable")
func _spawn_player_on_client(id: int):
	_spawn_player(id)

@rpc("any_peer", "reliable")
func _hide_loading():
	if multiplayer.is_server():
		return
	loading_overlay.visible = false

func _spawn_player(id: int) -> void:
	if players_node.get_node_or_null(str(id)):
		return
	var player = PlayerScene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	players_node.add_child(player)
	player.global_position = players_node.global_position
	#print("Spawned Player: ", id, " at: ", player.global_position)
	
func _on_player_died(peer_id: int) -> void:

	await get_tree().create_timer(0.5).timeout
	_spawn_player(peer_id)
	
