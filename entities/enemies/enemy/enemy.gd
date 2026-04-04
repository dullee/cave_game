extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent
@onready var arm_collision: CollisionShape2D = $Area2D/ArmCollision
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sound_component: SoundComponent = $SoundComponent
@onready var ray_cast_2d: RayCast2D = $RayCast2D

const SPEED = 70.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 900.0
var direction := 0.0


const SEPARATION_FORCE := 200.0
const SEPARATION_DISTANCE := 40.0  

var _last_direction := 1.0
var player: CharacterBody2D
var jump_timer = 0.0
const ATTACK_RANGE := 40.0
var attack_damage = 15
var attack_cooldown: float = 0.12
var can_attack = true

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	health_component.died.connect(_on_died)

func _process(_delta: float) -> void:
	if direction == _last_direction or direction == 0:
		return
	_last_direction = direction
	sprite_2d.flip_h = direction < 0
	arm_collision.position.x = abs(arm_collision.position.x) * direction
	
func _physics_process(delta: float) -> void:
	if not player:
		player = _get_closest_player()
		return
	velocity.y += GRAVITY * delta
	direction = sign(player.global_position.x - global_position.x)
	var dist = abs(player.global_position.x - global_position.x)
	
	if dist > ATTACK_RANGE:
		velocity.x = direction * SPEED  # move toward player
	elif dist < ATTACK_RANGE * 0.5:
		velocity.x = -direction * SPEED  # too close, back away
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)  # in range, stop
	
	jump_timer -= delta
	if is_on_floor():
		if player.global_position.y < global_position.y - 32 and jump_timer <= 0:
			velocity.y = JUMP_VELOCITY
			jump_timer = 1.0
	if is_on_wall():
		velocity.y = JUMP_VELOCITY
	_apply_separation(delta)
	move_and_slide()

func _get_closest_player() -> CharacterBody2D:
	var closest: CharacterBody2D = null
	var closest_dist := INF
	for p in get_tree().get_nodes_in_group("player"):
		var dist = global_position.distance_to(p.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = p
	return closest
	
func _apply_separation(delta: float) -> void:
	# Push away from all players and other enemies
	for body in get_tree().get_nodes_in_group("player"):
		_separate_from(body, delta)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self:
			continue
		_separate_from(enemy, delta)

func _separate_from(body: Node2D, delta: float) -> void:
	var diff = global_position - body.global_position
	# Only separate horizontally — don't push up or down
	diff.y = 0
	var dist = diff.length()
	if dist < SEPARATION_DISTANCE and dist > 0:
		var push = diff.normalized() * SEPARATION_FORCE * (1.0 - dist / SEPARATION_DISTANCE)
		velocity.x += push.x * delta
	
func take_damage(amount: int):
	if not multiplayer.is_server():
		return
	health_component.take_damage(amount)
	_notify_hit.rpc()
	
@rpc("authority", "call_local", "reliable")
func _notify_hit() -> void:
	animation_player.play("on_hit")
	sound_component.play_sound("on_hit")
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and can_attack:
		attack(body)
	
func _on_died():
	SignalBus.enemy_died.emit()
	queue_free()

func attack(entity) -> void:
	can_attack = false
	var knockback_dir = (entity.global_position - global_position).normalized()
	if entity.has_method("take_damage"):
		entity.deal_knockback(knockback_dir)
	if entity.has_method("deal_knockback"):
		entity.take_damage(attack_damage)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
