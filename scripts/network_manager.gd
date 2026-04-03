# network_manager.gd
extends Node

@onready var sync: MultiplayerSynchronizer = $"../MultiplayerSynchronizer"
@onready var health: HealthComponent = $"../HealthComponent"
@onready var player = get_parent()

func _ready():
	sync.synchronized.connect(_on_synchronized)

func _on_synchronized():
	# health value just updated from network
	health.health_changed.emit(health.health, health.max_health)
	
	# check death on all peers
	if health.health <= 0:
		health.died.emit()
