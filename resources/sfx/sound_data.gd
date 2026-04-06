# sound_data.gd
extends Resource
class_name SoundData

@export var stream: AudioStream
@export var volume_db: float = 0.0
@export var pitch_min: float = 1.0  # randomize pitch for variety
@export var pitch_max: float = 1.0
@export var max_distance: float = 800.0
