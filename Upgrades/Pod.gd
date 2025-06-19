extends Node2D

export var money = 2000
export var spawns = ""
export var pickup_range = 50
export var heals = false
export var type = "Pod"

var blip
var collected = false

export var blip_colour = Color("ffffff")

onready var Game = get_parent().get_parent().get_parent()


func _process(_delta):
	
	for unit in get_tree().get_nodes_in_group("Unit"):
		if unit.flying == false:
			if unit.global_position.distance_to(global_position) <= pickup_range:
				collect(unit.faction, unit)
				if not collected:
					if heals:
						unit.health = unit.max_health


func die():
	
	for player in gamestate.players.keys():
		if gamestate.players.get(player)[1] == Game.name:
			rpc_id(player, "die")
	
	explode()
	
	queue_free()


onready var explosion = load("res://Effects/BOOM.tscn")

func explode():
	var e = explosion.instance()
	
	get_parent().add_child(e)
	e.global_position = get_node("Texture").global_position
	e.type = "puff"



func collect(fact, obj):
	
	if collected == false:
		Game.level().add_money(fact, money)
		
		if spawns:
			Game.get_parent().create_unit(position, spawns, fact, Game.name, false)
		
		if heals:
			obj.change_health(obj.max_health-obj.health)
		
		$SoundEffect.play()
		hide()
		
		if blip:
			blip.queue_free()
			blip = null
		
		for player in gamestate.players.keys():
			if gamestate.players.get(player)[1] == Game.name:
				rpc_id(player, "collect")
	
	collected = true


func _on_SoundEffect_finished():
	queue_free()

