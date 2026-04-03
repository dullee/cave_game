extends Node

class_name HealthComponent

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int
var health: int

func _ready() -> void:
	health = max_health

func take_damage(amount: int):
	health = max(0, health - amount)
	_sync_health.rpc(health)
	if health <= 0:
		died.emit()
		
@rpc("any_peer", "call_local", "reliable")
func _sync_health(new_health: int) -> void:
	health = new_health
	health_changed.emit(health, max_health)

func heal(amount: int):
	if not get_parent().is_multiplayer_authority():
		return
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)
	
