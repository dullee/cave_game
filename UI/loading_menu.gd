extends CanvasLayer

signal loading_complete

@onready var players: Node2D = $"../Players"

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

var _generation_done := false

func _ready():
	label.text = "Connecting..."
	if multiplayer.is_server():
		label.text = "Generating cave..."
		await SignalBus.cave_generated
		_generation_done = true
		label.text = "Ready!"
		loading_complete.emit()
	else:
		label.text = "Loading world..."
		var host_id = Webrtc.host_id if Webrtc else 1
		_request_seed.rpc_id(host_id)

@rpc("any_peer", "reliable")
func _request_seed():
	if not multiplayer.is_server():
		return
	var id = multiplayer.get_remote_sender_id()
	while not _generation_done:
		await get_tree().process_frame
	var cave_gen = get_tree().get_first_node_in_group("cave_generator")
	if cave_gen:
		_receive_seed.rpc_id(id, cave_gen.world_seed)
	else:
		push_error("cave_gen not found")

@rpc("authority", "call_remote", "reliable")
func _receive_seed(_seed: int):
	label.text = "Rendering cave..."
	var cave_gen = get_tree().get_first_node_in_group("cave_generator")
	if not cave_gen:
		push_error("cave_gen not found on client")
		return
	cave_gen.generate(_seed)
	await SignalBus.cave_generated
	await get_tree().process_frame
	label.text = "Ready!"
	loading_complete.emit()
	_notify_server_ready.rpc_id(1)

@rpc("any_peer", "reliable")
func _notify_server_ready():
	if not multiplayer.is_server():
		return
	var id = multiplayer.get_remote_sender_id()
	get_tree().get_first_node_in_group("world").spawn_player(id)
