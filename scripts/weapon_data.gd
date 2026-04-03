extends Resource
class_name WeaponData

@export var damage: int = 10
@export var fire_rate: float = 0.5
@export var bullet_speed: float = 600.0
@export var bullet_scene: PackedScene 
@export var max_ammo: int = 8
@export var reload_time: float = 1.5

@export var shoot_sound: SoundData
