extends Node

class_name HealthComponent

const DamageNumber = preload("res://scenes/damage_indicator_number.tscn")

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int
var health: int

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	if not multiplayer.is_server():
		return
	health = max(0, health - amount)
	_sync_health.rpc(health, amount)  # ← pass amount separately
	if health <= 0:
		died.emit()

@rpc("any_peer", "call_local", "reliable")
func _sync_health(new_health: int, damage_amount: int) -> void:
	health = new_health
	health_changed.emit(health, max_health)
	_spawn_damage_number(damage_amount) 

func heal(amount: int):
	if not get_parent().is_multiplayer_authority():
		return
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)
	
func _spawn_damage_number(amount: int) -> void:
	var number = DamageNumber.instantiate()
	var offset = Vector2(randf_range(-15, 15), randf_range(-10, 0))
	number.global_position = get_parent().global_position + Vector2(0, -20) + offset
	get_tree().current_scene.add_child(number)
	var color = Color.RED if get_parent().is_in_group("player") else Color.YELLOW
	number.setup(amount, color)
