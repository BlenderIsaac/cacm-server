extends "res://Units/Unit.gd"

# These variables are probably so confusing :S

# wether we are not journeying to find a crystal
var currently_mining = false
# Which tile we are mining
var tile_mining
# If the animation for mining is happening
var mining = false
# If we are currently looking for things to mine
var is_mining = true

# Our current money stored in our little money banks
export var money_supply = 0

# If we are going to the hq
var going_to_hq = false


# What building we drop off the money to
export var dropoff_point = "EagleCommandBase"
# The maximum amount of money we can store in our little money banks
export var max_money = 1000



func _process_special(delta):
	
	if is_mining:
		if currently_mining == false:
			tile_mining = find_crystal_tile()
			
			if tile_mining:
				currently_mining = true
				travel(Game.tilemap.map_to_world(tile_mining) + Vector2(48, 24), 0)
			else:
				# Find the hq
				var hq = null
				
				# loop through all buildings
				for building in get_tree().get_nodes_in_group("Building"):
					# If the building is the correct one, then set hq to that building
					if building.type == dropoff_point:
						hq = building
				
				# Check if there was an hq
				if hq:
					# Set is_mining to false, which means it no longer seeks crystals
					is_mining = false
					# travel to the hq's global position
					travel(hq.global_position, 0)
					# turn going_to_hq on
					going_to_hq = true
				else:
					# If we don't have an hq blow up from loneliness
					die()
			
				# Turn the mining animation off
				mining = false
				# Make so we are no longer currently mining
				currently_mining = false
	else:
		mining = false
	
	if mining == true:
		$Texture/sparks.modulate.a = rand_range(0, 1)
	else:
		$Texture/sparks.modulate.a = 0
	
	$Mine.stream_paused = invert(mining)


func invert(boolean):
	var ret = true
	
	if boolean == true:
		ret = false
	
	return ret


func find_crystal_tile():
	
	var ret = null
	
	var c = Game.tilemap
	var crystal_tiles = c.get_used_cells_by_id(1)
	
	
	# find closest tile
	var closest = null
	for tile in crystal_tiles:
		if not closest == null:
			if c.map_to_world(tile).distance_to(global_position) < c.map_to_world(closest).distance_to(global_position):
				if not c.get_cell_autotile_coord(tile.x, tile.y) == Vector2(0, 3):
					closest = tile
		else:
			if not c.get_cell_autotile_coord(tile.x, tile.y) == Vector2(0, 3):
				closest = tile
	ret = closest
	
	
	
	return ret



func traveling(delta):
	
	if path.size() > 1:
		if global_position.distance_to(path[1]) <= 3:
			path.remove(1)
			
			
			if path.size() > 1:
				
				if turn:
					var pos = path[1].angle_to_point(self.position)
					
					if lerped_angle == pos:
						anim = "straight"
					elif lerped_angle < pos:
						anim = "right"
					elif lerped_angle > pos:
						anim = "left"
					$TurnCooldown.start()
				else:
					anim = "straight"
		
		
		
		if path.size() > 1:
			face(path[1], anim)
			
			position += Vector2(-(speed*60*delta), 0).rotated(position.angle_to_point(path[1]))
		else:
			
			pursuing_nemesis = false
			
			if is_mining:
				# mine the tile
				if currently_mining == true:
					mining = true
					$MiningAway.wait_time = rand_range(3, 5)
					$MiningAway.start()
					
			else:
				if going_to_hq == true:
					if at_hq():
						Game.level().add_money(get_hq().faction, money_supply)
						money_supply = 0
						is_mining = true
						going_to_hq = false
					else:
						# Find the hq
						var hq = get_hq()
						
						# Check if there was an hq
						if hq:
							# Set is_mining to false, which means it no longer seeks crystals
							is_mining = false
							# travel to the hq's global position
							travel(hq.global_position, 0)
							# turn going_to_hq on
							going_to_hq = true
			
	
	
	
	if target:
		$target.show()
		$target.points[1] = target - position
		$target.points[0] = $Texture.position + $Texture.offset
		$Line2D.points = path
		$Line2D.global_position = Vector2()
	else:
		$target.hide()
	
	
	if not selected:
		$target.hide()



func get_hq():
	var hq = null
	
	# loop through all buildings
	for building in get_tree().get_nodes_in_group("Building"):
		# If the building is the correct one, then set hq to that building
		if building.type == dropoff_point:
			if building.faction == faction:
				hq = building
	
	if not hq:
		# If we don't have an hq blow up from loneliness
		die()
	
	return hq



func at_hq():
	
	var hq = get_hq()
	
	var ret = false
	
	if hq:
		if hq.global_position.distance_to(global_position) <= 10:
			ret = true
	else:
		die(true)
	
	return ret



func travel(pos, deviation, time_to_board=false, play_sound=false):
	if can_move == true:
		
		$MiningAway.stop()
		mining = false
		
		if play_sound == true:
			if faction == Game.level().faction:
				$Move.play()
		
		
		if not flying:
			var nav = get_tree().get_nodes_in_group("nav")[0]
			path = nav.get_simple_path(global_position, pos+Vector2(rand_range(-deviation, deviation), rand_range(-deviation, deviation)))
		else:
			path = [global_position, pos]
		
		target = pos
		
		if not time_to_board == true:
			boarding_carrier = false


func _on_MiningAway_timeout():
	
	# set tile to the tile we are on
	var tile = Game.tilemap.world_to_map(target)
	
	# If tile is a crystal tile
	if Game.tilemap.get_cell(tile.x, tile.y) == 1:
		
		# get the previous stage of the tile
		var previous_stage = Game.tilemap.get_cell_autotile_coord(tile.x, tile.y).y
		
		# set the tile to the next stage down
		Game.tilemap.set_cell(tile.x, tile.y, 1, false, false, false, Vector2(0, previous_stage+1))
		
		# If the tile stage is greater than 4, (which is illegal), set it to an legal state
		if Game.tilemap.get_cell_autotile_coord(tile.x, tile.y).y > 3:
			Game.tilemap.set_cell(tile.x, tile.y, 1, false, false, false, Vector2(0, 3))
		
		# If the tile is not mined, add money to the supply
		if not Game.tilemap.get_cell_autotile_coord(tile.x, tile.y) == Vector2(0, 4):
			money_supply += 100
		
		# Check if we have the maximum amount in our little money banks
		if money_supply >= max_money:
			# Find the hq
			var hq = null
			
			# loop through all buildings
			for building in get_tree().get_nodes_in_group("Building"):
				# If the building is the correct one, then set hq to that building
				if building.type == dropoff_point:
					hq = building
			
			# Check if there was an hq
			if hq:
				# Set is_mining to false, which means it no longer seeks crystals
				is_mining = false
				# travel to the hq's global position
				travel(hq.global_position, 0)
				# turn going_to_hq on
				going_to_hq = true
			else:
				# If we don't have an hq blow up from loneliness
				die()
		
		# Turn the mining animation off
		mining = false
		# Make so we are no longer currently mining
		currently_mining = false
	


func _on_Mine_finished():
	$SANITY.start()


func _on_SANITY_timeout():
	$Mine.stream = load(str("res://Sounds/sfx/", bullet_sound, int(rand_range(1, 4)), ".ogg"))
	$Mine.play()
