extends Node

var main_layer: TileMapLayer
var tile_size_x = 16
const WALL_TILE := Vector2i(1, 0)
const FLOOR_TILE := Vector2i(0, 1)
var source_id = 0

func _ready():

	main_layer = get_tree().get_first_node_in_group("tilemaplayer")
	if main_layer:
		tile_size_x = main_layer.tile_set.tile_size.x

func destroy_tile(collision: KinematicCollision2D):
	if not collision or not multiplayer.is_server():
		print("no coll / not server")
		return
	var collider = collision.get_collider()
	if not is_instance_valid(collider):
		print("instance not valid")
		return
	# Only process if it's actually the cave tilemap
	if collider != main_layer:
		return
	var collision_pos_global = collision.get_position()
	var collision_normal = collision.get_normal()
	var biased_pos = collision_pos_global - collision_normal * (main_layer.tile_set.tile_size.x * 0.5)
	var collision_pos_local = main_layer.to_local(biased_pos)
	var collided_tile_pos = main_layer.local_to_map(collision_pos_local)
	var tile_data = main_layer.get_cell_tile_data(collided_tile_pos)
	if not tile_data:
		print("no tile data")
		return
	if not tile_data.get_custom_data("breakable"):
		print("tile has no breakable data")
		return
	replace_tile(collided_tile_pos, source_id, WALL_TILE)

func destroy_tiles_in_radius(world_pos: Vector2, radius: float):
	if not is_instance_valid(main_layer) or not multiplayer.is_server():
		return
	var tile_radius = int(ceil(radius / tile_size_x))
	var center_tile = main_layer.local_to_map(main_layer.to_local(world_pos))
	
	for x in range(-tile_radius, tile_radius + 1):
		for y in range(-tile_radius, tile_radius + 1):
			var candidate = center_tile + Vector2i(x, y)
			if main_layer.get_cell_source_id(candidate) == -1:
				continue
			var tile_data = main_layer.get_cell_tile_data(candidate)
			if not tile_data:
				continue
			if not tile_data.get_custom_data("breakable"):
				continue
			var candidate_world = main_layer.to_global(main_layer.map_to_local(candidate))
			if world_pos.distance_to(candidate_world) <= radius:
				replace_tile(candidate, source_id, WALL_TILE)

func replace_tile(cell_pos: Vector2i, id: int, new_tile: Vector2i) -> void:
	var tile_data = main_layer.get_cell_tile_data(cell_pos)
	if not tile_data:
		return
	var can_glow = tile_data.get_custom_data("can_glow")
	_apply_replace_tile(cell_pos, id, new_tile, can_glow)  # local
	_sync_replace_tile.rpc(cell_pos, id, new_tile, can_glow)  
	_update_spawn_tiles(cell_pos)
	
@rpc("any_peer", "call_remote", "reliable")  # ← call_remote not default
func _sync_replace_tile(cell_pos: Vector2i, id: int, new_tile: Vector2i, can_glow: bool) -> void:
	_apply_replace_tile(cell_pos, id, new_tile, can_glow)

func _apply_replace_tile(cell_pos: Vector2i, id: int, new_tile: Vector2i, can_glow: bool) -> void:
	main_layer.set_cell(cell_pos, id, new_tile)
	if can_glow:
		var cave_gen = get_tree().get_first_node_in_group("cave_generator")
		if cave_gen:
			cave_gen.remove_ore_light(cell_pos)

func _update_spawn_tiles(cell: Vector2i) -> void:
	if not multiplayer.is_server():
		return
	var cave_gen = get_tree().get_first_node_in_group("cave_generator")
	if not cave_gen:
		return
	_evaluate_spawn_tile(cell, cave_gen)
	SignalBus.spawn_tiles_updated.emit()

func _evaluate_spawn_tile(cell: Vector2i, cave_gen: Node) -> void:
	var below_cell = Vector2i(cell.x, cell.y + 1)
	var above_cell = Vector2i(cell.x, cell.y - 1)
	
	var atlas = main_layer.get_cell_atlas_coords(cell)
	var below_atlas = main_layer.get_cell_atlas_coords(below_cell)
	var above_atlas = main_layer.get_cell_atlas_coords(above_cell)
	var world_pos = main_layer.to_global(main_layer.map_to_local(cell))
	var world_above = main_layer.to_global(main_layer.map_to_local(above_cell))
	var world_below = main_layer.to_global(main_layer.map_to_local(below_cell))
	
	var potential_tiles = cave_gen.potential_spawn_tiles
	var valid_tiles = cave_gen.valid_spawn_tiles
	
	var is_valid = below_atlas == cave_gen.FLOOR_TILE and above_atlas != cave_gen.FLOOR_TILE
	var above_potential = potential_tiles.has(world_below)
	var below_potential = potential_tiles.has(world_above) and below_atlas != cave_gen.FLOOR_TILE
	var new_potential = above_atlas == cave_gen.FLOOR_TILE and below_atlas == cave_gen.FLOOR_TILE
	var in_between_potentials = potential_tiles.has(world_below) and potential_tiles.has(world_above)
	
	valid_tiles.erase(world_above)

	if is_valid:
		if potential_tiles.has(world_above):
			potential_tiles.erase(world_above)
		if not valid_tiles.has(world_pos):
			valid_tiles.append(world_pos)
			return
	if above_potential:
		if in_between_potentials:
			potential_tiles.erase(world_above)
			
		potential_tiles.erase(world_below)
		valid_tiles.append(world_below)
		return
	if below_potential:
		potential_tiles.erase(world_above)
		
	if new_potential:
		potential_tiles.append(world_pos)
		return
	else:
		valid_tiles.erase(world_pos)
	
