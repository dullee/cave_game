extends Node2D

@onready var input_manager: InputManager = $"../InputManager"

@export var jetpack_velocity = -200.0
@export var hover_threshold := 20.0  # how close to target height before hovering
@export var hover_strength := 300.0  # force to maintain hover

var _hover_target_y: float = 0.0

var jetpack_active = false
var hovering = false

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return 
	if not input_manager.is_enabled():
		return
	
	var player = get_parent()

	if hovering:
		hover(delta)
		# Let player exit hover by pressing shift again
		if input_manager.is_action_just_pressed("space"):
			hovering = false
			jetpack_active = false
		return  # ← return early, skip everything else
	
	if input_manager.is_action_pressed("left_shift"):
		fly_up()
		jetpack_active = true
	else:
		jetpack_active = false
	
	if input_manager.is_action_just_pressed("space") and jetpack_active:
		_hover_target_y = player.global_position.y
		hovering = true

func fly_up() -> void:
	var player = get_parent()
	player.velocity.y = jetpack_velocity
	player.state = player.State.JUMP

func hover(delta: float) -> void:
	var player = get_parent()
	var diff = player.global_position.y - _hover_target_y

	# Push up if below target, push down if above
	if abs(diff) > hover_threshold:
		player.velocity.y = move_toward(
			player.velocity.y,
			-sign(diff) * hover_strength,
			hover_strength * delta
		)
	else:
		# Dampen vertical velocity to lock in place
		player.velocity.y = move_toward(player.velocity.y, 0.0, hover_strength * delta)
	
func is_gravity_suppressed() -> bool:
	return jetpack_active or hovering

func on_landed() -> void:
	hovering = false
	jetpack_active = false
