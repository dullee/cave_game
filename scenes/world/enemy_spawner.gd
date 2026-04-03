# enemy_spawner.gd
extends Node

@export var enemies: Array[PackedScene] = []
@export var enemy_weights: Array[int] = []
@export var base_wave_size := 8
@export var wave_size_increase := 4   # added per wave
@export var time_between_waves := 1.0
@export var min_spawn_distance := 300.0

var current_wave := 0
var _wave_timer := 0.0
var _wave_active := false
var _enemies_remaining := 0

func _ready() -> void:
	set_process(false)
	if not multiplayer.is_server():
		return
	await SignalBus.cave_generated
	await get_tree().process_frame
	SignalBus.enemy_died.connect(_on_enemy_died)
	# Start first wave after a short grace period
	_wave_timer = 1.0
	set_process(true) 
	
func _process(delta: float) -> void:
	if _wave_active:
		return 
	_wave_timer -= delta
	
	if _wave_timer <= 0.0:
		_start_wave()

func _start_wave() -> void:
	current_wave += 1
	var wave_size = base_wave_size + (current_wave - 1) * wave_size_increase
	#print("WAVE: starting wave ", current_wave, " size: ", wave_size)
	_enemies_remaining = wave_size
	_wave_active = true
	_notify_wave_start.rpc(current_wave, wave_size)
	_spawn_wave(wave_size)

func _spawn_wave(count: int) -> void:
	var cave_gen = get_tree().get_first_node_in_group("cave_generator")
	var enemies_node = get_tree().get_first_node_in_group("enemies")
	#print("WAVE: cave_gen: ", cave_gen, " enemies_node: ", enemies_node)
	#print("WAVE: valid_spawn_tiles count: ", cave_gen.valid_spawn_tiles.size() if cave_gen else 0)
	#print("WAVE: enemies array size: ", enemies.size())
	if not cave_gen or not enemies_node:
		return
	var valid_positions = _get_valid_positions(cave_gen.valid_spawn_tiles, count)
	#print("WAVE: valid positions found: ", valid_positions.size())
	for pos in valid_positions:
		var enemy_scene = _get_weighted_enemy()
		#print("WAVE: spawning enemy at: ", pos)
		var enemy = enemy_scene.instantiate()
		enemy.global_position = pos
		enemies_node.add_child(enemy)
		await get_tree().create_timer(0.2).timeout

func _get_valid_positions(all_tiles: Array, count: int) -> Array:
	var valid := []
	var shuffled = all_tiles.duplicate()
	shuffled.shuffle()

	for pos in shuffled:
		if valid.size() >= count:
			break
		if not _is_far_enough_from_players(pos):
			continue
		# Also check not too close to other spawn points in this wave
		var too_close_to_other := false
		for other in valid:
			if pos.distance_to(other) < 100.0:
				too_close_to_other = true
				break
		if not too_close_to_other:
			valid.append(pos)

	return valid

func _is_far_enough_from_players(pos: Vector2) -> bool:
	for player in get_tree().get_nodes_in_group("player"):
		if pos.distance_to(player.global_position) < min_spawn_distance:
			return false
	return true

func _on_enemy_died() -> void:
	if not _wave_active:
		return
	_enemies_remaining -= 1
	_notify_enemies_remaining.rpc(_enemies_remaining)
	if _enemies_remaining <= 0:
		_end_wave()

func _end_wave() -> void:
	_wave_active = false
	_wave_timer = time_between_waves
	_notify_wave_end.rpc(current_wave)

func _get_weighted_enemy() -> PackedScene:
	if enemy_weights.is_empty() or enemy_weights.size() != enemies.size():
		return enemies[randi() % enemies.size()]
	var total := 0
	for w in enemy_weights:
		total += w
	var roll = randi() % total
	var cumulative := 0
	for i in enemies.size():
		cumulative += enemy_weights[i]
		if roll < cumulative:
			return enemies[i]
	return enemies[0]

# Notify all clients about wave state for UI
@rpc("authority", "call_local", "reliable")
func _notify_wave_start(wave_num: int, size: int) -> void:
	SignalBus.wave_started.emit(wave_num, size)

@rpc("authority", "call_local", "reliable")
func _notify_wave_end(wave_num: int) -> void:
	SignalBus.wave_ended.emit(wave_num)

@rpc("authority", "call_local", "reliable")
func _notify_enemies_remaining(count: int) -> void:
	SignalBus.enemies_remaining.emit(count)
