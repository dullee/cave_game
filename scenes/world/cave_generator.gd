extends Node

@onready var tilemap: TileMapLayer = $"../TileMapLayer"

const WALL_TILE  := Vector2i(1, 0)
const FLOOR_TILE := Vector2i(0, 1)
const ORE_TILE   := Vector2i(0, 0)

const BOSS_ROOM_WIDTH = 100
const BOSS_ROOM_HEIGHT = 50

var valid_spawn_tiles: Array[Vector2] = []  # world positions of valid floor tile
var potential_spawn_tiles: Array[Vector2] = [] # can become valid spawn if tile above it is removed
const MIN_SPAWN_INTERVAL = 5  # only store every Nth tile to spread them out

@export var web_map_width := 100
@export var web_map_height := 550

@export var map_width := 100
@export var map_height := 100
var fill_threshold := 0.0
var world_seed := 0
var max_light_distance := 900.0
var ore_lights: Dictionary = {}

var _player: CharacterBody2D

func _ready():
	add_to_group("cave_generator")

	if OS.get_name() == "Web":
		await _prewarm_scenes()
		map_height = web_map_height
		map_width = web_map_width
		
	if multiplayer.is_server():
		world_seed = randi()
		generate(world_seed)	
		
func generate(_seed: int) -> void:

	valid_spawn_tiles.clear()
	var noise = FastNoiseLite.new()
	noise.seed = _seed
	noise.frequency = 0.03
	noise.noise_type = FastNoiseLite.TYPE_PERLIN

	var ore_noise = FastNoiseLite.new()
	ore_noise.seed = _seed + 1
	ore_noise.frequency = 0.08

	for x in map_width:
		for y in map_height:
			var value = noise.get_noise_2d(x, y)
			var tile = WALL_TILE if value > fill_threshold else FLOOR_TILE
			if tile == WALL_TILE and ore_noise.get_noise_2d(x, y) > 0.6:
				tile = ORE_TILE
				
			tilemap.set_cell(Vector2i(x, y), 0, tile)

		await get_tree().process_frame
	
	_stamp_boss_room()
	_collect_spawn_tiles()
	SignalBus.cave_generated.emit()
	print("cave generated")
	
func _process(_delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return
		
func _collect_spawn_tiles() -> void:
	for x in map_width:
		for y in map_height:
			var cell = Vector2i(x, y)
			var atlas = tilemap.get_cell_atlas_coords(cell)
			var above = tilemap.get_cell_atlas_coords(Vector2i(x, y -1))
			var below = tilemap.get_cell_atlas_coords(Vector2i(x, y + 1))
			
			if atlas == FLOOR_TILE:
				continue
				
			if below != FLOOR_TILE:
				continue
				
			if above == FLOOR_TILE:
				potential_spawn_tiles.append(tilemap.to_global(tilemap.map_to_local(cell)))
				
			valid_spawn_tiles.append(tilemap.to_global(tilemap.map_to_local(cell)))
	print("collected spawn tiles: ", valid_spawn_tiles.size())
	
func _stamp_boss_room() -> void:
	# Bottom center of the map
	@warning_ignore("integer_division")
	var room_y = map_height - BOSS_ROOM_HEIGHT

	# First carve out the area so noise tiles don't poke through
	for x in range(map_width - 2):
		for y in range(room_y, room_y + BOSS_ROOM_HEIGHT):
			if y < map_height:
				tilemap.set_cell(Vector2i(x, y), 0, ORE_TILE)
				
	var boss_room_scene = preload("res://scenes/boss_room.tscn")
	var boss_room = boss_room_scene.instantiate()
	get_tree().current_scene.add_child(boss_room)
		
	var local_pos = tilemap.map_to_local(Vector2i(0, room_y))
	var global_pos = tilemap.to_global(local_pos)
	
	boss_room.global_position = global_pos
	boss_room.add_to_group("boss_room")

func remove_ore_light(pos):
	tilemap.set_cell(pos, 0, WALL_TILE)

func _prewarm_scenes() -> void:
	var scenes_to_prewarm = [
		preload("res://entities/weapons/bullet.tscn"),
		preload("res://entities/weapons/dynamite.tscn"),
	]
	for scene in scenes_to_prewarm:
		var instance = scene.instantiate()
		instance.global_position = Vector2(-99999, -99999)
		add_child(instance)
		await get_tree().process_frame
		instance.queue_free()
	print("Prewarm done")
