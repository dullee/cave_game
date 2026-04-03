extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent

const SPEED = 70.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 900.0

var health = 100
var player: CharacterBody2D
var jump_timer = 0.0
var attack_damage = 15
var attack_cooldown: float = 0.5
var can_attack = true

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	health_component.died.connect(_on_died)
	
func _physics_process(delta: float) -> void:
	if not player:
		return
		
	velocity.y += GRAVITY * delta
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * SPEED
	
	jump_timer -= delta
	if is_on_floor():
		if player.global_position.y < global_position.y - 32 and jump_timer <= 0:
			velocity.y = JUMP_VELOCITY
			jump_timer = 1.0
		if is_on_wall():
			velocity.y = JUMP_VELOCITY
	
	if not can_attack:
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
	move_and_slide()
	
func take_damage(amount: int):
	health_component.take_damage(amount)
		
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and can_attack:
		body.take_damage(attack_damage)
		can_attack = false
		
func _on_died():
	SignalBus.enemy_died.emit()
	queue_free()
