extends Resource
class_name WeaponData

@export var weapon_name: String = "Pistol"
@export var bullet_scene: PackedScene
@export var max_ammo: int = 10
@export var fire_rate: float = 0.2
@export var reload_time: float = 1.5
@export var damage: int = 10
@export var bullet_speed: float = 800.0
@export var bullets_per_shot: int = 1      # 1 for pistol, 5 for shotgun
@export var spread_angle: float = 0.0      # degrees, 0 for pistol, 15 for shotgun
@export var is_automatic: bool = false     # hold to shoot or click
@export var shoot_sound: SoundData
@export var reload_sound: SoundData
@export var weapon_sprite: Texture2D  
