# tentacle_segment.gd
extends RigidBody2D

@export var hp: int = 30

func _ready() -> void:
	add_to_group("tentacle")
	if not multiplayer.is_server():
		freeze = true
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

func take_damage(amount: int) -> void:
	if not multiplayer.is_server():
		return
	hp -= amount
	if hp <= 0:
		_destroy()

func _destroy() -> void:
	var boss = get_tree().get_first_node_in_group("boss")
	if boss:
		boss.on_tentacle_destroyed()
	queue_free()
