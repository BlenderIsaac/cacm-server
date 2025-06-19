extends AnimatedSprite


var anim = "standard"

func _process(_delta):
	var cursor = get_tree().get_nodes_in_group("cursor")[0]
	global_position = get_global_mouse_position()
	cursor.global_position = cursor.get_global_mouse_position()
	anim = cursor.anim
	animation = anim
	
	
	var amount = 152
	if position.x <= amount:
		cursor.over_ui = true
	else:
		cursor.over_ui = false
	
	cursor.draw_group_select(cursor.group_origin)
	
	
	
	if Input.is_action_just_pressed("left_click"):
		if get_parent().get_parent().radars.size() > 0 and not get_parent().get_parent().get_power(Game.level().faction) == "disabled":
			if position.y > 40:
				if position.y < 160:
					if position.x > 15:
						if position.x < 135:
							
							get_parent().get_parent().get_node("Camera").pos = get_parent().get_node("Radar/RadarTiles").get_local_mouse_position()














