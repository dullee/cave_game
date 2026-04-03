extends RigidBody2D

@onready var line_2d: Line2D = $Line2D

@onready var curve = Curve2D	.new()

const SPEED:= 800.0
var collision : KinematicCollision2D = null
var direction := Vector2.RIGHT
var damage = 10

const BULLET_LIFE_TIME = 1.5
var life_time_left = 0.0

const MAX_TRAIL_POINTS: int = 2000
var trail_points: Array[Vector2] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	linear_velocity = direction * SPEED
	rotation = direction.angle()
	
func _process(delta: float) -> void:
	trail_points.push_front(global_position)
	if trail_points.size() > MAX_TRAIL_POINTS:
		trail_points.pop_back()
	line_2d.points = trail_points
	
	life_time_left += delta
	if life_time_left > BULLET_LIFE_TIME:
		queue_free()
		
func _physics_process(delta: float) -> void:
	var move_vector = direction * SPEED * delta  
	collision = move_and_collide(move_vector)

	if collision:
		_on_body_entered(collision.get_collider())

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.linear_velocity.length()> 0.1:
		rotation = state.linear_velocity.angle()

func _on_body_entered(body):
	self.set_physics_process(false)
	self.set_process(false)
	self.hide()

	if body is TileMapLayer:
		TileMapGlobal.destroy_tile(collision)
		queue_free()
		return
	if body.is_in_group("enemy"):
		body.take_damage(damage)
	
