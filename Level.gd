extends Node2D

var GAME = "0909"
onready var Game = get_parent()

export var custom = false
export var level_editor_exit = false
export var crystal_regenerate_rate = 300
export var starting_money = {
	"astro" : 10000,
	"alien" : 10000,
	"other1" : 10000,
	"other2" : 10000
}
var money = {}
var factions = []
var power = []
export var tutorial = {
		"Positions" : [],
		"Text" : [],
		"Time" : [],
		"Colours" : [],
	}
export(String, MULTILINE) var win_text = "Good Job"
export(String, MULTILINE) var lose_text = "You have been conquered"
export(String, MULTILINE) var tie_text = "At least you didn't lose..."

onready var Cam = $Camera

var state = "off"



func _process(_delta):
	
#	for player in gamestate.players.keys():
#		var info = gamestate.players.get(player)
#
#		if info[1] == get_parent().name:
#			print(get_tree().name)
	
	$Info.text = str(money, ", ", get_parent().name)
	
	for player in gamestate.players.keys():
		if gamestate.players.get(player)[1] == GAME:
			
			var f = gamestate.players.get(player)[2]
			
			rset_unreliable_id(player, "money", money[f])
	
	calculate_all_power()


func get_power(fact):
	
	var index = -1
	var valid = false
	
	for f in power:
		index += 1
		if f[0] == fact:
			valid = true
			break
	
	
	var power_state = "disabled"
	
	if valid == true:
		
		var amount = power[index][1]
		
		# Set power_state to the correct thing
		if amount < 0:
			power_state = "disabled"
		elif amount < 35:
			power_state = "slowed"
		else:
			power_state = "good"
	
	
	return power_state


func get_power_index(build_fact):
	var index = -1
	var valid = false
	
	for p in power:
		index += 1
		if p[0] == build_fact:
			valid = true
			break
	
	if valid == false:
		power.append([build_fact, 0])
		index = power.find([build_fact, 0])
	
	return index



func calculate_all_power():
	
	power = []
	
	for building in Game.buildings:
		
		var ratio = building.health/building.max_health
		
		power[get_power_index(building.faction)][1] += Game.building_power.get(building.type)*ratio


func get_money(fact):
	return money[fact] # this might not work if no key value pair has been created



remote func add_money(fact, value):
	
	var begin_mon = 0
	
	if money.has(fact):
		begin_mon = money.get(fact)
	
	money[fact] = begin_mon+value


func generate(data):
	
	var MAP = $Navigation2D/Tiles
	
	# Tile
	for tile in data.Tile:
		MAP.set_cell(str2var("Vector2" + tile[0]).x, str2var("Vector2" + tile[0]).y, tile[1], false, false, false, str2var("Vector2" + tile[2]))
		
		var id = tile[1]
		var coord = tile[2]
		
		var sets = false
		
		
		match id:
			0:
				if not coord == Vector2(3, 1):
					sets = true
			1:
				sets = true
			2:
				sets = true
			3:
				sets = true # Change
			4:
				sets = true
			5:
				sets = true
			8:
				sets = true
			9:
				sets = true
			10:
				sets = true
			11:
				sets = true
			12:
				sets = true
		
		if sets == true:
			get_node("NoBuild").set_cellv(tile[0], 0)
	
	# Buildings
	for building in data.Buildings:
		
		var no_map = get_node("NoBuild")
		var map_pos = str2var("Vector2" + building[1])
		var size = Game.building_sizes.get(building[0])
		
		var b = load("res://Buildings/"+building[0]+".tscn").instance()
		
		$Units.add_child(b)
		
		b.global_position = map_pos
		b.faction = building[2]
		b.damage = building[3]
		b.starter = true
		
		var topcorner_position = b.global_position - Vector2(size.x*48, size.y*24)
		var pos = no_map.world_to_map(topcorner_position)
		
		for x in range(size.x):
			for y in range(size.y):
				var curr_pos = Vector2(pos.x + x, pos.y + y)
				no_map.set_cellv(curr_pos, 0)
		
		
		for d in building[4]:
			b.get_node(d[0]).set(d[1], d[2])
	
	
	
	# Units
	for unit in data.Units:
		var unit_spawn = load("res://Units/"+unit[0]+".tscn").instance()
		
		unit_spawn.global_position = str2var("Vector2" + unit[1])
		
		unit_spawn.faction = unit[2]
		unit_spawn.damage = unit[3]
		unit_spawn.respawn = unit[4]
		
		for d in unit[5]:
			unit.get_node(d[0]).set(d[1], d[2])
		
		$Units.add_child(unit_spawn)
	
	
	# Upgrades
	for upgrade in data.Upgrades:
		var up = load("res://Upgrades/"+upgrade[0]+".tscn").instance()
		
		up.global_position = str2var("Vector2" + upgrade[1])
		
		up.money = upgrade[2]
		up.spawns = upgrade[3]
		up.pickup_range = upgrade[4]
		up.blip_colour = upgrade[5]
		
		for d in upgrade[6]:
			up.get_node(d[0]).set(d[1], d[2])
		
		$Units.add_child(up)
	
	# easy things
	#faction = data.Faction
	crystal_regenerate_rate = data.CrystalRegenerationRate
	win_text = data.WinText
	lose_text = data.LoseText
	tie_text = data.TieText
	starting_money = data.Cash
	#blip_modulation = data.BlipModulation
	#enemy_spawns = data.Spawn
	
	var tut = data.Tutorial
	
	for p in tut.Positions:
		tut.Positions[tut.Positions.find(p)] = str2var("Vector2" + p)
	
	tutorial = tut
	
	# Nukes
	# jokes no code here yet
	
	# Custom D A T A (I don't know why but i love saying data)
	for d in data.CustomData:
		get_node(d[0]).set(d[1], d[2])



func _ready():
	
	if custom == true:
		generate(Game.level_data_store)
	
	var rect = get_node("Navigation2D/Tiles").get_used_rect()
	
	$terrain.region_rect.size.y = int(rect.size.y*48)
	$terrain.region_rect.size.x = int(rect.size.x*96)
	
	Cam.limit_right = int(rect.size.x*96)
	Cam.limit_bottom = int(rect.size.y*48)
	
	money = starting_money
	
	# loop through all factions
	
	Game.unit_parent = $Units
	
	var crystal_tiles = $Navigation2D/Tiles.get_used_cells_by_id(4)
	
	for tile in crystal_tiles:
		
		var stage = int(rand_range(0, 3))
		
		$Navigation2D/Tiles.set_cell(tile.x, tile.y, 1, false, false, false, Vector2(0, stage))
	
	Game.tilemap = $Navigation2D/Tiles


func check_if_wonlost(exception=[]):
	var factions_remaining = []
	var things = get_tree().get_nodes_in_group("Unit") + get_tree().get_nodes_in_group("Building")

	# Generate factions_remaining
	for thing in things:

		if not exception.has(thing):
			if not factions_remaining.has(thing.faction):
				if thing.get_parent().get_parent().GAME == GAME:
					factions_remaining.append(thing.faction)
	
	# Figure out if some of the factions from the start of the game are dead
	factions = factions_remaining
	
	
	var winner = null
	
	if factions_remaining.size() == 1:
		winner = factions_remaining[0]
	
	if not winner == null:
		end(winner)



func regenerate_crystals():
	# Regeneration script
	var crystal_tiles = $Navigation2D/Tiles.get_used_cells_by_id(1)

	for tile in crystal_tiles:
		if int(rand_range(0, crystal_regenerate_rate)) == 1:
		
			var previous_stage = Game.tilemap.get_cell_autotile_coord(tile.x, tile.y).y
			
			Game.tilemap.set_cell(tile.x, tile.y, 1, false, false, false, Vector2(0, previous_stage-1))
			
			if Game.tilemap.get_cell_autotile_coord(tile.x, tile.y).y < 0:
				Game.tilemap.set_cell(tile.x, tile.y, 1, false, false, false, Vector2(0, 0))
			
			for player in gamestate.players.keys():
				if str(gamestate.players.get(player)[1]) == get_parent().name:
					rpc_id(player, "set_crystal_stage", tile, $Navigation2D/Tiles.get_cell_autotile_coord(tile.x, tile.y).y)



func end(winner):
	for player in gamestate.players.keys():
		if str(gamestate.players.get(player)[1]) == get_parent().name:
			rpc_id(player, "end", winner)
	$DeleteTimer.start()


func _on_AnimationPlayer_animation_finished(anim_name):
	get_parent().queue_free()



func change_song():
	$Music.play()



func _on_Regenerate_timeout():
	regenerate_crystals()


func fire_nuke():
	pass


func _on_DeleteTimer_timeout():
	get_parent().queue_free()
