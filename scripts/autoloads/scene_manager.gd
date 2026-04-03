extends Node

const LOADING_MENU = "res://UI/loading_menu.tscn"
const START_MENU = "res://UI/start_menu.tscn"
const GAME_WORLD = "res://scenes/world/world.tscn"
const SETTINGS_MENU = preload("res://UI/options_menu.tscn")
const PAUSE_MENU = preload("res://UI/pause_menu.tscn")
const DEATH_SCREEN = preload("res://UI/death_screen.tscn")

func open_loading_menu():
	get_tree().change_scene_to_file(LOADING_MENU)

func open_game_world():
	get_tree().change_scene_to_file(GAME_WORLD)

func back_to_start_menu():
	get_tree().change_scene_to_file(START_MENU)

func open_settings():
	_open_overlay(SETTINGS_MENU)
	
func open_pause():
	_open_overlay(PAUSE_MENU)

func open_death_screen():
	_open_overlay(DEATH_SCREEN)

func _open_overlay(scene: PackedScene):
	var overlay = scene.instantiate()
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	canvas.add_child(overlay)
	overlay.tree_exited.connect(canvas.queue_free)
