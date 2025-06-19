extends Node2D

export var requirements = ["OrbitalUplink"]
export var faction_firer = "alien"
export (String) var fired_at = null # Leave blank for random faction
export (float) var nuke_expense = 3000
export (float) var nuke_min_time = 120
export (float) var nuke_max_time = 200
export (float) var nuke_original_wait = 400
export (PackedScene) var nuke


func _ready():
	$Timer.wait_time = nuke_original_wait
	$Timer.start()


func _on_Timer_timeout():
	verify()


func verify():
	if visible:
		
		var requirements_met = 0
		
		for requirement in requirements:
			for building in get_tree().get_nodes_in_group("Building"):
				if building.type == requirement:
					if building.faction == faction_firer:
						requirements_met += 1
						break
		
		
		if requirements_met == requirements.size():
			choose()
		
		$Timer.wait_time = rand_range(nuke_min_time, nuke_max_time)
		$Timer.start()



func choose():
	randomize()
	
	var victim = null
	var backup = null
	
	if Game.level().get_money(faction_firer) >= nuke_expense:
		for building in get_tree().get_nodes_in_group("Building"):
			# If its not in our faction and its in the faction we are targeting
			if enemy_faction(building):
				# if we can't reach the other checks then we set backup
				backup = building
				# If we can destroy the building
				if building.health < 1000:
					victim = building
					break
	
	
	
	if victim:
		nuke_da(victim)
	else:
		if backup:
			nuke_da(backup)


func nuke_da(thing):
	
	var n = nuke.instance()
	
	Game.unit_parent.add_child(n)
	
	n.global_position = thing.global_position
	
	Game.level().add_money(faction_firer, -nuke_expense)



func enemy_faction(building):
	var ret = false
	
	if not building.faction == faction_firer:
		if fired_at == null:
			ret = true
		else:
			if building.faction == fired_at:
				ret = true
	
	return ret




