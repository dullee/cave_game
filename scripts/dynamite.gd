extends RigidBody2D

@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer 

var damage = 50
var speed:= 800.0
var direction := Vector2.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	linear_velocity = direction * speed
	linear_velocity = direction * speed
	
	explode()

func explode():
	var radius = collision_shape_2d.shape.radius 
	await get_tree().create_timer(1.5).timeout
	TileMapGlobal.destroy_tiles_in_radius(global_position, radius)
	
	if area_2d.has_overlapping_bodies(): deal_damage_to_nearby_bodies(area_2d.get_overlapping_bodies())
	queue_free()

func deal_damage_to_nearby_bodies(overlapping_bodies):	
	self.set_physics_process(false)
	self.set_process(false)
	self.hide()

	for body in overlapping_bodies:
		if body.has_method("take_damage"): body.take_damage(damage)
	
