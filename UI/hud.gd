extends Control
class_name Hud

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel
@onready var ammo_count_label: Label = $AmmoCountLabel
@onready var cursor_layer: CanvasLayer = $"../CursorLayer"


func _ready() -> void:
	await get_tree().process_frame
	var player = get_parent().get_parent()
	var health_comp = player.get_health_component()
	var weapon_comp = player.get_weapon_component()
	weapon_comp.reload_started.connect(cursor_layer.show_reload)
	weapon_comp.reload_finished.connect(cursor_layer.show_cursor)
	
	if not health_comp:
		print(health_comp) 
	elif not weapon_comp:
		print(weapon_comp)
	else:
		
		health_comp.health_changed.connect(_on_health_changed)
		weapon_comp.ammo_changed.connect(_on_ammo_changed)
	
		health_bar.max_value = health_comp.max_health
		health_bar.value = health_comp.health
		ammo_count_label.text = str(weapon_comp.data.max_ammo) + "/" + str(weapon_comp.data.max_ammo)
	
func _on_health_changed(current: int, max_value: int):
	health_bar.value = current
	health_bar.max_value = max_value


func _on_ammo_changed(current: int, max_value: int):
	ammo_count_label.text = str(current) + "/" + str(max_value)
