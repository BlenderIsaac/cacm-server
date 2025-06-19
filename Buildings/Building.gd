extends Node2D

var lerped_angle = 0

var hovered = false
var selected = true
var shroud_fill = []

var id = 0

export var type = "Building"
export var HQ = false
export var faction = "astro"
export (PoolStringArray) var reinforcements = []
export(String, "quad", "large", "puff") var explosion_type = "quad"
export var offset = Vector2()
export var overlay = false
export var spread = 2
export var clear_shroud = false
export var show_radar = false
export var max_health = 100.0
export var extra_anims = true
export var repairable = true
export var damage_sound = "UD_good_pain_"

export(Array, NodePath) var bacon = [] # Edible and delicious @Cashibonite
export var protected_colour = Color("000000")

var starter = false
var health = 100.0
var repairing = false
var damage = 1.0

var blip_colour = "ffffff"
var blip = null

onready var explosion = preload("res://Effects/BOOM.tscn")
onready var Game = get_parent().get_parent().get_parent()


func _ready():
	
	id = gamestate.obj_id
	gamestate.obj_id += 1
	name = str(id)
	
	$Texture/HUD.z_index = 1
	$repair_anim.z_index = 1
	
	Game.buildings.append(self)
	Game.type_buildings.append(type)
	
	health = max_health*damage
	
	$Texture/HUD/Health.max_value = max_health
	$Texture/HUD/Health.value = health
	
	var _blah = $HurtFlash.connect("timeout", self, "end_flash")
	
	# calibrate anims
	$Shadow.frame = $Texture.frame
	$Texture/Flash.frame = $Texture.frame
	if overlay:
		$Overlay.frame = $Overlay/Flash.frame
	
	if not Game.level().factions.has(faction):
		Game.level().factions.append(faction)
	
	
	ready_special()
	
	if extra_anims:
		set_anim("Build")
	
	change_faction(faction, true)


func ready_special():pass
func process_special():pass


func set_anim(anim):
	$Texture.animation = anim
	$Texture/Flash.animation = anim
	$Shadow.animation = anim
	if overlay:
		$Overlay.animation = anim
		$Overlay/Flash.animation = anim


func change_faction(new_faction, overide_bacon=false):
	
	if got_bacon() or overide_bacon:
		faction = new_faction
		
		var sizex = Game.building_sizes.get(type).x
		
		var base_path = str("res://Textures/buildings/baseplate_", faction, "_", sizex, ".png")
		
		if starter == false:
			Game.level().check_if_wonlost()
		
		$Base.texture = load(base_path)
	else:
		change_health(0)



func got_bacon():
	var ret = true
	
	for b in bacon:
		
		if is_instance_valid(get_node(b)):
			ret = false
			break
	
	return ret



func _process(_delta):
	
	
	
	if repairing:
		$repair_anim.show()
	else:
		$repair_anim.hide()
	
	
	if $Texture.animation == "Build":
		if $Texture.frame == 3:
			set_anim("Idle")
	
	
	# Health colours and smoke
	if health <= max_health/4:
		$Texture/Smoke.emitting = true
		if extra_anims:
			set_anim("Broken")
		$Texture/HUD/Health.modulate = Color("df0000")
	elif health <= max_health/2:
		$Texture/HUD/Health.modulate = Color("fff500")
		$Texture/Smoke.emitting = false
		
		if $Texture.animation == "Broken":
			set_anim("Idle")
	else:
		$Texture/HUD/Health.modulate = Color("ffffff")
		$Texture/Smoke.emitting = false
		
		if $Texture.animation == "Broken":
			set_anim("Idle")
	
	
	process_special()
	
	if selected:
		$Texture/HUD.modulate.a = 1
	elif hovered:
		$Texture/HUD.modulate.a = .49
	else:
		$Texture/HUD.modulate.a = 0
	
	hovered = false
	selected = false



func flash(col):
	$Texture/Flash.material.set_shader_param("color", Color(col))
	$Texture/Flash.show()
	if overlay == true:
		$Overlay/Flash.show()
	$HurtFlash.start()



var dead = false

func change_health(value, nuked=false, overide_bacon=false):
	
	if got_bacon() or overide_bacon:
		
		health += value
		$Texture/HUD/Health.value = health
		
		flash("ffffff")
		
		for player in gamestate.players.keys():
			if player_in_my_game(player):
				rpc_id(player, "set_health", health, nuked)
		
		if health <= 0 and dead == false:
			if nuked == true:
				die(true, false)
			else:
				die(true, true)
			
			dead = true
		
	else:
		flash(protected_colour)
		
		for player in gamestate.players.keys():
			if player_in_my_game(player):
				rpc_id(player, "flash", protected_colour)



func player_in_my_game(p):
	return gamestate.players.get(p)[1] == get_parent().get_parent().GAME



remote func sell():
	if not HQ:
		
		var cost = Game.type_costs.get(type)
		
		var ratio = health/max_health
		var refund = stepify(cost*ratio*0.5, 5.0)
		
		Game.level().add_money(faction, refund)
		
		for player in gamestate.players.keys():
			if player_in_my_game(player):
				rpc_id(player, "die", false)
		
		die(false)



func return_used_tiles_global_positions():
	
	var tiles = []
	
	
	
	var building_tilemap = get_parent().get_parent().get_node("Buildings")
	
	var size = Game.building_sizes.get(type)
	var topcorner_position = global_position - Vector2(size.x*48, size.y*24)
	
	if not size.y/2 == int(size.y/2):
		topcorner_position.y += 48
	
	var map_pos = building_tilemap.world_to_map(topcorner_position)
	
	for x in range(size.x):
		for y in range(size.y):
			var curr_pos = Vector2(map_pos.x + x-1, map_pos.y + y-1)
			tiles.append(building_tilemap.map_to_world(curr_pos))
	
	
	
	return tiles



func die(boom=true, spawn=true):
	if dead == false:
		
		if blip:
			blip.queue_free()
		
		var building_tilemap = get_parent().get_parent().get_node("Buildings")
		var size = Game.building_sizes.get(type)
		var topcorner_position = global_position - Vector2(size.x*48, size.y*24)
		
		#if not size.y/2 == int(size.y/2):
		#	topcorner_position.y += 48
		
		var map_pos = building_tilemap.world_to_map(topcorner_position)
		
		var no_map = get_parent().get_parent().get_node("NoBuild")
		
		for x in range(size.x):
			for y in range(size.y):
				var curr_pos = Vector2(map_pos.x + x, map_pos.y + y)
				no_map.set_cellv(curr_pos, -1)
		
		Game.type_buildings.erase(type)
		Game.buildings.erase(self)
		
		
		
		if HQ == true:
			
			var buildings_doomed = []
			var has_hq = false
			
			for building in get_tree().get_nodes_in_group("Building"):
				if not building == self:
					if building.faction == faction:
						if building.HQ == true:
							has_hq = true
							break
						else:
							buildings_doomed.append(building)
			
			if has_hq == false:
				for unit in get_tree().get_nodes_in_group("Unit"):
					if not unit == self:
						if unit.faction == self.faction:
							for player in gamestate.players.keys():
								if player_in_my_game(player):
									unit.rpc_id(player, "die")
							unit.die()
				
				for building_doomed in buildings_doomed:
					for player in gamestate.players.keys():
						if player_in_my_game(player):
							building_doomed.rpc_id(player, "die", true, false)
					building_doomed.die(true, false)
				
				spawn = false
		
		
		# Spawn reinforcements
		if spawn:
			for rein in reinforcements:
			
				var limit = Game.type_limits.get(rein)
				
				
				if not Game.has_max(rein, "unit", limit, faction):
					
					var pos = position + Vector2(rand_range(-20, 20), rand_range(-10, 10))
					
					Game.get_parent().create_unit(pos, rein, faction, Game.name, true)
		
		
		if boom:
			get_parent().get_parent().get_node("Camera").shake += 30
			explode()
		
		dead = true
	
	Game.level().check_if_wonlost([self])
	
	queue_free()


func end_flash(): # Goodbye Adobe Flash Player. Miss u
	$Texture/Flash.hide()
	if overlay:
		$Overlay/Flash.hide()


func explode():
	var e = explosion.instance()
	
	get_parent().add_child(e)
	e.global_position = self.global_position
	e.type = explosion_type



func lmt(number, limit):
	var first = number/limit + 0.0
	var second = first - int(first)
	var third = second*limit
	return third


func ur2rad(ur):
	return deg2rad((ur+1)*11.5)


remote func start_repair():
	repairing = true
	get_node("repair_time").start()
	
	for player in gamestate.players.keys():
		if player_in_my_game(player):
			rset_id(player, "repairing", true)


func repair():
	
	var repair_amount = 20
	
	var cancel = false
	
	if Game.level().get_money(faction) >= repair_amount:
		if health <= max_health-repair_amount:
			Game.level().add_money(faction, -repair_amount)
			change_health(repair_amount)
		
		else:
			if health < max_health:
				Game.level().add_money(faction, health-max_health)
				change_health(max_health - health)
			else:
				cancel = true
	else:
		cancel = true
	
	if cancel == true:
		repairing = false
		$repair_time.stop()
		
		for player in gamestate.players.keys():
			if player_in_my_game(player):
				rset_id(player, "repairing", false)


