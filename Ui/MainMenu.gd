extends Control


export (PackedScene) var played
export (PackedScene) var custom

export var cutscene = preload("res://Ui/Cutscene.tscn")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func start():
	
	Game.setup()
	Game.played = played
	
	var _blah = get_tree().change_scene_to(cutscene)


func custom_start():
	
	Game.setup()
	Game.played = custom
	
	var _blah = get_tree().change_scene_to(cutscene)


func level_editor():
	var _blah_blah = get_tree().change_scene_to(load("res://Level Editor/LevelEditor.tscn"))

