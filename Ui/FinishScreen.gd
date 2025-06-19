extends Control


export (PackedScene) var mainmenu

export var win_text = "You are Victorious!"
export var lose_text = "Failure is not an Option"
export var tie_text = "Try just a little bit harder next time."

func _ready():
	if Game.has_won == "win":
		$Text.text = win_text
	elif Game.has_won == "lose":
		$Text.text = lose_text
	elif Game.has_won == "tie":
		$Text.text = tie_text
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_Button_pressed():
	var _blah = get_tree().change_scene_to(mainmenu)
