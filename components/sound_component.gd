# sound_component.gd
extends Node
class_name SoundComponent

@export var sounds: Dictionary = {}

func play_sound(sound_name: String) -> void:
	if not is_multiplayer_authority():
		return
	_play_sound_rpc.rpc(sound_name, get_parent().global_position)

func play_sound_data(data: SoundData, world_pos: Vector2) -> void:
	if not is_multiplayer_authority():
		return
	_play_sound_data_rpc.rpc(data.resource_path, world_pos)

@rpc("any_peer", "call_local", "reliable")
func _play_sound_rpc(sound_name: String, world_pos: Vector2) -> void:
	if not sounds.has(sound_name):
		return
	_spawn_audio_player(sounds[sound_name], world_pos)

@rpc("any_peer", "call_local", "reliable")
func _play_sound_data_rpc(resource_path: String, world_pos: Vector2) -> void:
	var data = load(resource_path) as SoundData
	if not data:
		return
	_spawn_audio_player(data, world_pos)

# Shared helper so both RPCs use the same spawning logic
func _spawn_audio_player(data: SoundData, world_pos: Vector2) -> void:
	if not data or not data.stream:
		return
	var player = AudioStreamPlayer2D.new()
	player.stream = data.stream
	player.volume_db = data.volume_db
	player.pitch_scale = randf_range(data.pitch_min, data.pitch_max)
	player.max_distance = data.max_distance
	player.global_position = world_pos
	player.finished.connect(player.queue_free)
	get_tree().current_scene.add_child(player)
	player.play()
