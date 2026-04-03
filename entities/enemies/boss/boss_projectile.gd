# boss_projectile.gd
extends Area2D

@export var speed := 300.0
@export var damage := 15
@export var lifetime := 5.0

var direction := Vector2.ZERO

func _ready() -> void:
	# Auto destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	if body.is_in_group("player"):
		var knockback_dir = (body.global_position - global_position).normalized()
		body.take_damage(damage)
		body.deal_knockback(knockback_dir)
