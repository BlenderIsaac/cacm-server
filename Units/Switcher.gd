extends "res://Units/Unit.gd"

export var ascension_speed = 2.0
var height = 0

onready var tilemap = get_parent().get_parent().get_node("Navigation2D/Tiles")


func travel(pos, deviation, time_to_board=false, play_sound=false):
	
	if can_move == true:
		
		if play_sound == true:
			if faction == Game.level().faction:
				$Move.play()
		
		
		var nav = get_tree().get_nodes_in_group("nav")[0]
		
		if flying:
			path = [global_position, nav.get_closest_point(pos+Vector2(rand_range(-deviation, deviation), rand_range(-deviation, deviation)))]
		else:
			path = nav.get_simple_path(global_position, nav.get_closest_point(pos+Vector2(rand_range(-deviation, deviation), rand_range(-deviation, deviation))))
		
		target = pos
	
	if not time_to_board == true:
		boarding_carrier = false



func _process_special(delta):
	
	$Col.position.y = $Texture.position.y
	
	if target:
		flying = true
	else:
		flying = false
	
	
	if flying == true:
		
		if height > 0:
			height -= delta*ascension_speed
		
		if height > 1:
			height = 1
		
	else:
		
		if height < 1:
			height += delta*ascension_speed
		
		if height < 0:
			height = 0
	
	$updown.play("flying")
	$updown.seek(height, true)
	
	
	var anim = "fly"
	
	if height > .9:
		anim = "straight"
	elif height > .01:
		anim = "land"
	
	var temp = $Texture.frame
	
	if $Texture.animation == "left" or $Texture.animation == "right":
		if not anim == "fly":
			$Texture.animation = anim
	else:
		$Texture.animation = anim
	
	$Shadow.animation = anim
	$Shadow.frame = temp
	$Texture.frame = temp
	
	if type == "AlienInfiltrator":
		if anim == "fly":
			$Texture/Light.offset = Vector2()
		elif anim == "land":
			$Texture/Light.offset = Vector2(0, -35)
		else:
			$Texture/Light.offset = Vector2()



