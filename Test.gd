extends Node2D


var lerped_angle = 0
var turn = true
var anim = "straight"



func _process(delta):
	face(get_global_mouse_position())



func face(pos=Vector2(), anim_name="straight"):
	
	var angle = pos.angle_to_point(self.position)
	
	if turn == true:
		var prev_rot = $total_rot.rotation_degrees
		
		$total_rot.look_at(pos)
		
		var curr_rot = $total_rot.rotation_degrees
		
		if curr_rot < prev_rot:
			anim = "left"
			$Turnout.start()
		elif curr_rot > prev_rot:
			anim = "right"
			$Turnout.start()
		
		anim_name = anim
	
	lerped_angle = lerp_angle(lerped_angle, angle, 0.3)
	
	lerped_angle = deg2rad(lmt(rad2deg(lerped_angle), 360))
	
	
	$Texture.animation = anim_name
	$Shadow.animation = "straight"
	$Texture/Flash.animation = anim_name
	var frame = float(int((rad2deg(lerped_angle)/22.5 + 4.5) + 16))
	
	frame = lmt(frame, 32)
	
	$Texture.frame = frame
	$Shadow.frame = frame
	$Texture/Flash.frame = frame



