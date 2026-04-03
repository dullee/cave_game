extends Node

class_name WeaponComponent

@onready var input_manager: InputManager = $"../InputManager"

@onready var sound_component: SoundComponent = $"../SoundComponent"
@export var data: WeaponData
@onready var pivot_arm: Node2D = $"../pivot_arm"
@onready var muzzle: Marker2D = $"../pivot_arm/muzzle"

signal ammo_changed(current: int, max_ammo: int)

var can_shoot = true
var current_ammo: int
var reload_time: float
var is_reloading := false
#------------------------test----------------------
var dynamite = preload("res://entities/weapons/dynamite.tscn")
#----------------------------------------------------
func _ready() -> void:
	SignalBus.input_disabled.connect(_on_inputs_disabled)
	current_ammo = data.max_ammo
	reload_time = data.reload_time

func _unhandled_input(_event: InputEvent) -> void:
	if not is_multiplayer_authority() or not input_manager.is_enabled():
		return
	if input_manager.is_action_just_pressed("mouse_2"):
		_throw_item.rpc()
	if input_manager.is_action_just_pressed("r") and not is_reloading and current_ammo < data.max_ammo:
		reload()
		print("reloading")
		
func _process(_delta: float) -> void:
	if not is_multiplayer_authority() :
		return
	if input_manager.is_action_pressed("mouse_1") and can_shoot and current_ammo > 0:
		_do_shoot()
		print("shooting")
		
	if current_ammo <= 0 and not is_reloading:  # ← guard here too
		reload()
	
func _do_shoot():
	current_ammo -= 1
	ammo_changed.emit(current_ammo, data.max_ammo)
	can_shoot = false
	sound_component.play_sound("shoot")
	_spawn_bullet.rpc(muzzle.global_position, muzzle.global_transform.x)
	await get_tree().create_timer(data.fire_rate).timeout
	if not is_reloading: can_shoot = true

@rpc("any_peer", "call_local", "reliable")
func _spawn_bullet(pos: Vector2, dir: Vector2) -> void:
	if not data or not data.bullet_scene:
		return
	var bullet = data.bullet_scene.instantiate()
	bullet.global_position = pos
	bullet.direction = dir
	get_tree().current_scene.add_child(bullet)

func reload():
	if not is_multiplayer_authority():
		return
	is_reloading = true
	can_shoot = false
	sound_component.play_sound("reload")
	await get_tree().create_timer(reload_time).timeout
	current_ammo = data.max_ammo
	ammo_changed.emit(current_ammo, data.max_ammo)
	is_reloading = false
	await get_tree().create_timer(data.fire_rate).timeout
	can_shoot = true
	
@rpc("any_peer", "call_local", "reliable")
func _throw_item():
	var dynamite_instance = dynamite.instantiate()
	dynamite_instance.global_position = pivot_arm.global_position
	dynamite_instance.direction = muzzle.global_transform.x
	get_tree().root.add_child(dynamite_instance)
	
func _on_inputs_disabled() -> void:
	set_process(false)
	set_process_unhandled_input(false)
