extends "res://Buildings/Building.gd"


var enemies = []
var nemesis
var opponent
export var turret_range = 300
onready var bullet = preload("res://Effects/Bullet.tscn")
export var fire_rate = 0.1
export var fire_pos = Vector2()
export var bullet_sound = "INT_guntower_"
var gun_type = "bullet"

var can_fire = true

var f = 0


func ready_special():
	$FireRate.wait_time = fire_rate


func process_special():
	
	check_for_enemies()
	
	if enemies.size() > 0:
		var en = enemies[0]
		
		if en:
			if is_instance_valid(en):
				opponent = en
			else:
				enemies.erase(en)
				enemies.shuffle()
		else:
			enemies.erase(en)
			enemies.shuffle()
	else:
		if opponent:
			opponent = null
	
	
	if nemesis:
		verify_nemesis()
		if not is_instance_valid(nemesis):
			nemesis = null
	
	var t = null
	
	if nemesis:
		t = nemesis
	elif opponent:
		t = opponent
	
	if t:
		if is_instance_valid(t):
			if not Game.level().get_power(faction) == "disabled":
				
				face(t.global_position)
				
				if can_fire == true:
					shoot(t)
					can_fire = false
					$FireRate.start()
		else:
			set_anim("Idle")
	else:
		set_anim("Idle")
	
	
	for player in gamestate.players:
		if player_in_my_game(player):
			rset_unreliable_id(player, "frame", $Texture.frame)
		
	if not Game.level().get_power(faction) == "disabled":
		f = $Texture.frame
	else:
		$Texture.frame = f
		$Texture/Flash.frame = f
		$Shadow.frame = f
		
		if overlay:
			$Overlay.frame = f
			$Overlay/Flash.frame = f



func change_health(value, nuked=false, overide_bacon=false):
	
	if got_bacon() or overide_bacon:
		
		health += value
		$Texture/HUD/Health.value = health
		
		for player in gamestate.players.keys():
			if player_in_my_game(player):
				rpc_id(player, "set_health", health, nuked)
		
		flash("ffffff")
		
		if health <= 0 and dead == false:
			
			if nuked == true:
				die(true, false)
			else:
				die(true)
			
			dead = true
	else:
		flash(protected_colour)
		
		for player in gamestate.players.keys():
			if player_in_my_game(player):
				rpc_id(player, "flash", protected_colour)
	
	enemies = []


func verify_nemesis():
	if nemesis.get_parent() == get_parent():
		if not Game.in_oval(global_position, nemesis.global_position, turret_range/2, turret_range):
			nemesis = null


func check_for_enemies():
	for enemy in get_tree().get_nodes_in_group("Selectable"):
		if enemy.get_parent() == get_parent():
			if faction_checks(enemy):
				if not enemies.has(enemy):
					if not enemy == self:
						if Game.in_oval(global_position, enemy.global_position, turret_range/2, turret_range):
							enemies.append(enemy)
						
				else:
					if not Game.in_oval(global_position, enemy.global_position, turret_range/2, turret_range):
						enemies.erase(enemy)


func faction_checks(enemy):
	var ret = true
	
	if enemy.faction == self.faction:
		ret = false
	
	if enemy.is_in_group("Building") and not enemy.is_in_group("Turret"):
		ret = false
	
	return ret


var bullet_id = 0


func shoot(enemy):
	var angle = (global_position+fire_pos).angle_to_point(enemy.get_node("Texture").global_position)
	
	var b = bullet.instance()
	var id = str(name, "b", bullet_id)
	bullet_id += 1
	
	b.rotation = angle - deg2rad(90)
	b.target = enemy
	b.global_position = global_position + fire_pos
	b.faction = faction
	b.sound_name = bullet_sound
	b.name = id
	
	get_parent().add_child(b)
	
	for player in gamestate.players:
		if player_in_my_game(player):
			rpc_id(player, "shoot", enemy.get_node("Texture").position, b.rotation, id)



func cooldown_fire():
	can_fire = true



func face(pos=Vector2(), anim_name="Face"):
	var angle = pos.angle_to_point(self.position)
	
	lerped_angle = lerp_angle(lerped_angle, angle, 0.3)
	
	lerped_angle = deg2rad(lmt(rad2deg(lerped_angle), 360))
	
	$Texture.animation = anim_name
	$Shadow.animation = anim_name
	$Texture/Flash.animation = anim_name
	var frame = float(int((rad2deg(lerped_angle)/22.5 + 4.5) + 16))
	
	frame = lmt(frame, 31)
	
	$Texture.frame = frame
	$Shadow.frame = frame
	$Texture/Flash.frame = frame
