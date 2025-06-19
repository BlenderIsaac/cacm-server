extends Node

# Default game port
const DEFAULT_PORT = 56565

# Max number of players
const MAX_PLAYERS = 12

# Players dict stored as id:[name, game, faction]
var players = {}
# Players dict stored as id:[game, faction]
var players_in_lobbies = {}

var obj_id = 0
var game_name = 1000


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	
	create_server()


func _process(delta):
	for player in gamestate.players.keys():
		var info = gamestate.players.get(player)
		
		if info[1] == get_parent().name:
			break


func create_server():
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(host)


# Callback from SceneTree, called when client connects
func _player_connected(_id):
	print("Client ", _id, " connected")


# Callback from SceneTree, called when client disconnects
func _player_disconnected(id):
	
	if players_in_lobbies.has(id):
		rpc("unregister_player_in_lobby", id)
	
	if players.has(id):
		rpc("unregister_player", id)
	
	print("Client ", id, " disconnected")


# Player management functions
remote func register_player(new_player_name, game, fact):
	# We get id this way instead of as parameter, to prevent users from pretending to be other users
	var caller_id = get_tree().get_rpc_sender_id()
	
	# Add him to our list
	players[caller_id] = [new_player_name, game, fact]
	
	# Add everyone to new player:
	for p_id in players:
		rpc_id(caller_id, "register_player", p_id, players[p_id][0], players[p_id][1], players[p_id][2]) # Send each player to new dude
	
	
	
	rpc("register_player", caller_id, players[caller_id][0], players[caller_id][1], players[caller_id][2]) # Send new dude to all players
	# NOTE: this means new player's register gets called twice, but fine as same info sent both times
	
	print("Client ", caller_id, " registered as ", new_player_name, " in game ", game, " in faction ", fact)


remote func create_game(preset, cacl_file):
	
	var new_game
	
	if preset == "Game4":
		new_game = load("res://Levels/Game4.tscn").instance()
	else:
		new_game = load("res://Levels/Game.tscn").instance()
	
	game_name += 1
	new_game.name = str(game_name)
	new_game.get_node("Level").GAME = str(game_name)
	
	get_node("/root/World").add_child(new_game)
	
	var caller_id = get_tree().get_rpc_sender_id()
	
	rpc_id(caller_id, "join_game", str(game_name))



remote func take_faction(faction, game):
	var caller_id = get_tree().get_rpc_sender_id()


remote func leave(id):
	unregister_player(id)


puppetsync func unregister_player(id):
	players.erase(id)
	
	print("Client ", id, " was unregistered")


remotesync func unregister_player_in_lobby(id):
	players_in_lobbies.erase(id)
	
	print("Client ", id, " left a lobby")


remote func register_player_in_lobby(id, game):
	# We get id this way instead of as parameter, to prevent users from pretending to be other users
	var caller_id = get_tree().get_rpc_sender_id()
	
	# Add him to our list
	players_in_lobbies[caller_id] = [game, ""]
	
	# Add everyone to new player:
	for p_id in players_in_lobbies:
		rpc_id(caller_id, "register_player_in_lobby", p_id, players_in_lobbies[p_id][0], players_in_lobbies[p_id][1]) # Send each player to new dude
	
	rpc("register_player_in_lobby", caller_id, players_in_lobbies[caller_id][0], players_in_lobbies[caller_id][1]) # Send new dude to all players
	# NOTE: this means new player's register gets called twice, but fine as same info sent both times
	
	print("Client ", caller_id, " registered in a lobby in game ", game)



remote func set_faction_taken(faction):
	var caller_id = get_tree().get_rpc_sender_id()
	
	players_in_lobbies[caller_id][1] = faction



remote func does_game_exist(game):
	var caller_id = get_tree().get_rpc_sender_id()
	
	var game_exists = false
	
	for g in get_node("/root/World").get_children():
		if g.name == game:
			game_exists = true
	
	rpc_id(caller_id, "game_exists", game_exists)


remote func get_factions(game):
	var caller_id = get_tree().get_rpc_sender_id()
	var factions_remaining = []
	var things = get_tree().get_nodes_in_group("Unit") + get_tree().get_nodes_in_group("Building")
	
	for thing in things:
		if not factions_remaining.has(thing.faction):
			if thing.get_parent().get_parent().GAME == game:
				factions_remaining.append(thing.faction)
	
	var factions_taken = []
	
	for player in players_in_lobbies.keys():
		if players_in_lobbies.get(player)[0] == game:
			if not players_in_lobbies.get(player)[1] == "":
				factions_taken.append(players_in_lobbies.get(player)[1])
	
	rpc_id(caller_id, "recieve_factions", factions_remaining, factions_taken)



remote func populate_world():
	var caller_id = get_tree().get_rpc_sender_id()
	var world = get_node("/root/World")
	var game = str(players.get(caller_id)[1])
	
	# Spawn all current units on new client
	for unit in get_tree().get_nodes_in_group("Unit"):
		
		var unit_game = unit.get_parent().get_parent().get_parent().name
		
		var other = null
		if unit.has_method("can_carry"):
			other = unit.carrying
		
		if unit_game == game:
			world.rpc_id(
				caller_id,
				"spawn_unit",
				unit.position,
				unit.type,
				unit.name,
				unit.max_health,
				unit.health,
				unit.faction,
				other
				)
	
	# Spawn all buildings in the client's game on the client
	for building in get_tree().get_nodes_in_group("Building"):
		
		var building_game = building.get_parent().get_parent().get_parent().name
		
		if building_game == game:
			world.rpc_id(
				caller_id,
				"spawn_building",
				building.position,
				building.type,
				building.name,
				building.max_health,
				building.health,
				building.faction,
				building.repairing
				)
	
	# Spawn all upgrades in the client's game on the client
	for upgrade in get_tree().get_nodes_in_group("Upgrade"):
		
		var upgrade_game = upgrade.get_parent().get_parent().get_parent().name
		
		if upgrade_game == game:
			world.rpc_id(
				caller_id,
				"spawn_upgrade",
				upgrade.position,
				upgrade.type,
				upgrade.name
				)
	
	# Create the map on the client
	
	var map_data = []
	
	var map = world.get_node(game).get_node("Level/Navigation2D/Tiles")
	var rect = map.get_used_rect()
	
	for y in range(rect.size.y):
		var row = []
		for x in range(rect.size.x):
			
			var autotile_coord = map.get_cell_autotile_coord(x, y)
			
			if map.get_cell(x, y) == 6:
				autotile_coord = null
			
			
			row.append([map.get_cell(x, y), autotile_coord])
		
		map_data.append(row)
	
	world.rpc_id(caller_id, "recieve_map", map_data)


# Return random 2D vector inside bounds 0, 0, bound_x, bound_y
func random_vector2(bound_x, bound_y):
	return Vector2(randf() * bound_x, randf() * bound_y)
