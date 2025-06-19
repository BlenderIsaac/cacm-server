extends Node2D

onready var Game = get_parent().get_parent().get_parent()

signal die

export var type = "Unit"
export var max_health = 100
export var speed = 6.0
export var spread = 1
export(String, "quad", "large", "puff") var explosion_type = "large"
export(String, "bullet", "laser", "infiltrate", "none") var gun_type = "bullet"
export var one_track_brain = false
export var flying = false
export var bounces = false
export var hover_anim = false
export var turn = false
export var walking = false
export var repairable = true
export var faction = "astro"
export var bullet_sound = "INT_guntower_"
export var move_sound = "UD_good_comply"
export var damage_sound = "UD_good_pain_"
export var death_sound = "UD_good_die"
export var fire_rate = 0.5
export var gun_range = 300
export var hit_flyers = false
var blip_size = 30

var boarding_carrier = false
var carrier = null
var health = 100
var path
var can_shoot = true
var can_move = true
var damage = 1.0

var target = null
var opponent
remote var nemesis

var selected = false
var hovered = false

var lerped_angle = 0

var id = 0
var set_id = true

onready var explosion = preload("res://Effects/BOOM.tscn")
onready var bullet = preload("res://Effects/Bullet.tscn")

func _ready():
	
	if set_id == true:
		id = gamestate.obj_id
		gamestate.obj_id += 1
		name = str(id)
	
	randomize()
	
	$Move.stream = load(str("res://Sounds/sfx/", move_sound, ".ogg"))
	
	var something = Vector2(rand_range(-100, 100), rand_range(-100, 100)) + global_position
	
	var f = int(rand_range(0, 15))
	
	$Texture.frame = f
	$Shadow.frame = f
	$Texture/Flash.frame = f
	
	health = max_health*damage
	
	if not Game.level().factions.has(faction):
		Game.level().factions.append(faction)
	
	var h = $Texture/HUD/Health
	
	h.max_value = max_health
	h.value = health
	h.rect_size.x = health*0.12
	h.rect_position.x = -health*0.06
	
	if flying:
		z_index = 1
	
	Game.type_units.append(type)
	Game.units.append(self)
	
	$FireRate.wait_time = fire_rate
	if hover_anim:
		var num = rand_range(0, 2)
		$Backforth.seek(num, true)
		$updown.seek(num, true)
	
	change_faction(faction)
	
	_ready_special()


func _process_special(delta):pass
func _ready_special():pass


remote func flash(col):
	$Texture/Flash.material.set_shader_param("color", Color(col))
	$Texture/Flash.show()
	$HurtFlash.start()


remote func board_carrier(carrier_id):
	boarding_carrier = true
	carrier = get_parent().get_node(str(carrier_id))


func face(pos=Vector2(), anim_name="straight"):
	
	var angle = pos.angle_to_point(self.position)
	
	if turn == true:
		var prev_rot = int($total_rot.rotation_degrees)
		
		$total_rot.look_at(pos)
		
		var curr_rot = int($total_rot.rotation_degrees)
		
		if curr_rot < prev_rot:
			anim = "left"
			$TurnCooldown.start()
		elif curr_rot > prev_rot:
			anim = "right"
			$TurnCooldown.start()
		
		anim_name = anim
	
	lerped_angle = lerp_angle(lerped_angle, angle, 0.3)
	
	lerped_angle = deg2rad(lmt(rad2deg(lerped_angle), 360))
	
	
	$Texture.animation = anim_name
	$Shadow.animation = "straight"
	$Texture/Flash.animation = anim_name
	var frame = float(int((rad2deg(lerped_angle)/22.5 + 4.5) + 16))
	
	frame = lmt(frame, 32)
	
	$Texture.frame = frame
	$Shadow.frame = frame
	$Texture/Flash.frame = frame



func lmt(number, limit):
	var first = number/limit + 0.0
	var second = first - int(first)
	var third = second*limit
	return third


func change_health(value, nuked=false):
	health += value
	$Texture/HUD/Health.value = health
	
	flash("ffffff")
	
	for player in gamestate.players.keys():
		if gamestate.players.get(player)[1] == get_parent().get_parent().get_parent().name:
			rpc_id(player, "set_health", health)
	
	if health <= 0:
		die()


var dead = false


func die(ex=true):
	if dead == false:
		
		emit_signal("die")
		
		Game.type_units.erase(type)
		Game.units.erase(self) #For later just in case
		
		if ex == true:
			explode()
		
		dead = true
	
	Game.level().check_if_wonlost([self])
	
	queue_free()



func explode():
	var e = explosion.instance()
	
	get_parent().add_child(e)
	e.global_position = get_node("Texture").global_position
	e.type = explosion_type
	e.load_sound(death_sound)


var pursuing_nemesis = false


func _process(_delta):
	
	
	# Health colours and smoke
	if health <= max_health/4:
		$Texture/Smoke.emitting = true
		$Texture/HUD/Health.modulate = Color("df0000")
	elif health <= max_health/2:
		$Texture/HUD/Health.modulate = Color("fff500")
		$Texture/Smoke.emitting = false
	else:
		$Texture/HUD/Health.modulate = Color("ffffff")
		$Texture/Smoke.emitting = false
	
	if target:
		traveling(_delta)
		
		if boarding_carrier == true:
			if is_instance_valid(carrier):
				if carrier.global_position.distance_to(global_position) <= carrier.pickup_range:
					if carrier.can_carry(self):
						carrier.carry(self)
					else:
						boarding_carrier = false
			else:
				boarding_carrier = false
		
	else:
		if boarding_carrier == true:
			travel(carrier.position, 0, true)
	
	
	# If we have a gun
	if not gun_type == "none":
		
		
		if opponent:
			if not verify_enemy(opponent):
				opponent = null
				find_opponent()
		else:
			find_opponent()
		
		# shooting the enemy
		
		
		
		# if we have a nemesis then check if the nemesis is valid
		if nemesis:
			# check if the nemesis is dead
			if not is_instance_valid(nemesis):
				# Remove the nemesis if dead
				nemesis = null
		
		# t is the thing we are shooting at. It is automatically set to opponent
		var t = opponent
		
		# If we have a nemesis and the nemesis is in reach then change t to nemesis
		if nemesis:
			
			if verify_nemesis():
				t = nemesis
				pursuing_nemesis = false
			else:
				# make sure we aren't already going to the nemesis
				if pursuing_nemesis == false:
					var deviation = 40
					
					if gun_type == "infiltrate":
						deviation = 0
					
					var backup = nemesis
					travel(nemesis.global_position, deviation)
					
					if gun_type == "infiltrate":
						
						nemesis = backup
						
						if not path:
							nemesis = null
					
					pursuing_nemesis = true
		
		
		# If we don't have an opponent then don't shoot at anything
		if not opponent and not nemesis:
			t = null
		
		if not t == nemesis:
			if one_track_brain == true:
				t = null
		
		# If we are shooting at anything
		if t:
			
			# look at the thing we are shooting at
			face(t.global_position, anim)
			
			# If the gun type is a laser then position the tip of the laser
			if gun_type == "laser":
				
				# set e_pos to the thing we are shooting's position
				var e_pos = t.global_position
				
				# Set the lasers second point to the enemy position minus our own position
				$Laser.points[1] = e_pos - $Laser.global_position
			
			
			# If we can shoot then shoot
			if can_shoot == true:
				# shoot whatever t is
				shoot(t)
				# turn off shooting until we reload
				can_shoot = false # Remove this line for machine guns! :)
				# start the reload
				$FireRate.start()
	
	
	# Bouncing
	if bounces:
		var b = rand_range(0, 1.5)
		$Texture.position.y = -b
	
	# HUD modulate
	if selected:
		$Texture/HUD.modulate.a = 1
	elif hovered:
		$Texture/HUD.modulate.a = .49
	else:
		$Texture/HUD.modulate.a = 0
	
	 
	if not target:
		
		var f = $Texture.frame
		
		$Texture.animation = "straight"
		$Texture/Flash.animation = "straight"
		
		$Texture.frame = f
		$Texture/Flash.frame = f
	
	
	_process_special(_delta)
	
	# Reset things
	hovered = false
	selected = false
	
	
	for player in gamestate.players.keys():
		if gamestate.players.get(player)[1] == get_parent().get_parent().get_parent().name:
			rset_unreliable_id(player, "pos", position)
			rset_unreliable_id(player, "anim", $Texture.animation)
			rset_unreliable_id(player, "frame", $Texture.frame)


func player_in_my_game(p):
	return gamestate.players.get(p)[1] == get_parent().get_parent().GAME


func verify_enemy(enemy, fc=true):
	
	var ret = false
	
	if is_instance_valid(enemy):
		if enemy.get_parent() == get_parent():
			if Game.in_oval(global_position, enemy.global_position, gun_range/2, gun_range):
				
				var verified = true
				
				if fc == true:
					if not faction_checks(enemy):
						verified = false
				
				var yes = true
				
				if gun_type == "infiltrate":
						
						# if in our faction
						if enemy.faction == faction:
							
							# if at max health
							if enemy.health >= enemy.max_health:
								yes = false
							
							if enemy.repairable == false:
								yes = false
							
						else:
							# If not in our faction
							if enemy.is_in_group("Unit"):
								yes = false
				
				
				
				if verified == true and yes == true:
					if not enemy == self:
						
						# flying check
						
						var can = false
						
						if not enemy.is_in_group("Building"):
							if enemy.flying == true:
								if hit_flyers == true:
									can = true
							else:
								can = true
						else:
							can = true
						
						if flying == true:
							can = true
						
						
						
						if can == true:
							ret = true
	
	return ret



func find_opponent():
	for enemy in get_tree().get_nodes_in_group("Selectable"):
		if enemy.get_parent() == get_parent():
			if faction_checks(enemy):
				if not enemy == self:
					
					# flying check
					
					var can = false
					
					if not enemy.is_in_group("Building"):
						if enemy.flying == true:
							if hit_flyers == true:
								can = true
						else:
							can = true
					else:
						can = true
					
					if flying == true:
						can = true
					
					
					
					if can == true:
						if Game.in_oval(global_position, enemy.global_position, gun_range/2, gun_range):
							opponent = enemy


func verify_nemesis():
	
	var ret = false
	
	if nemesis.get_parent() == get_parent():
		if Game.in_oval(global_position, nemesis.global_position, gun_range/2, gun_range):
			ret = true
	
	return ret


remote func set_nemesis(id):
	nemesis = get_parent().get_node(id)


func faction_checks(enemy):
	var ret = true
	
	if not enemy.get_parent() == get_parent():
		ret = false
	
	if enemy.faction == self.faction:
		ret = false
	
	if enemy.is_in_group("Building") and not enemy.is_in_group("Turret"):
		ret = false
	
	return ret


var anim = "straight"


func traveling(delta):
	if path.size() > 1:
		
		face(path[1], anim)
		
		if position.distance_to(path[1]) <= (float(speed)*delta*60):
			position = path[1]
		else:
			position += Vector2(-(float(speed)*delta*60), 0).rotated(position.angle_to_point(path[1]))
		
		if position.distance_to(path[1]) <= (float(speed)*delta*60):
			path.remove(1)
			
			
			if path.size() > 1:
				
				if turn:
					var pos = path[1].angle_to_point(self.position)
					
					anim = "straight"
					$TurnCooldown.start()
				else:
					if not walking:
						anim = "straight"
						
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


remote func travel(pos, deviation, time_to_board=false, play_sound=false):
	if can_move == true:
		
		var nav = get_tree().get_nodes_in_group("nav")[0]
		if not flying:
			path = nav.get_simple_path(global_position, nav.get_closest_point(pos+Vector2(rand_range(-deviation, deviation), rand_range(-deviation, deviation))))
		else:
			path = [global_position, nav.get_closest_point(pos+Vector2(rand_range(-deviation, deviation), rand_range(-deviation, deviation)))]
		
		
		target = pos
	
	if not time_to_board == true:
		boarding_carrier = false
	
	#nemesis = null


func back2straight():
	var f = $Texture.frame
	anim = "straight"
	$Texture.animation = "straight"
	$Texture.frame = f




# --------------- AI MODES --------------- #


var wandaing = false


func wanda():#vision
	
	if $Line2D.points.size() == 0:
		wandaing = false
	
	if not opponent:
		if wandaing == false:
			var place = Vector2(rand_range(-300, 300), rand_range(-300, 300))
			
			
			travel(place+global_position, 0)
			wandaing = true


var prey = []


func seek():
	if nemesis == null:
		
		var list = get_tree().get_nodes_in_group("Building")
		
		for thing in list:
			if thing.faction == self.faction:
				pass
			else:
				prey.append(thing)
		
		prey.shuffle()
		
		
		if prey.size() > 0:
			nemesis = prey[0]
			pursuing_nemesis = false


# ---------------------------------------- #

var bullet_id = 0

func shoot(enemy):
	if is_instance_valid(enemy):
		if verify_enemy(enemy, false):
			if gun_type == "laser":
				
				var e_pos = enemy.get_node("Texture").global_position
				
				$Laser.points[1] = e_pos - $Laser.global_position
				$Laser/Flash.start()
				$Laser.show()
				$Laser/Shoot.stream = load(str("res://Sounds/sfx/", bullet_sound, int(rand_range(1, 4)), ".ogg"))
				$Laser/Damage.stream = load(str("res://Sounds/sfx/", enemy.damage_sound, int(rand_range(1, 3)), ".ogg"))
				$Laser/Shoot.play()
				$Laser/Damage.play()
				
				for player in gamestate.players.keys():
					if player_in_my_game(player):
						rpc_id(player, "shoot", e_pos, null, null, null, enemy.damage_sound)
				
				enemy.change_health(-25, false)
				
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
				
			elif gun_type == "infiltrate":
				
				var changed = false
				
				if enemy.faction == faction:
					enemy.change_health(enemy.max_health-enemy.health)
				else:
					changed = true
					enemy.change_faction(faction)
					
				
				# Broadcast our death to the local news
				for player in gamestate.players.keys():
					if player_in_my_game(player):
						
						if changed == true:
							
							enemy.rpc_id(player, "change_faction", faction)
						
						rpc_id(player, "die", false)
				
				die(false)
		else:
			if enemy == nemesis:
				nemesis = null
			elif enemy == opponent:
				opponent = null


func change_faction(new_fact):
	
	if gun_type == "laser":
		$Laser.texture = load(str("res://Textures/weapons/", new_fact, "_laser.png"))
	
	if flying:
		$Texture/Light.texture = load(str("res://Textures/units/", new_fact, "_beam.png"))
	
	faction = new_fact
	
	Game.level().check_if_wonlost()


func stop_laser():
	$Laser.hide()


func end_flash(): # Goodbye Adobe Flash Player. Miss u
	$Texture/Flash.hide()



func _on_FireRate_timeout():
	can_shoot = true


func _on_WalkSpeed_timeout():
	var new_animation = walk()
	anim = new_animation


var next_done = "back"


func walk():
	var c_anim = $Texture.animation
	var n_anim = "straight"
	
	if c_anim == "straight":
		n_anim = str("straight", next_done)
		
		if next_done == "back":
			next_done = "front"
		else:
			next_done = "back"
	
	return n_anim


