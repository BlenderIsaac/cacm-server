extends Node2D


func _ready():
	$anim1.playing = true
	$anim1.frame = 0
	
	$anim2.playing = true
	$anim2.frame = 0


func _process(delta):
	if $anim2.frame == 21:
		queue_free()
