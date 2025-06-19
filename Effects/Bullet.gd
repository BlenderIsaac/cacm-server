extends Area2D

var Speed = 7
var target = null
var damage = 25
var faction = "astro"
var sound_name = "INT_guntower_"
var disabled = false

var sound_finished = false
var damage_sound_finished = false

onready var b2 = preload("res://Textures/weapons/rocket_evil.png")


func _ready():
	if faction == "alien":
		$Sprite.texture = b2
	
	$Shoot.stream = load(str("res://Sounds/sfx/", sound_name, int(rand_range(1, 4)), ".ogg"))
	$Damage.stream = load(str("res://Sounds/sfx/", target.damage_sound, int(rand_range(1, 3)), ".ogg"))


func _process(_delta):
	if disabled == false:
		position += Vector2(0, -Speed*_delta*60).rotated(rotation)
	else:
		
		if sound_finished == true and damage_sound_finished == true:
			queue_free()
	


func hit_somthin(body):
	if target and disabled == false:
		if body == target:
			body.change_health(-damage)
			disabled = true
			$Damage.play()
			hide()
			
			for p in gamestate.players.keys():
				if gamestate.players.get(p)[1] == get_parent().get_parent().GAME:
					rpc_id(p, "hit_somthin")


func _on_Timer_timeout():
	queue_free()


func _on_Shoot_finished():
	sound_finished = true


func _on_Damage_finished():
	damage_sound_finished = true
