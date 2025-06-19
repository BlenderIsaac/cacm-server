extends "res://Buildings/Building.gd"


func ready_special():
	if faction == Game.level().faction:
		get_parent().get_parent().uplinks.append(self)
