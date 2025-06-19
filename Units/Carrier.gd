extends "res://Units/Unit.gd"

export var carry_amount = 1
var carrying = []
export(Array, String) var carriable = [
		"Infantry",
		"Drone",
		"Saboteur",
		"Engineer",
		"AstroCommander",
		"AlienCommander",
		"Viper",
		"JetpackExplorer",
		"Santa",
		"Reindeer",
		]
export var spawn_distance = 40
export var ascension_speed = 1.0
export var lander = false
export var pickup_range = 20

var height = 0

onready var tilemap = get_parent().get_parent().get_node("Navigation2D/Tiles")

remote func deploy():
	if can_deploy():
		for unit in carrying:
			
			var game = get_parent().get_parent().get_parent().name
			var w = get_parent().get_parent().get_parent().get_parent()
			
			var offset = Vector2(rand_range(-100, 100), rand_range(-100, 100)).normalized() * spawn_distance
			var pos = tilemap.get_parent().get_closest_point(self.global_position + offset)
			
			var unit_id = gamestate.obj_id
			gamestate.obj_id += 1
			
			for player in gamestate.players.keys():
				if player_in_my_game(player):
					w.rpc_id(player, "spawn_unit", pos, unit[0], str(unit_id), unit[1], unit[2], faction)
			
			w.spawn_unit(pos, unit[0], str(unit_id), game, unit[1], unit[2], faction)
		
		carrying.clear()
		flash("ffffff")
		
		for player in gamestate.players.keys():
			if player_in_my_game(player):
				rpc_id(player, "flash", "ffffff")
				rset_id(player, "carrying", carrying)



func can_deploy():
	var ret = false
	
	if height >= .9 or lander == false:
		ret = true
	
	return ret




func can_carry(unit):
	
	var ret = false
	
	if unit:
		if unit.faction == self.faction:
			if carriable.has(unit.type):
				if carrying.size() < carry_amount:
					if height >= .9 or lander == false:
						if not unit == self:
							ret = true
	
	
	return ret



func carry(unit):
	flash("ffffff")
	
	for player in gamestate.players.keys():
		if player_in_my_game(player):
			rpc_id(player, "flash", "ffffff")
	
	var list = [
		unit.type,
		unit.max_health,
		unit.health,
	]
	
	carrying.append(list)
	
	
	
	for player in gamestate.players.keys():
		if player_in_my_game(player):
			unit.rpc_id(player, "die", false)
			rset_id(player, "carrying", carrying)
	
	unit.die(false)



func travel(pos, deviation, time_to_board=false, play_sound=false):
	
	if can_move == true:
		
		if play_sound == true:
			$Move.play()
		
		
		var nav = get_tree().get_nodes_in_group("nav")[0]
		
		if flying or lander:
			path = [global_position, nav.get_closest_point(pos+Vector2(rand_range(-deviation, deviation), rand_range(-deviation, deviation)))]
		else:
			path = nav.get_simple_path(global_position, nav.get_closest_point(pos+Vector2(rand_range(-deviation, deviation), rand_range(-deviation, deviation))))
		
		target = pos
	
	if not time_to_board == true:
		boarding_carrier = false



func _process_special(delta):
	
	$Col.position.y = $Texture.position.y
	
	if lander == true:
		if target:
			flying = true
		else:
			# check if we are hovering over ground
			#if lands_on.has(tilemap.get_cellv(tilemap.world_to_map(global_position))):
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
		
		for player in gamestate.players.keys():
			if gamestate.players.get(player)[1] == get_parent().get_parent().get_parent().name:
				rset_unreliable_id(player, "height", height)
		
		$updown.play("flying")
		$updown.seek(height, true)



