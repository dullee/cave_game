# webrtc_manager.gd
extends Node

# Replace with your Railway URL
const SIGNAL_SERVER = "wss://signaling-server-production-784c.up.railway.app"
const ICE_SERVERS = [
	{ "urls": ["stun:stun.l.google.com:19302"] },
	{ "urls": ["stun:stun1.l.google.com:19302"] }
]

var _ws := WebSocketPeer.new()
var _rtc := WebRTCMultiplayerPeer.new()
var _my_id := 0
var _connections: Dictionary = {}
var _is_ready := false

signal session_ready(my_id: int)

func _ready() -> void:
	set_process(false)

func join_session() -> void:
	# Don't reconnect if already connected
	var state = _ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN or state == WebSocketPeer.STATE_CONNECTING:
		print("Already connected to signal server")
		return
	var err = _ws.connect_to_url(SIGNAL_SERVER)
	if err != OK:
		push_error("Failed to connect to signal server")
		return
	set_process(true)
	print("Connecting to signal server...")	

func _process(_delta: float) -> void:
	_ws.poll()
	_poll_connections()
	match _ws.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			print("still connecting...")  # ← add this
		WebSocketPeer.STATE_OPEN:
			while _ws.get_available_packet_count():
				var msg = _ws.get_packet().get_string_from_utf8()
				print("received: ", msg)  # ← add this
				_handle_message(msg)
		WebSocketPeer.STATE_CLOSING:
			print("closing...")
		WebSocketPeer.STATE_CLOSED:
			var code = _ws.get_close_code()
			var reason = _ws.get_close_reason()
			print("closed | code: ", code, " reason: ", reason)  # ← add this
			set_process(false)

func _poll_connections() -> void:
	for id in _connections:
		_connections[id].poll()

func _handle_message(msg: String) -> void:
	var data = JSON.parse_string(msg)
	if not data:
		return
	print("Signal received: ", data.type)
	match data.type:
		"id":
			_on_got_id(data.id)
		"peers":
			_on_got_peers(data.peers)
		"peer_connected":
			_on_peer_connected(data.id)
		"peer_disconnected":
			_on_peer_disconnected(data.id)
		"offer":
			_on_offer(data.from, data.sdp)
		"answer":
			_on_answer(data.from, data.sdp)
		"candidate":
			_on_candidate(data.from, data.media, data.index, data.name)

func _on_got_id(id: int) -> void:
	_my_id = id
	# Replace initialize() with create_mesh()
	_rtc.create_mesh(id)
	get_tree().get_multiplayer().multiplayer_peer = _rtc
	print("My WebRTC ID: ", _my_id)
	

func _on_got_peers(peers: Array) -> void:
	# We joined an existing session
	for peer_id in peers:
		_create_connection(peer_id, true)  # we initiate offer
	session_ready.emit(_my_id)

func _on_peer_connected(id: int) -> void:
	# New peer joined after us, they will send offer
	_create_connection(id, false)
	if not _is_ready:
		_is_ready = true
		session_ready.emit(_my_id)

func _on_peer_disconnected(id: int) -> void:
	if _connections.has(id):
		_rtc.remove_peer(id)
		_connections[id].close()
		_connections.erase(id)
	print("Peer disconnected: ", id)

func _create_connection(peer_id: int, initiate: bool) -> void:
	print("Creating connection to peer: ", peer_id, " initiate: ", initiate)
	var conn = WebRTCPeerConnection.new()
	conn.initialize({ "iceServers": ICE_SERVERS })
	conn.ice_candidate_created.connect(
		func(media, index, name):
			_send({ "type": "candidate", "target": peer_id,
					"media": media, "index": index, "name": name })
	)
	conn.session_description_created.connect(
		func(type, sdp):
			conn.set_local_description(type, sdp)
			_send({ "type": type, "target": peer_id, "sdp": sdp })
	)
	_rtc.add_peer(conn, peer_id)
	_connections[peer_id] = conn
	if initiate:
		conn.create_offer()

func _on_offer(from: int, sdp: String) -> void:
	if not _connections.has(from):
		_create_connection(from, false)
	_connections[from].set_remote_description("offer", sdp)

func _on_answer(from: int, sdp: String) -> void:
	if _connections.has(from):
		_connections[from].set_remote_description("answer", sdp)

func _on_candidate(from: int, media: String, index: int, name: String) -> void:
	if _connections.has(from):
		_connections[from].add_ice_candidate(media, index, name)

func _send(data: Dictionary) -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(data))

func cleanup() -> void:
	_ws.close()
	for id in _connections:
		_connections[id].close()
	_connections.clear()
	_my_id = 0
	_is_ready = false
	set_process(false)
