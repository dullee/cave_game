# boss.gd
extends CharacterBody2D

@onready var sound_component: SoundComponent = $SoundComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var tentacles: Node2D = $Tentacles
@onready var hit_box: Area2D = $HitBox

const SPEED = 80.0
const GRAVITY = 300.0

enum State { IDLE, CHASE, SHOOT, ENRAGED, DEAD }

var state = State.IDLE

@export var projectile_scene: PackedScene
@export var shoot_interval := 2.0
@export var shoot_range := 400.0

var _shoot_timer := 0.0

var target: Node2D = null
var tentacles_alive: int = 2

func _ready() -> void:
	add_to_group("boss")
	health_component.died.connect(_on_died)
	if not multiplayer.is_server():
		set_physics_process(false)  # only host runs AI
		return
	tentacles_alive = tentacles.get_child_count()
	_find_target()
func _physics_process(delta: float) -> void:
	match state:
		State.IDLE: _state_idle()
		State.CHASE: _state_chase(delta)
		State.SHOOT: _state_shoot(delta)
		State.ENRAGED: _state_enraged(delta)
		State.DEAD: pass
	
func _state_idle() -> void:
	_find_target()
	if target:
		state = State.CHASE

func _state_chase(delta: float) -> void:
	if not is_instance_valid(target):
		_find_target()
		return
	if tentacles_alive <= 0 or health_component.health <= health_component.max_health * 0.5:
		state = State.ENRAGED
		return
	# Switch to shoot state if in range
	var dist = global_position.distance_to(target.global_position)
	if dist <= shoot_range:
		state = State.SHOOT
		return
	_move_toward_target(delta, SPEED)
	
func _state_enraged(delta: float) -> void:
	if not is_instance_valid(target):
		_find_target()
		return
	# Enraged — chase AND shoot at the same time
	_move_toward_target(delta, SPEED * 2.0)
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = shoot_interval * 0.9  # shoot faster when enraged
		_do_shoot()

func _move_toward_target(delta: float, speed: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	_apply_gravity(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _find_target() -> void:
	# Target closest player
	var players = get_tree().get_nodes_in_group("player")
	var closest_dist = INF
	for p in players:
		var dist = global_position.distance_to(p.global_position)
		if dist < closest_dist:
			closest_dist = dist
			target = p

func _state_shoot(delta: float) -> void:
	if not is_instance_valid(target):
		_find_target()
		state = State.CHASE
		return
	# Chase if player runs away
	var dist = global_position.distance_to(target.global_position)
	if dist > shoot_range:
		state = State.CHASE
		return
	# Tick shoot timer
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = shoot_interval
		_do_shoot()

func _do_shoot() -> void:
	if not multiplayer.is_server():
		return
	var base_dir = (target.global_position - global_position).normalized()
	if state == State.ENRAGED:
		# Shoot 3 projectiles in a spread
		for i in range(-1, 2):
			var spread = base_dir.rotated(deg_to_rad(i * 20))
			_spawn_projectile.rpc(global_position, spread)
	else:
		_spawn_projectile.rpc(global_position, base_dir)

@rpc("any_peer", "call_local", "reliable")
func _spawn_projectile(pos: Vector2, dir: Vector2) -> void:
	if not projectile_scene:
		return
	var projectile = projectile_scene.instantiate()
	projectile.global_position = pos
	projectile.direction = dir
	get_tree().current_scene.add_child(projectile)

func on_tentacle_destroyed() -> void:
	tentacles_alive -= 1
	#SignalBus.boss_tentacle_destroyed.emit(tentacles_alive)

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)
	health_bar.value -= amount
	
func _on_died() -> void:
	state = State.DEAD
	SignalBus.boss_died.emit()
	# Play death animation then free
	sound_component.play_sound("boss_death")
	await get_tree().create_timer(2.0).timeout
	queue_free()
