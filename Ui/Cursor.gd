extends AnimatedSprite

onready var Game = get_parent().get_parent()

var mode = "ready"
var anim = "standard"

var hover = null

var selected = []
var group_origin = Vector2()
var just_built = false
var stored_money = 0

var placing = null

var over_ui = false
var drag_select_disabled = false

export (PackedScene) var super_weapon
export (PackedScene) var click_pulse


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Game.cursor = self


func _physics_process(_delta):
	global_position = get_global_mouse_position()


func _process(_delta):
	
	# If we have selected something check if that is dead
	if mode == "selected":
		
		# loop through all selected things
		for s in selected:
			# check if it is dead
			if not is_instance_valid(s):
				# If it is dead remove it from the list of things that are selected
				selected.erase(s)
				selected.shuffle()
				
		
	# Animation things:
		
		
		# If we have something selected
		if selected.size() > 0:
			# If the first thing in the list is a building, then set animation to standard
			# You can only select one building at a time, and you can't select a building and a unit
			# So that's why this code works
			if is_instance_valid(selected[0]):
				if selected[0].is_in_group("Building"):
					# set anim to standard
					anim = "standard"
				else:
					# If the selected thing is a vehicle, then set anim to the crosshairs
					
					var can_mine = false
					
					var c = Game.tilemap
					if c.get_cellv(c.world_to_map(get_global_mouse_position())) == 1:
						for s in selected:
							if s.has_method("mine"):
								can_mine = true
					
					if can_mine:
						anim = "target"
					else:
						anim = "goto"
			else:
				selected.remove(0)
				selected.shuffle()
		else:
			# If we have nothing selected and mode is 'selected' then set mode back to ready
			mode = "ready"
	
	# If our cursor is not doing anything, then make our animation normal
	if mode == "ready":
		anim = "standard"
	
	
	# If we are selling stuff, make the cursor look like a dollar sign
	if mode == "sell":
		anim = "sell"
	
	# If we are repairing stuff, then make the cursor look like a wrench
	if mode == "repair":
		anim = "repair"
	
	# If we are getting ready to commit max extincition, make the cursor look like a nuke symbol
	if mode == "KABOOOOOM":
		anim = "superweapon"
	
	# if we are not placing a building
	if not mode == "placing":
		
		
		## START OF CANNON BOOM BOOM
		
		
		if Input.is_action_just_pressed("left_click") and mode == "KABOOOOOM" and not over_ui:
			var boomboom = super_weapon.instance()
			
			Game.unit_parent.add_child(boomboom)
			
			boomboom.global_position = global_position
			
			mode = "ready"
		
		
		## END OF CANNON BOOM BOOM
		
		
		
		
		# Figure out if we are hovering over something
		for selectable in get_tree().get_nodes_in_group("Selectable"):
			# Check if our cursor is close to something
			if selectable.get_node("Texture").global_position.distance_to(global_position) <= 30:
				# If we are hovering over something, and we are not selling or repairing or
				# preparing to cause mass extinction, then make the cursor look like it's 
				# ready to select something
				if not mode == "sell" and not mode == "repair" and not mode == "KABOOOOOM":
					
					var has_infil = false
					
					# If the thing is in our faction, we have an infiltrator
					# and if the thing has less than max health
					if selected:
						if selectable.health < selectable.max_health:
							if selectable.repairable == true:
								for unit in selected:
									if is_instance_valid(unit):
										if unit.is_in_group("Unit"):
											if unit.gun_type == "infiltrate":
												has_infil = true
												break
									else:
										selected.erase(unit)
					
					if has_infil == false:
						
						var sending_to_dropship = false
						
						if selected.size() > 0:
							if selectable.has_method("can_carry"):
								for s in selected:
									if selectable.can_carry(s):
										sending_to_dropship = true
										break
						
						if sending_to_dropship == false:
							
							var mining = false
							
							for s in selected:
								if s.has_method("mine"):
									if s.dropoff_points.has(selectable.type):
										mining = true
										break
							
							if mining == true:
								anim = "infiltrate"
							else:
								anim = "select"
						else:
							anim = "infiltrate"
					else:
						anim = "repair"
				
				hover = selectable
				break
		
		if selected.has(hover):
			if hover.has_method("can_carry"):
				if hover.carrying.size() > 0:
					if hover.can_deploy():
						anim = "deploy"
				else:
					anim = "standard"
			else:
				anim = "standard"
		
		
		# Figure out if we are group selecting
		if Input.is_action_just_pressed("left_click"):
			if not over_ui:
				group_origin = get_global_mouse_position()
				if anim == "deploy":
					hover.deploy()
			else:
				drag_select_disabled = true
			
		if Input.is_action_pressed("left_click") and not mode == "sell" and not mode == "repair" and not mode == "KABOOOOOM":
			if get_global_mouse_position().distance_to(group_origin) >= 15:
				if not over_ui:
					if drag_select_disabled == false:
						if not mode == "group_select":
							$Drag.play()
						mode = "group_select"
		else:
			drag_select_disabled = false
		
		
		
		
		
		# Check if we released left click
		if Input.is_action_just_released("left_click"):
			if mode == "group_select":
				$Select.play()
				for unit in get_tree().get_nodes_in_group("Unit"):
					var has_selected_anything = false
					
					if is_in_rect(unit.get_node("Texture").global_position, group_origin.x, global_position.x, group_origin.y, global_position.y):
						selected.append(unit)
						has_selected_anything = true
					
					if has_selected_anything == true:
						
						mode = "selected"
					else:
						mode = "ready"
			else:
				if hover and not over_ui and not mode == "selected":
					if not in_shroud(get_global_mouse_position()):
						if not mode == "sell":
							if not mode == "repair":
								selected.clear()
								selected.append(hover)
								$Select.play()
								mode = "selected"
								anim = "standard"
							else:
								selected.clear()
								if hover.is_in_group("Building"):
									hover.start_repair()
						else:
							selected.clear()
							if hover.is_in_group("Building"):
								hover.sell()
				
				# If we have selected something then check if we make it move somewhere
				if mode == "selected" and not over_ui:
					
					
					
					# make sure our cursor is not in the shroud # Commented because older brothers hated it
					#if not in_shroud(get_global_mouse_position()):
						
					if hover:
							
							
						var infiltrators = []
							
						if not hover.health == hover.max_health:
							if hover.repairable == true:
								for unit in selected:
									if not unit.is_in_group("Building"):
										if unit.gun_type == "infiltrate":
											infiltrators.append(unit)
							
							
							
						var can_board = []
							
						if hover.has_method("can_carry"):
							for unit in selected:
								if hover.can_carry(unit):
									can_board.append(unit)
							
							
						if can_board.size() > 0:
							for unit in can_board:
								if hover.can_carry(unit):
									unit.boarding_carrier = true
									unit.carrier = hover
						else:
							if infiltrators.size() == 0:
								
								var miners_to_dropoff = []
								
								for s in selected:
									if s.has_method("mine"):
										if s.dropoff_points.has(hover.type):
											#if s.money_supply > 0:
											miners_to_dropoff.append(s)
								
								
								if miners_to_dropoff.size() == 0:
									
									selected.clear()
									selected.append(hover)
									$Select.play()
									mode = "selected"
									anim = "standard"
								else:
									for miner in miners_to_dropoff:
										miner.returning = true
										miner.hq = hover
										miner.mining = false
										miner.controlled = false
										miner.half_controlled = false
										miner.target = null
							else:
								for agent in infiltrators:
									agent.nemesis = hover
						
						
						
						hover = null
						
					else:
						for unit in selected:
							if unit.has_method("travel"):
								
								var deviation = 0
								
								if selected.size() > 3:
									deviation = 40
								elif selected.size() > 1:
									deviation = 20
								
								if unit.has_method("mine"):
									unit.travel(get_global_mouse_position(), deviation, false, true, true, true)
								else:
									unit.travel(get_global_mouse_position(), deviation, false, true)
								
								
								
								unit.nemesis = null
								
								$Move.play()
						
						pulsate()
		
		
		get_parent().get_node("Buildings").clear()
	else:
		# Placing Mode
		
		if placing and not over_ui:
			var building_tilemap = get_parent().get_node("Buildings")
			var no_map = get_parent().get_node("NoBuild")
			var map_pos = building_tilemap.world_to_map(get_global_mouse_position())
			
			
			
			var our_building_tiles = []
			
			for building in get_tree().get_nodes_in_group("Building"):
				if building.faction == Game.level().faction:
					
					var building_tiles = building.return_used_tiles_global_positions()
					
					for t in building_tiles:
						our_building_tiles.append(t)
			
			
			var size = Game.building_sizes.get(placing)
			
			building_tilemap.clear()
			
			var allowed = true
			var near = false
			
			
			
			# loop through all my tiles
			for x in range(size.x):
				for y in range(size.y):
					
					var curr_pos = Vector2(map_pos.x + x, map_pos.y + y)
					
					# Make sure it's close to another building
					
					var pos = ((map_pos+Vector2(x-1, y-1))*Vector2(96, 48))
					
					for tile in our_building_tiles:
						
						if within_build_limit(tile, pos):
							
							near = true
					
					
					
					if no_map.get_cellv(curr_pos) == 0:
						allowed = false
						building_tilemap.set_cellv(curr_pos, 2)
					else:
						building_tilemap.set_cellv(curr_pos, 0)
			
			
			if near == false:
				for x in range(size.x):
					for y in range(size.y):
						
						var curr_pos = Vector2(map_pos.x + x, map_pos.y + y)
						building_tilemap.set_cellv(curr_pos, 2)
			
			
			if Input.is_action_just_pressed("left_click") and allowed == true and near == true:
				var b = load(str("res://Buildings/", placing, ".tscn")).instance()
				
				$PlaceBuilding.play()
				
				b.global_position = building_tilemap.map_to_world(map_pos) + Vector2(48, 48) + (b.offset*Vector2(96, 48))
				b.faction = Game.level().faction
				
				
				
				for x in range(size.x):
					for y in range(size.y):
						var curr_pos = Vector2(map_pos.x + x, map_pos.y + y)
						no_map.set_cellv(curr_pos, 0)
				
				
				Game.unit_parent.add_child(b)
				b.faction = Game.level().faction
				
				get_parent().get_node("Camera").pos = b.global_position
				
				
				
				
				group_origin = get_global_mouse_position()
				
				mode = "ready"
			
			
			
			
			
			hover = null
			selected.clear()
	
	
	# show/hide the BoxSelect
	if mode == "group_select":
		anim = "standard"
		selected.clear()
		$BoxSelect.show()
	else:
		$BoxSelect.hide()
	
	# Tell the hovered thing to show gray hud
	if hover:
		hover.hovered = true
	
	if Input.is_action_just_pressed("space"):
		selected.clear()
		if mode == "placing":
			Game.level().add_money(Game.level().faction, stored_money)
			stored_money = 0
			mode = "ready"
		if mode == "sell":
			mode = "ready"
		if mode == "repair":
			mode = "ready"
		if mode == "KABOOOOOM":
			mode = "ready"
			Game.level().add_money(Game.level().faction, 3000)
			
	
	
	if not mode == "placing":
		if selected.size() == 0:
			if not mode == "group_select" and not mode == "sell" and not mode == "repair" and not mode == "KABOOOOOM":
				mode = "ready"
		else:
			mode = "selected"
			for select in selected:
				if is_instance_valid(select):
					select.selected = true
				else:
					selected.erase(select)
	
	
	if not Input.is_action_pressed("left_click"):
		if mode == "group_select":
			mode = "ready"
	
	hover = null
	
	
	
	if over_ui:
		anim = "standard"
	animation = anim
	
	draw_group_select(group_origin)



func within_build_limit(center, pos):
	var ret = false
	
	var x_diff = center.x-pos.x
	var y_diff = center.y-pos.y
	
	if abs(x_diff) <= 192:
		if abs(y_diff) <= 96:
			ret = true
	
	
	return ret



func draw_group_select(pos):
	$BoxSelect.points[1] = Vector2(0, pos.y - global_position.y)
	$BoxSelect.points[2] = pos - global_position
	$BoxSelect.points[3] = Vector2(pos.x - global_position.x, 0)


func pulsate():
	var new_pulse = click_pulse.instance()
	
	new_pulse.global_position = self.global_position
	
	Game.unit_parent.add_child(new_pulse)



func in_shroud(_pos):
	return false



func is_in_rect(pos, left, right, top, bot):
	var ret = false
	
	var rleft = left
	var rright = right
	var rtop = top
	var rbot = bot
	
	if left < right:
		rright = left
		rleft = right

	if top > bot:
		rtop = bot
		rbot = top
	
	if pos.x > rright:
		if pos.x < rleft:
			if pos.y > rtop:
				if pos.y < rbot:
					ret = true
	
	return ret



func sell_stuff():
	mode = "sell"
	selected.clear()



func repair_stuff():
	mode = "repair"
	selected.clear()


