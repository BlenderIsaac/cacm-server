extends Node2D


func _ready():
	if get_parent().get_parent().level_editor_exit == true:
		$bottom/Exit.show()
		$bottom/Resume.hide()
	else:
		$bottom/Exit.hide()
		$bottom/Resume.show()


func restart():
	Game.setup()
	
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit():
	get_tree().paused = false
	get_tree().change_scene_to(load("res://Ui/MainMenu.tscn"))


func resume():
	get_tree().paused = false
	$anims.play_backwards("default")
	Game.cursor.show()
	get_parent().get_node("Cursor").show()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func level_editor():
	get_tree().paused = false
	var _blah_blah = get_tree().change_scene_to(load("res://Level Editor/LevelEditor.tscn"))

