extends Button

export (PackedScene) var level_loaded
export var cutscene = preload("res://Ui/Cutscene.tscn")


func _ready():
	$Flash.play("Pulse")


func _process(delta):
	
	if pressed:
		Game.setup()
		Game.played = level_loaded
		
		var _blah = get_tree().change_scene_to(cutscene)
	
	
	if disabled == true:
		$Text.set("custom_colors/font_color", Color("5c5c5c"))
		$arra_on.hide()
		$arra_off.hide()
		$arra_on2.hide()
		$arra_off2.hide()
	else:
		$Text.set("custom_colors/font_color", Color("000000"))
		$arra_on.show()
		$arra_off.show()
		$arra_on2.show()
		$arra_off2.show()
	
	
	if is_hovered():
		$Flash.seek(0, true)
		
		if not disabled:
			$Text.set("custom_colors/font_color", Color("ffffff"))
