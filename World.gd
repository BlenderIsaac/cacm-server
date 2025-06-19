extends Node2D


remote func fire_nuke(pos, game):
	var boomboom = load("res://Effects/SuperWeapon.tscn").instance()
	
	get_node(str(game+"/Level/Units")).add_child(boomboom)
	
	boomboom.position = pos
	
	# spawn the decorative version on the clients
	for player in gamestate.players.keys():
		if gamestate.players.get(player)[1] == game:
			rpc_id(player, "fire_nuke", pos)


remote func create_unit(pos, type, faction, game, check_max=false):
	
	var allowed = true
	
	var limit = get_node(str(game)).type_limits.get(type)
	
	if get_node(str(game)).has_max(type, "unit", limit, faction):
		allowed = false
	
	if allowed or not check_max:
		# spawn the unit on the server
		var unit = load("res://Units/"+type+".tscn").instance()
		
		unit.set_id = false
		unit.position = pos
		unit.name = str(gamestate.obj_id)
		gamestate.obj_id += 1
		unit.set_network_master(0)
		unit.faction = faction
		
		get_node(str(game) + "/Level/Units").add_child(unit)
		
		# spawn the unit on all the clients
		for player in gamestate.players.keys():
			if gamestate.players.get(player)[1] == game:
				rpc_id(player, "spawn_unit", unit.position, type, unit.name, unit.max_health, unit.health, unit.faction)



remote func create_building(pos, type, faction, game):
	
	# spawn the building on the server
	var building = load("res://Buildings/"+type+".tscn").instance()
	
	building.position = pos + building.offset*Vector2(96, 48)
	building.name = str(gamestate.obj_id)
	gamestate.obj_id += 1
	building.set_network_master(0)
	building.faction = faction
	
	get_node(str(game) + "/Level/Units").add_child(building)
	
	# spawn the building on all the clients
	for player in gamestate.players.keys():
		if gamestate.players.get(player)[1] == game:
			rpc_id(player, "spawn_building", building.position, type, building.name, building.max_health, building.health, building.faction, building.repairing)



remote func spawn_unit(spawn_pos, type, id, game, max_health, health, faction):
	var unit = load("res://Units/"+type+".tscn").instance()
	
	unit.set_id = false
	unit.position = spawn_pos
	unit.name = str(id)
	unit.set_network_master(0) # This might be needed
	unit.max_health = max_health
	unit.health = health
	unit.faction = faction
	unit.type = type

	get_node(str(game) + "/Level/Units").add_child(unit)


remote func spawn_building(spawn_pos, type, id, game, max_health, health, faction):
	var building = load("res://Buildings/"+type+".tscn").instance()

	building.position = spawn_pos
	building.name = str(id) # Important
	building.set_network_master(0) # This might be needed
	building.max_health = max_health
	building.health = health
	building.faction = faction

	get_node(str(game) + "/Level/Units").add_child(building)


remote func remove_unit(id, game):
	get_node(str(game) + "/Level/Units").get_node(String(id)).queue_free()


func _process(delta):
	var txt = "PLAYERS:\n"
	
	for player in gamestate.players.keys():
		txt += str(player) + ", " + str(gamestate.players.get(player)) + "\n"
	
	txt += "LOBBY PLAYERS:\n"
	
	for player in gamestate.players_in_lobbies.keys():
		txt += str(player) + ", " + str(gamestate.players_in_lobbies.get(player)) + "\n"
	
	$CanvasLayer/Control/Label.text = txt
