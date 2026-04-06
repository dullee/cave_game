# chest.gd
extends StaticBody2D

@export var loot_table: LootTable
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interact_area: Area2D = $InteractArea

var _opened := false
var _item: Resource = null

func _ready() -> void:
	add_to_group("chest")
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	# Roll loot on server only, same seed = same loot on all peers
	if multiplayer.is_server() and loot_table:
		_item = loot_table.get_random_item()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not body.is_multiplayer_authority():
		return
	# Show interact prompt
	SignalBus.show_interact_prompt.emit("Press F to open")

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	SignalBus.hide_interact_prompt.emit()

func _unhandled_input(event: InputEvent) -> void:
	if _opened:
		return
	# Check if a player is in range
	for body in interact_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.is_multiplayer_authority():
			if event.is_action_pressed("f"):
				_request_open()

@rpc("any_peer", "reliable")
func _request_open() -> void:
	if not multiplayer.is_server():
		return
	if _opened:
		return
	_opened = true
	var sender_id = multiplayer.get_remote_sender_id()
	# Tell all peers to play open animation
	_open.rpc()
	# Give item to the player who opened it
	if _item:
		print("calling give item rpc")
		if is_multiplayer_authority():
			_give_item(_item.resource_path)
			return
		_give_item.rpc_id(sender_id, _item.resource_path)
	else:
		print("no item found")
		
@rpc("authority", "call_local", "reliable")
func _open() -> void:
	_opened = true
	#animation_player.play("open")
	SignalBus.hide_interact_prompt.emit()

@rpc("authority", "call_remote", "reliable")
func _give_item(item_path: String) -> void:
	print("give item started")
	var item = load(item_path) as WeaponData
	print("loading item path: ", item)
	if not item:
		print("could not load item path")
		return
	# Give to local player
	
	var my_id = str(multiplayer.get_unique_id())
	print("gettin player id: ", my_id)
	
	var player = get_tree().get_first_node_in_group("players_node").get_node_or_null(str(my_id))

	print("getting player ", my_id, ": ", player)
	if player:
		print("player found sending item")
		var weapon_comp = player.get_weapon_component()
		if weapon_comp:
			weapon_comp.equip(item)
		else:
			print("weapon comp not found: ", weapon_comp)
		SignalBus.item_picked_up.emit(item.weapon_name)
