extends "res://Units/Unit.gd"


export var home_type = "RadarStation"
export var bullet_slots = 10
export var ascension_speed = 1
export var tex_offset_y = 11

var home = null
var bullet_amount = 0
var docked_time = 0



func _ready_special():
	bullet_amount = 0


func fighter(): # this is so we can identify it in the dropship code
	pass


func _process_special(delta):
	
	if flying == true:
		if bullet_amount <= 0:
			
			nemesis = null
			
			if target:
				pass
			else:
				
				if not home:
					home = find_home()
				else:
					if not is_instance_valid(home):
						home = find_home()
				
				if not home:
					for player in gamestate.players.keys():
						if player_in_my_game(player):
							rpc_id(player, "die")
					die()
				else:
					travel(home.global_position, 10)
				
				if dist_to_home() <= 100:
					flying = false
					target = null
		else:
			if target:
				pass
			else:
				if not home:
					home = find_home()
				else:
					if not is_instance_valid(home):
						home = find_home()
				if not home:
					for player in gamestate.players.keys():
						if player_in_my_game(player):
							rpc_id(player, "die")
					die()
				else:
					travel(home.global_position, 10)
				
				if dist_to_home() <= 100:
					flying = false
					target = null
	else:
		if target:
			flying = true
			
			var nemesis_backup = nemesis
			travel(target, 10)
			nemesis = nemesis_backup
		else:
			docked_time += delta*60
			if bullet_amount < bullet_slots:
				bullet_amount += 1
	
	
	
	if flying == true:
		$Texture/Light.show()
		
		$Texture.offset.y = 11
		if $Texture.position.y >= -85 + ascension_speed:
			$Texture.position.y -= ascension_speed
		elif $Texture.position.y > -85:
			$Texture.position.y = -85
	else:
		$Texture/Light.hide()
		
		if $Texture.position.y <= 0 - ascension_speed:
			$Texture.position.y += ascension_speed
		elif $Texture.position.y < 0:
			$Texture.position.y = 0
		else:
			$Texture.offset.y = rand_range(tex_offset_y, tex_offset_y-2)
	
	for player in gamestate.players.keys():
		if player_in_my_game(player):
			rset_id(player, "height", $Texture.position.y)
			rset_id(player, "fly", flying)
	
	$Col.position = $Texture.position



func dist_to_home():
	var ret = 100000
	
	if not home:
		home = find_home()
	else:
		if not is_instance_valid(home):
			home = find_home()
	
	if home:
		ret = home.global_position.distance_to(global_position)
	else:
		for player in gamestate.players.keys():
			if player_in_my_game(player):
				rpc_id(player, "die")
		die()
	
	return ret


func find_home():
	var ret = null
	
	var all_list = get_tree().get_nodes_in_group("Building") + get_tree().get_nodes_in_group("Unit")
	
	for h in all_list:
		if h.type == home_type:
			if h.faction == faction:
				ret = h
				break
	
	if ret == null:
		for player in gamestate.players.keys():
			if player_in_my_game(player):
				rpc_id(player, "die")
		die()
	
	return ret


func seek():
	if nemesis == null and bullet_amount >= 10 and docked_time >= 300:
		
		# Figure out if we are the leader
		var units = get_tree().get_nodes_in_group("Unit")
		var leader = null
		
		
		for possible_canidate in units:
			if possible_canidate.type == self.type:
				if possible_canidate.faction == faction:
					leader = possible_canidate
					break
		
		if leader == self:
			var list = get_tree().get_nodes_in_group("Building")
			
			for thing in list:
				if thing.faction == self.faction:
					pass
				else:
					prey.append(thing)
			
			randomize()
			
			prey.shuffle()
			
			
			if prey.size() > 0:
				nemesis = prey[0]
				pursuing_nemesis = false
		
		
			# If we are the leader then we want to send all the fighters off
			
			for fighter in units:
				if fighter.type == type:
					if fighter.faction == faction:
						if fighter.flying == false:
							fighter.attack(nemesis)
		
		
		docked_time = 0


func attack(thing):
	nemesis = thing
	pursuing_nemesis = false




# Rewrite the shoot function to only shoot 10 bullets
func shoot(enemy):
	if is_instance_valid(enemy):
		if bullet_amount > 0:
			if gun_type == "laser":
				
				var e_pos = enemy.get_node("Texture").global_position
				
				$Laser.points[1] = e_pos - get_node("Texture").global_position
				$Laser/Flash.start()
				$Laser.show()
				$Laser/Shoot.stream = load(str("res://Sounds/sfx/", bullet_sound, int(rand_range(1, 4)), ".ogg"))
				$Laser/Damage.stream = load(str("res://Sounds/sfx/", enemy.damage_sound, int(rand_range(1, 3)), ".ogg"))
				$Laser/Shoot.play()
				$Laser/Damage.play()
				
				enemy.change_health(-25)
			elif gun_type == "bullet":
				
				var angle = get_node("Texture").global_position.angle_to_point(enemy.get_node("Texture").global_position)
				
				var b = bullet.instance()
				
				b.rotation = angle - deg2rad(90)
				b.target = enemy
				b.global_position = get_node("Texture").global_position
				b.faction = faction
				b.sound_name = bullet_sound
				b.name = str(name, "b", bullet_id)
				bullet_id += 1
				
				get_parent().add_child(b)
				
				for player in gamestate.players.keys():
					if player_in_my_game(player):
						rpc_id(player, "shoot", Vector2(), b.position, b.rotation, b.name, enemy.damage_sound)
			
			bullet_amount -= 1
