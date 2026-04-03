extends Node2D

@onready var input_manager: InputManager = $"../InputManager"

@onready var ray_cast_2d: RayCast2D = $muzzle/RayCast2D
@onready var muzzle: Marker2D = $muzzle
@onready var gun_sprite: Sprite2D = $muzzle/GunSprite
var pivot_arm: Node2D = self

func _process(_delta: float) -> void:
	if get_parent().is_multiplayer_authority() and input_manager.is_enabled():
		
		var mouse_pos =	get_global_mouse_position()
		pivot_arm.look_at(mouse_pos)

		if pivot_arm.transform.x.x < 0:
			gun_sprite.flip_v = true
			muzzle.position.y = -abs(muzzle.position.y)
		else:
			gun_sprite.flip_v = false
			muzzle.position.y = abs(muzzle.position.y)

func _physics_process(delta: float) -> void:
	if get_parent().is_multiplayer_authority():
		if ray_cast_2d.is_colliding():
			muzzle.position = muzzle.position.move_toward(pivot_arm.position, delta * 100.0)
		else:
			var default_pos = Vector2(48, muzzle.position.y)
			muzzle.position = muzzle.position.move_toward(default_pos, delta * 200.0)
