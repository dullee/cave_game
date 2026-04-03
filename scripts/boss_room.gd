# boss_room.gd
extends Node2D

@onready var boss_trigger: Area2D = $TileMapLayer/BossTrigger
@onready var boss_spawn_point: Marker2D = $TileMapLayer/BossSpawnPoint

var boss_spawned := false

func _ready() -> void:
	add_to_group("boss_room")
	boss_trigger.body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D) -> void:

	if boss_spawned:
		return
	if not body.is_in_group("player"):
		return
	boss_trigger.set_deferred("monitoring", false)
	if multiplayer.is_server():
		_request_boss_spawn()  # call directly on host
	else:
		_request_boss_spawn.rpc_id(1)  # RPC only if client

@rpc("any_peer", "reliable")
func _request_boss_spawn() -> void:
	if not multiplayer.is_server():
		return
	if boss_spawned:
		return
	boss_spawned = true
	var boss_node = get_tree().get_first_node_in_group("boss_node")
	var boss_scene = preload("res://entities/enemies/boss/boss.tscn")
	var boss = boss_scene.instantiate()
	boss.global_position = boss_spawn_point.global_position

	boss_node.call_deferred("add_child", boss)
	_notify_boss_spawned.rpc()

@rpc("authority", "call_local", "reliable")
func _notify_boss_spawned() -> void:
	boss_spawned = true  # make sure all peers know its spawned
	boss_trigger.set_deferred("monitoring", false)
	SignalBus.boss_spawned.emit()

func _on_out_of_bounds_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("player went out of bounds")
		body._on_died()
	else:
		body.queue_free()
