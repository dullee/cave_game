extends Camera2D

var target: Node2D = null
var follow_speed := 5.0

func set_target(node: Node2D) -> void:
	target = node
	make_current()

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		global_position = global_position.lerp(target.global_position, follow_speed * delta)
		
