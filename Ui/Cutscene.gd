extends Control



func _on_VideoPlayer_finished():
	get_tree().change_scene_to(Game.played)
