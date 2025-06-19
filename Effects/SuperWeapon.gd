extends Node2D

onready var Game = get_parent().get_parent().get_parent()

export (PackedScene) var superscorch
export var _damage = -1000
export var ran = 100

var done_it = false



func _ready():
	get_parent().get_parent().get_node("Camera").shake += 150



func damage():
	if done_it == false:
		var s = superscorch.instance()
		
		get_parent().add_child(s)
		
		s.global_position = global_position + Vector2(0, 1)
		
		done_it = true
	
	
	var damageables = get_tree().get_nodes_in_group("Unit") + get_tree().get_nodes_in_group("Building")
	
	for damageable in damageables:
		if damageable.get_parent() == get_parent():
			if Game.in_oval(global_position, damageable.global_position, ran/2, ran):
				
				var distance = Game.ovular_distance_to(global_position, damageable.global_position, ran/2, ran)
				
				var d = abs(distance-1)
				
				
				damageable.change_health(d*_damage, true)
	
	for box in get_tree().get_nodes_in_group("nukesmash"):
		if box.get_parent() == get_parent():
			if Game.in_oval(global_position, box.global_position, ran/2, ran):
				
				box.die()



func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "default":
		queue_free()
