# boss_hitbox.gd
extends Area2D

@export var damage := 10
@export var knockback_force := 600.0
var _hit_cooldowns := {}  # per player cooldown so invincibility works with overlap

func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	for body in get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		var id = body.get_multiplayer_authority()
		# Only hit if cooldown expired
		if _hit_cooldowns.get(id, 0.0) > 0.0:
			continue
		_hit_cooldowns[id] = 0.5  # match your invincibility duration
		# Get knockback direction from boss center to player center
		var knockback_dir = _get_knockback_direction(body)
		body.take_damage.rpc(damage)
		if multiplayer.get_unique_id() == id:
			body.apply_knockback(knockback_dir)   # direct call for host player
		else:
			body.apply_knockback_rpc.rpc_id(id, knockback_dir)  # RPC for clients

func _process(delta: float) -> void:
	# Tick down cooldowns
	for id in _hit_cooldowns:
		_hit_cooldowns[id] -= delta

func _get_knockback_direction(body: Node2D) -> Vector2:
	var diff = body.global_position - global_position
	# If player is exactly on top, pick a default direction (never zero)
	if diff.length() < 1.0:
		return Vector2.UP
	return diff.normalized()
