extends TextureRect


onready var HUD = get_parent().get_parent()


export var type = "unit"
export var object = "Infantry"
export (PoolStringArray) var requirements = ["EagleCommandCentre", "PowerPlant"]
export var limit = 4
export var cost = 200
export var radar_name = "Infantry"
export var faction = "astro"

var money = 4.00

var charged = false
var charging = false
var amount_charged = 0
var paused = false

var stored_money = 0

var disabled = false

var a = false


func _process(_delta):
	
	if Game.HUD.power_state == "disabled":
		money = 1.00
	elif Game.HUD.power_state == "slowed":
		money = 2.00
	else:
		money = 4.00
	
	
	if Game.has_max(object, type, limit):
		$Button.disabled = true
	else:
		$Button.disabled = false 
	
	if disabled:
		$Button.disabled = true
	
	
	# Tech Tree stuuff
	
	check_tech_tree()
	
	var radar_names = HUD.get_node("RadarNames")
	
	if $Button.is_hovered():
		
		radar_names.show()
		radar_names.get_node("AnimationPlayer").play("flash")
		radar_names.get_node("Name").text = radar_name
		
		if charged:
			radar_names.get_node("Price").text = "Deploy"
		else:
			if charging:
				if paused == true:
					radar_names.get_node("Price").text = "Awaiting Funds"
				else:
					radar_names.get_node("Price").text = str(int(amount_charged*100), "% COMPLETED")
			else:
				
				if Game.has_max(object, type, limit):
					radar_names.get_node("Price").text = "Max Built"
				else:
					radar_names.get_node("Price").text = str("$", cost)
		
		a = true
	else:
		if a == true:
			radar_names.hide()
			radar_names.get_node("AnimationPlayer").stop()
			a = false
	
	
	if charging or charged:
		for child in get_parent().get_children():
			if not child == self:
				if visible:
					child.disabled = true
				else:
					cancel()
	
	
	disabled = false


func _physics_process(_delta):
	
	if charging:
		if Game.level().get_money(Game.level().faction) >= money:
			Game.level().add_money(Game.level().faction, -money)
			stored_money += money
			paused = false
		else:
			paused = true
		
		amount_charged = stored_money/cost
		
		
		$charge.max_value = 1
		$charge.value = -amount_charged+1
		
		if amount_charged > 1:
			_on_Timer_timeout()
		
	else:
		if charged == true:
			$AnimatedSprite.playing = true
			if type == "unit":
				_on_Button_pressed()
		else:
			$AnimatedSprite.playing = false
			$AnimatedSprite.frame = 0


func _on_Button_pressed():
	
	if charged == true:
		
		charged = false
		
		
		if Game.cursor:
			if type == "building":
				
				
				if not stored_money == cost: # This is duct tape. Duct tape that works tho. EDIT: It might not work...
					Game.level().add_money(Game.level().faction, stored_money-cost)
				
				
				Game.cursor.mode = "placing"
				Game.cursor.placing = object
				Game.cursor.stored_money = cost
				
				
				stored_money = 0
		
		if type == "unit":
			
			if Game.unit_parent:
				var origin = null
				
				for building in Game.buildings:
					if building.type == Game.unit_origins.get(object):
						if building.faction == Game.level().faction:
							origin = building
				
				if origin:
					var u = load(str("res://Units/", object, ".tscn")).instance()
					
					var offset = Vector2(rand_range(-80, 80), rand_range(-80, 80))
					offset = offset.normalized()*Vector2(24, 12)
					
					var corner_offset = Game.building_sizes.get(origin.type)*Vector2(-48, 24)-Vector2(-48, 24)
					
					u.global_position = origin.global_position + corner_offset + offset
					u.faction = Game.level().faction
					
					Game.unit_parent.add_child(u)
					
					stored_money = 0

		
		elif type == "superweapon":
			Game.cursor.mode = "KABOOOOOM"
			Game.cursor.selected.clear()
		
	else:
		if charging == false:
			$ChargeSound.play()
			# Charge it if not already charged or charging
			charging = true
		else:
			cancel()


func cancel():
	Game.level().add_money(Game.level().faction, stored_money)
	stored_money = 0
	charging = false
	charged = false
	$charge.value = 0


func _on_Timer_timeout():
	$FinishSound.play()
	charged = true
	charging = false
	$charge.value = 0


func check_tech_tree():
	
	var has_em_all = true
	var type_buildings = []
	
	
	for building in Game.buildings:
		if building.faction == Game.level().faction:
			type_buildings.append(building.type)
	
	
	for requirement in requirements:
		if not type_buildings.has(requirement):
			has_em_all = false
	
	
	var testing = false
	
	if testing == true:
		if type == "superweapon":
			has_em_all = true
			cost = 12
	
	
	if has_em_all == true:
		show()
	else:
		hide()
		
		if not stored_money == 0:
			Game.level().add_money(Game.level().faction, stored_money)
		stored_money = 0
		charging = false
		$charge.value = 0





