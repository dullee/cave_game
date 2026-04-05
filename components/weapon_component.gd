extends Node

class_name WeaponComponent

@onready var input_manager: InputManager = $"../InputManager"

@onready var sound_component: SoundComponent = $"../SoundComponent"
@export var data: WeaponData
@onready var pivot_arm: Node2D = $"../pivot_arm"
@onready var muzzle: Marker2D = $"../pivot_arm/muzzle"
@onready var muzzle_flash_particle: GPUParticles2D = $"../pivot_arm/muzzle/MuzzleFlashParticle"
@onready var gun_sprite: Sprite2D = $"../pivot_arm/muzzle/GunSprite"

@export var starting_weapons: Array[WeaponData] = []
var current_weapon_index := 0

signal ammo_changed(current: int, max_ammo: int)
signal reload_started(duration: float)
signal reload_finished

var can_shoot = true
var current_ammo: int
var reload_time: float
var is_reloading := false
#------------------------test----------------------
var dynamite = preload("res://entities/weapons/dynamite.tscn")
#----------------------------------------------------
func _ready() -> void:
	if starting_weapons.size() > 0:
		equip(starting_weapons[0])

func _unhandled_input(_event: InputEvent) -> void:
	if not is_multiplayer_authority() or not input_manager.is_enabled():
		print("not auth or input disabled")
		return
	if not data:  # ← guard at top
		print("no weapon data")
		return

	if input_manager.is_action_just_pressed("r") and not is_reloading and current_ammo < data.max_ammo:
		reload()
	if input_manager.is_action_just_pressed("1") and starting_weapons.size() > 0:
		equip(starting_weapons[0])
	if input_manager.is_action_just_pressed("2") and starting_weapons.size() > 1:
		equip(starting_weapons[1])
		
func _process(_delta: float) -> void:
	if not is_multiplayer_authority() or not input_manager.is_enabled():
		return
	if not data:  # ← guard at top
		return
	var shoot_input = input_manager.is_action_pressed("mouse_1") if data.is_automatic \
				   else input_manager.is_action_just_pressed("mouse_1")
	if shoot_input and can_shoot and current_ammo > 0 and not is_reloading:
		_do_shoot()
	if current_ammo <= 0 and not is_reloading:
		reload()
	if input_manager.is_action_just_pressed("mouse_2"):
		_throw_item.rpc()
		print("input m2")
		
func equip(new_data: WeaponData) -> void:
	data = new_data
	initialize()

func initialize() -> void:
	current_ammo = data.max_ammo
	reload_time = data.reload_time
	can_shoot = true
	is_reloading = false
	ammo_changed.emit(current_ammo, data.max_ammo)
	gun_sprite.texture = data.weapon_sprite
	
func _do_shoot():
	if not data:  # ← guard
		return
	current_ammo -= 1
	ammo_changed.emit(current_ammo, data.max_ammo)
	can_shoot = false
	if data.shoot_sound:
		sound_component.play_sound_data(data.shoot_sound, get_parent().global_position)
	for i in data.bullets_per_shot:
		var spread = 0.0
		if data.bullets_per_shot > 1:
			var t = float(i) / float(data.bullets_per_shot - 1)
			spread = lerp(-data.spread_angle, data.spread_angle, t)
		var dir = muzzle.global_transform.x.rotated(deg_to_rad(spread))
		_spawn_bullet.rpc(muzzle.global_position, dir)
	await get_tree().create_timer(data.fire_rate).timeout
	if not is_reloading:
		can_shoot = true

@rpc("any_peer", "call_local", "reliable")
func _spawn_bullet(pos: Vector2, dir: Vector2) -> void:
	if not data or not data.bullet_scene:
		return
	var bullet = data.bullet_scene.instantiate()
	bullet.global_position = pos
	bullet.direction = dir
	get_tree().current_scene.add_child(bullet)

func reload():
	if not is_multiplayer_authority() or not data:
		return
	is_reloading = true
	can_shoot = false
	if data.reload_sound:
		sound_component.play_sound_data(data.reload_sound, get_parent().global_position)
	reload_started.emit(data.reload_time)
	await get_tree().create_timer(reload_time).timeout
	reload_finished.emit()
	current_ammo = data.max_ammo
	ammo_changed.emit(current_ammo, data.max_ammo)
	is_reloading = false
	can_shoot = true
	
@rpc("any_peer", "call_local", "reliable")
func _throw_item():
	print("throwing item")
	var dynamite_instance = dynamite.instantiate()
	dynamite_instance.global_position = pivot_arm.global_position
	dynamite_instance.direction = muzzle.global_transform.x
	get_tree().current_scene.add_child(dynamite_instance)
	
