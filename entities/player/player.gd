extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var sound_component: SoundComponent = $SoundComponent
@onready var input_manager: InputManager = $InputManager


@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var player_name_label: Label = $PlayerName
@onready var hud_canvas: CanvasLayer = $HudCanvas
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var jetpack: Node2D = $Jetpack

@export var knockback_force = 300.0
var _knockback_velocity := Vector2.ZERO
var knockback_time := 0.2
var knockback_timer := 0.0
const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const JUMP_CUT_MULT = 0.4  # multiplied when jump released early
const GRAVITY = 1200.0
const STEP_HEIGHT = 16

var invincibility_time: float = 0.5
var _invincible = false
var is_stepping := false
var double_jumped := false

enum State { IDLE, WALK, JUMP, FALL}
var state: State = State.IDLE

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

func _ready() -> void:
	multiplayer_synchronizer.set_multiplayer_authority(int(name))
	health_component.died.connect(_on_died)
	player_name_label.text = str("Player: ", name)
	if not is_multiplayer_authority():
		set_physics_process(false)
		hud_canvas.visible = false
	else:
		get_tree().get_first_node_in_group("camera").set_target(self)

func get_health_component() -> HealthComponent: return health_component

func get_weapon_component() -> WeaponComponent: return weapon_component

func _unhandled_input(_event: InputEvent) -> void:
	var camera = get_tree().get_first_node_in_group("camera")
	if not is_multiplayer_authority():
		return
	
	if input_manager.is_action_just_pressed("esc"):
		SceneManager.open_pause()
	if input_manager.is_action_just_pressed("mouse_wheel_up"):
		if camera.zoom == Vector2(0,0):
			camera.zoom += Vector2(0.1, 0.1)
		camera.zoom += Vector2(0.1, 0.1)
	if input_manager.is_action_just_pressed("mouse_wheel_down"):
		if camera.zoom == Vector2(0,0):
			camera.zoom -= Vector2(0.1, 0.1)
		camera.zoom -= Vector2(0.1, 0.1)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority() or not input_manager.is_enabled():
		return
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_force * 3.0 * delta)
	if _knockback_velocity.length() > 10:
		print("knockback active: ", _knockback_velocity)
	match state:
		State.IDLE: _state_idle(delta)
		State.WALK: _state_walk(delta)
		State.JUMP: _state_jump(delta)
		State.FALL: _state_fall(delta)
		
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		if jetpack and jetpack.is_gravity_suppressed():
			return
		velocity.y += GRAVITY * delta
		
func _handle_horizontal(_delta: float) -> void:
	var direction := input_manager.get_axis("a", "d")
	# Blend player input with decaying knockback
	velocity.x = direction * SPEED + _knockback_velocity.x
	if direction != 0 and is_on_floor():
		_try_step_up(direction)

func _state_idle(delta: float) -> void:
	_apply_gravity(delta)
	move_and_slide()
	if not is_on_floor():
		state = State.FALL
		return
	if input_manager.get_axis("a", "d") != 0:
		state = State.WALK
	if input_manager.is_action_just_pressed("space"):
		_jump()

func _state_walk(delta: float) -> void:
	_apply_gravity(delta)
	_handle_horizontal(delta)

	move_and_slide()
	if not is_on_floor():
		state = State.FALL
		return
	if input_manager.get_axis("a", "d") == 0:
		state = State.IDLE
	if input_manager.is_action_just_pressed("space"):
		_jump()

func _state_jump(delta: float) -> void:
	_apply_gravity(delta)
	_handle_horizontal(delta)
	
	# Jump cut — let go of space early for a shorter jump
	if input_manager.is_action_just_released("space") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULT

	move_and_slide()
	if velocity.y >= 0:
		state = State.FALL
	if is_on_floor():
		state = State.IDLE

func _state_fall(delta: float) -> void:
	_apply_gravity(delta)
	_handle_horizontal(delta)
	velocity.y += _knockback_velocity.y  # ← apply vertical knockback
	_knockback_velocity.y = 0.0          # ← consume it immediately
	if input_manager.is_action_just_pressed("space") and not double_jumped:
		double_jumped = true
		_jump()
		state = State.JUMP
		return
	move_and_slide()
	if is_on_floor():
		double_jumped = false
		_knockback_velocity = Vector2.ZERO  # ← clear on landing
		state = State.IDLE
		if jetpack:
			jetpack.on_landed()
			
func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	state = State.JUMP
	sound_component.play_sound("jump")
	
func _try_step_up(direction: float) -> void:
	if is_stepping:
		return
	var half_width = (col_shape.shape as RectangleShape2D).size.x * 0.5
	var has_wall = test_move(global_transform, Vector2(direction * (half_width + 8), 0))
	if has_wall:
		var step_transform = global_transform
		step_transform.origin.y -= STEP_HEIGHT + 1
		var wall_above = test_move(step_transform, Vector2(direction * (half_width + 8), 0))
		var ceiling = test_move(step_transform, Vector2.ZERO)
		if not wall_above and not ceiling:
			_smooth_step_up()

func _smooth_step_up() -> void:
	is_stepping = true
	velocity.y = 0
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - STEP_HEIGHT, 0.07)
	tween.tween_callback(func(): is_stepping = false)

@rpc("authority", "call_local", "reliable")
func take_damage(amount: int) -> void: 
	if not multiplayer.is_server():
		return
	if _invincible:
		return
	health_component.take_damage(amount)
	_start_invincibility()
	animation_player.play("player_hurt")
	
func deal_knockback(knockback_dir: Vector2) -> void:
	var id = get_multiplayer_authority()
	if id == multiplayer.get_unique_id():
		apply_knockback_rpc(knockback_dir)
	else:
		apply_knockback_rpc.rpc_id(id, knockback_dir)

@rpc("any_peer", "call_remote", "reliable")
func apply_knockback_rpc(knockback_dir: Vector2) -> void:
	_do_knockback(knockback_dir)

func apply_knockback(knockback_dir: Vector2) -> void:
	_do_knockback(knockback_dir)

func _do_knockback(knockback_dir: Vector2) -> void:
	print("knockback received | dir: ", knockback_dir, 
		  " | is_authority: ", is_multiplayer_authority())
	_apply_knockback(knockback_dir)
	
func _apply_knockback(direction: Vector2) -> void:
	if not is_multiplayer_authority():
		return
	print("applying knockback | dir: ", direction, " force: ", knockback_force)
	state = State.FALL
	sound_component.play_sound("player_hit")
	_knockback_velocity = direction.normalized() * knockback_force
	_knockback_velocity.y = -abs(knockback_force * 0.6)
	print("knockback velocity set to: ", _knockback_velocity)
	velocity = _knockback_velocity
	
func _start_invincibility() -> void:
	_invincible = true
	# Flash to show invincibility
	#var tween = create_tween()
	#tween.tween_property(self, "modulate:a", 0.3, 0.1).set_loops(6)
	await get_tree().create_timer(invincibility_time).timeout  # invincibility duration
	#modulate.a = 1.0
	_invincible = false

func _on_died() -> void:
	set_process_unhandled_input(false)
	set_process(false)
	SignalBus.input_disabled.emit() 
	animation_player.play("death_animation")
	await animation_player.animation_finished
	set_physics_process(false)
	sound_component.play_sound("player_death")
	SignalBus.player_died.emit(get_multiplayer_authority())
	SceneManager.open_death_screen()
	queue_free()
