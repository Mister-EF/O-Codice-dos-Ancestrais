## Boot scene — routes to the correct screen after autoloads are ready.
## MainMenu → FactionSelect (first run) → WorldMap (returning player).
extends Control


func _ready() -> void:
	# Wait one frame so all autoloads finish _ready()
	await get_tree().process_frame
	_route()


func _route() -> void:
	if GameManager.has_save() and GameManager.has_chosen_faction():
		SceneManager.change_scene("res://ui/world_map/world_map.tscn")
	elif GameManager.has_save() and not GameManager.has_chosen_faction():
		SceneManager.change_scene("res://ui/faction_select/faction_select.tscn")
	else:
		SceneManager.change_scene("res://ui/main_menu/main_menu.tscn")
