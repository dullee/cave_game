# spawn_tile_debug.gd
extends Node2D

func _ready() -> void:
	SignalBus.cave_generated.connect(queue_redraw)
	SignalBus.spawn_tiles_updated.connect(queue_redraw)
	
func _draw() -> void:
	var cave_gen = get_tree().get_first_node_in_group("cave_generator")
	if not cave_gen:
		return
	for pos in cave_gen.valid_spawn_tiles:
		draw_circle(to_local(pos), 4.0, Color.BLUE_VIOLET)
	for pos in cave_gen.potential_spawn_tiles:
		draw_circle(to_local(pos), 4.0, Color.YELLOW)
