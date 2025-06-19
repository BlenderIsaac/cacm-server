extends "res://Units/Unit.gd"


var hq = null
var controlled = false
var mining_anim = false
var returning = false
var mining = false # Is currently mining a tile

# Our current money stored in our little money banks
export var money_supply = 0.0
# What thing we drop off the money to
export var dropoff_points = ["EagleCommandBase", "AlienMothership"]
export var dropoff_group = "Building"
export var dropoff_dist = 40.0
# Distance you should social distance
export var social_distancing = 48.0
# The maximum amount of money we can store in our little money banks
export var max_money = 1000.0
# Amount of time it takes to mine
export var mine_time = {
	"min" : 1.7,
	"max" : 4.6,
}


func _ready_special():
	set_hq()


remote func dropoff(hq_id):
	returning = true
	hq = get_parent().get_node(hq_id)
	mining = false
	controlled = false
	half_controlled = false
	target = null


func set_hq():
	
	if hq and is_instance_valid(hq):
		pass
	else:
		for building in get_tree().get_nodes_in_group(dropoff_group):
			if dropoff_points.has(building.type):
				if building.faction == faction:
					hq = building
					break
	
	if not hq:
		die()


func _process_special(delta):
	
	if controlled:
		mining_anim = false
	else:
		
		
		if not returning:
			if money_supply >= max_money:
				money_supply = max_money
				returning = true
				mining_anim = true
				
			else:
				# We are gonna mine
				if target:
					# If we are traveling
					pass
				else:
					# If we are stationary
					half_controlled = false
					if not mining:
						if can_mine():
							mine()
						else:
							var next_tile = find_crystal_tile()
							
							if next_tile:
								travel(map_to_world(next_tile), 5, false, false, false, false)
							else:
								returning = true
								controlled = true
						mining_anim = false
					else:
						mining_anim = true
		else:
			# We are returning to hq
			
			set_hq()
			
			if is_instance_valid(hq):
				if hq.global_position.distance_to(global_position) <= 40:
					Game.level().add_money(hq.faction, money_supply)
					money_supply = 0
					returning = false
			
			
				if not target:
					travel(hq.global_position, 0, false, false, false, false)
			
			mining_anim = false
			mining = false
	
	
	
	if mining_anim == true:
		$Texture/sparks.modulate.a = rand_range(0, 1)
	else:
		$Texture/sparks.modulate.a = 0



func find_crystal_tile():
	
	var ret = null
	
	var c = Game.tilemap
	var crystal_tiles = c.get_used_cells_by_id(1)
	var units = get_tree().get_nodes_in_group("Unit")
	var miners = []
	
	# get miners
	for unit in units:
		if not unit == self:
			if unit.has_method("mine"):
				if unit.get_parent() == get_parent():
					if unit.faction == faction:
						miners.append(unit)
	
	
	# find closest tile
	if crystal_tiles:
		
		var closest = crystal_tiles[0]
		var backup = crystal_tiles[0]
		
		for tile in crystal_tiles:
			if map_to_world(tile).distance_to(global_position) < map_to_world(closest).distance_to(global_position):
				if not c.get_cell_autotile_coord(tile.x, tile.y) == Vector2(0, 3):
					
					var miner_near = false
					
					for miner in miners:
						if miner.global_position.distance_to(map_to_world(tile)) <= social_distancing:
							miner_near = true
							break
					
					if miner_near == false:
						closest = tile
					
					backup = tile
					
		if closest:
			ret = closest
		else:
			ret = backup
	
	
	return ret


func map_to_world(tile):
	return tile*Vector2(96, 48)+Vector2(48, 24)


func mine():
	var c = Game.tilemap
	
	var tile = c.world_to_map(global_position)
	
	if c.get_cellv(tile) == 1:
		if not c.get_cell_autotile_coord(tile.x, tile.y).y > 2:
			if mining == false:
				$MiningAway.wait_time = rand_range(mine_time.min, mine_time.max)
				$MiningAway.start()
				mining = true
				mining_anim = true



func can_mine():
	var ret = false
	
	var c = Game.tilemap
	
	var tile = c.world_to_map(global_position)
	
	if c.get_cellv(tile) == 1:
		if not c.get_cell_autotile_coord(tile.x, tile.y).y > 2:
			ret = true
	
	
	return ret


func traveling(delta):
	if path.size() > 1:
		
		if global_position.distance_to(path[1]) <= 3:
			path.remove(1)
			
			if not controlled:
				if not returning:
					if not money_supply >= max_money:
						if half_controlled == false:
							
							var next_tile = find_crystal_tile()
							
							
							if next_tile:
								if not next_tile*Vector2(96, 48)+Vector2(48, 24) == target:
									travel(next_tile*Vector2(96, 48)+Vector2(48, 24), 5, false, false, false, false)
			
			
			
			
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
					if not walking:
						anim = "straight"
		
		
		
		if path.size() > 1:
			face(path[1], anim)
			
			position += Vector2(-(speed*delta*60), 0).rotated(position.angle_to_point(path[1]))
		else:
			
			pursuing_nemesis = false
			
			target = null
	
	
	
	if target:
		$target.show()
		if not nemesis:
			$target.points[1] = target - position
		else:
			if is_instance_valid(nemesis):
				$target.points[1] = nemesis.global_position - position
		$target.points[0] = $Texture.position + $Texture.offset
		$Line2D.points = path
		$Line2D.global_position = Vector2()
	else:
		$target.hide()
		
	
	if not selected:
		$target.hide()



func _on_SANITY_timeout():
	if mining_anim == true:
		$Mine.play()
	
	randomize()
	
	$SANITY.wait_time = rand_range(2, 4)
	$SANITY.start()


var half_controlled = false


func travel(pos, deviation, time_to_board=false, play_sound=false, cancel_action=true, cursor=false):
	
	if cancel_action == true:
		controlled = true
		returning = false
		mining = false
	
	
	if can_move == true:
		
		if cursor == true:
			
			var c = Game.tilemap
			
			var tile = c.world_to_map(pos)
			
			if c.get_cellv(tile) == 1:
				if not c.get_cell_autotile_coord(tile.x, tile.y).y > 2:
					
					controlled = false
					half_controlled = true
					returning = false
		
		var nav = get_tree().get_nodes_in_group("nav")[0]
		if not flying:
			path = nav.get_simple_path(global_position, nav.get_closest_point(pos+Vector2(rand_range(-deviation, deviation), rand_range(-deviation, deviation))))
		else:
			path = [global_position, nav.get_closest_point(pos+Vector2(rand_range(-deviation, deviation), rand_range(-deviation, deviation)))]
		
		
		target = pos
	
	if not time_to_board == true:
		boarding_carrier = false


func _on_MiningAway_timeout():
	if can_mine():
		
		var c = Game.tilemap
		
		var tile = c.world_to_map(global_position)
		
		var prev_coord = c.get_cell_autotile_coord(tile.x, tile.y)
		
		c.set_cell(tile.x, tile.y, 1, false, false, false, Vector2(0, prev_coord.y+1))
		
		for player in gamestate.players.keys():
			
			if gamestate.players.get(player)[1] == get_parent().get_parent().get_parent().name:
				
				get_parent().get_parent().rpc_id(player, "set_crystal_stage", tile, c.get_cell_autotile_coord(tile.x, tile.y).y)
		
		mining = false
		money_supply += 100

