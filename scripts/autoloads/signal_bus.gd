extends Node

var _input_enabled := true

@warning_ignore("unused_signal") signal cave_generated
@warning_ignore("unused_signal") signal player_spawned
@warning_ignore("unused_signal") signal input_disabled
@warning_ignore("unused_signal") signal input_enabled
@warning_ignore("unused_signal") signal player_died(peer_id: int)
@warning_ignore("unused_signal") signal boss_spawned
@warning_ignore("unused_signal") signal boss_died
@warning_ignore("unused_signal") signal enemy_died
@warning_ignore("unused_signal") signal wave_started(wave_num: int, size: int)
@warning_ignore("unused_signal") signal wave_ended(wave_num: int)
@warning_ignore("unused_signal") signal enemies_remaining(count: int)
@warning_ignore("unused_signal") signal spawn_tiles_updated
@warning_ignore("unused_signal") signal show_interact_prompt(text: String)
@warning_ignore("unused_signal") signal hide_interact_prompt
@warning_ignore("unused_signal") signal item_picked_up(item_name: String)


func _ready() -> void:
	input_disabled.connect(func(): _input_enabled = false)
	input_enabled.connect(func(): _input_enabled = true)

func is_input_enabled() -> bool:
	return _input_enabled
