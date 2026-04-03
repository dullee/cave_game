# sound_component.gd
extends Node
class_name SoundComponent

@export var sounds: Dictionary = {}  # e.g. {"shoot": SoundData, "jump": SoundData}

func play_sound(sound_name: String) -> void:
	if not is_multiplayer_authority():
		return
	_play_sound_rpc.rpc(sound_name, get_parent().global_position)

@rpc("any_peer", "call_local", "reliable")
func _play_sound_rpc(sound_name: String, world_pos: Vector2) -> void:
	if not sounds.has(sound_name):
		return
	var data: SoundData = sounds[sound_name]
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
