extends Node


onready var cursor = get_node("Level/Cursor")
onready var unit_parent = get_node("Level/Units")
onready var tilemap = get_node("Level/Navigation2D/Tiles")


export var coresponding_type = {
	"BA_evil" : "AlienMothership",
	"BA_good" : "EagleCommandBase",
	"BB_evil" : "EnergyGenerator",
	"BB_good" : "PowerPlant",
	"BC_evil" : "BreedingPit",
	"BC_good" : "TrainingCamp",
	"BD_evil" : "AssaultTurret",
	"BD_good" : "DefenceStation",
	"BE_evil" : "BattleFoundry",
	"BE_good" : "VehicleFactory",
	"BF_evil" : "SonarStation",
	"BF_good" : "RadarStation",
	"BG_evil" : "ExperimentLab",
	"BG_good" : "TechnologyCentre",
	"BH_evil" : "OrbitalUplink",
	"BH_good" : "SatelliteUplink",
	"BI_good" : "FootballField",
	"BJ_evil" : "Sleigh",
	"BK_evil" : "Hive",
	"BK_good" : "OpsShip",
	"BL_good" : "Driller",
	"BX_good" : "Rocket",
}


var building_sizes = {
	"PowerPlant" : Vector2(1, 2),
	"TrainingCamp" : Vector2(2, 2),
	"DefenceStation" : Vector2(1, 2),
	"VehicleFactory" : Vector2(2, 3),
	"RadarStation" : Vector2(2, 3),
	"TechnologyCentre" : Vector2(1, 2),
	"SatelliteUplink" : Vector2(1, 2),
	"EagleCommandBase" : Vector2(2, 4),
	"EnergyGenerator" : Vector2(1, 2),
	"BreedingPit" : Vector2(2, 2),
	"AssaultTurret" : Vector2(1, 2),
	"BattleFoundry" : Vector2(2, 3),
	"SonarStation" : Vector2(2, 3),
	"ExperimentLab" : Vector2(1, 2),
	"OrbitalUplink" : Vector2(1, 2),
	"AlienMothership" : Vector2(2, 4),
	"Hive" : Vector2(2, 4),
	"OpsShip" : Vector2(2, 4),
	"FootballField" : Vector2(4, 3),
	"Rocket" : Vector2(2, 4),
	"Driller" : Vector2(2, 3),
	"Sleigh" : Vector2(1, 2),
}

var unit_origins = {
	"Infantry" : "TrainingCamp",
	"Engineer" : "TrainingCamp",
	"JetpackExplorer" : "TrainingCamp",
	"ClawTank" : "VehicleFactory",
	"ReconDropship" : "VehicleFactory",
	"Trike" : "VehicleFactory",
	"AstroFighter" : "RadarStation",
	"CrystalMiner" : "EagleCommandBase",
	"Drone" : "BreedingPit",
	"Saboteur" : "BreedingPit",
	"Viper" : "BreedingPit",
	"DragonCruiser" : "BattleFoundry",
	"HyperCarrier" : "BattleFoundry",
	"Speeder" : "BattleFoundry",
	"StrikeFighter" : "SonarStation",
	"CrystalExtractor" : "AlienMothership",
	"AlienInfiltrator" : "Hive",
	"SwitchFighter" : "OpsShip",
}

var type_costs = {
	"Infantry" : 200,
	"Engineer" : 500,
	"JetpackExplorer" : 600,
	"ClawTank" : 1200,
	"ReconDropship" : 1000,
	"Trike" : 600,
	"AstroFighter" : 1200,
	"CrystalMiner" : 1400,
	"Drone" : 200,
	"Saboteur" : 500,
	"Viper" : 600,
	"DragonCruiser" : 1200,
	"HyperCarrier" : 1000,
	"Speeder" : 600,
	"StrikeFighter" : 1200,
	"CrystalExtractor" : 1400,
	"AlienInfiltrator" : 1500,
	"SwitchFighter" : 1500,
	
	"PowerPlant" : 800,
	"TrainingCamp" : 500,
	"DefenceStation" : 1500,
	"VehicleFactory" : 2000,
	"RadarStation" : 1000,
	"TechnologyCentre" : 2000,
	"SatelliteUplink" : 1500,
	"EagleCommandBase" : 3000,
	"EnergyGenerator" : 800,
	"BreedingPit" : 500,
	"AssaultTurret" : 1500,
	"BattleFoundry" : 2000,
	"SonarStation" : 1000,
	"ExperimentLab" : 2000,
	"OrbitalUplink" : 1500,
	"AlienMothership" : 3000,
	"Driller" : 3000,
	"Rocket" : 3000,
	"Sleigh" : 1500,
	"FootballField" : 19660,
	"OpsShip" : 3500,
	"Hive" : 3500,
}

var type_limits = {
	"Infantry" : 5,
	"Engineer" : 5,
	"JetpackExplorer" : 5,
	"ClawTank" : 5,
	"ReconDropship" : 2,
	"Trike" : 5,
	"AstroFighter" : 4,
	"CrystalMiner" : 4,
	"Drone" : 5,
	"Saboteur" : 5,
	"Viper" : 5,
	"DragonCruiser" : 5,
	"HyperCarrier" : 2,
	"Speeder" : 5,
	"StrikeFighter" : 4,
	"CrystalExtractor" : 4,
	"AlienInfiltrator" : 2,
	"SwitchFighter" : 2,
	
	"PowerPlant" : 8,
	"TrainingCamp" : 2,
	"DefenceStation" : 12,
	"VehicleFactory" : 2,
	"RadarStation" : 1,
	"TechnologyCentre" : 1,
	"SatelliteUplink" : 5,
	"EagleCommandBase" : 1,
	"EnergyGenerator" : 8,
	"BreedingPit" : 2,
	"AssaultTurret" : 12,
	"BattleFoundry" : 2,
	"SonarStation" : 1,
	"ExperimentLab" : 1,
	"OrbitalUplink" : 5,
	"AlienMothership" : 1,
	"Driller" : 4,
	"Rocket" : 1,
	"Sleigh" : 1,
	"FootballField" : 1,
	"OpsShip" : 1,
	"Hive" : 1,
}


var building_power = {
	"PowerPlant" : 200,
	"TrainingCamp" : -10,
	"DefenceStation" : -75,
	"VehicleFactory" : -25,
	"RadarStation" : -50,
	"TechnologyCentre" : -100,
	"SatelliteUplink" : -100,
	"EagleCommandBase" : 1,
	"EnergyGenerator" : 200,
	"BreedingPit" : -10,
	"AssaultTurret" : -75,
	"BattleFoundry" : -25,
	"SonarStation" : -50,
	"ExperimentLab" : -100,
	"OrbitalUplink" : -100,
	"AlienMothership" : 1,
	"Driller" : -100,
	"Rocket" : 0,
	"Sleigh" : 100,
	"FootballField" : 0,
	"OpsShip" : 1,
	"Hive" : 1,
}


var buildings = []
var type_buildings = []

var type_units = []
var units = []

var played
var has_won = false


var level_data_store = {}


func _process(delta):
	
	var is_active = false
	
	for player in gamestate.players_in_lobbies.keys():
		var info = gamestate.players_in_lobbies.get(player)
		
		if info[1] == get_parent().name:
			$Level/InactivityTimer.stop()
			is_active = true
	
	
	if is_active == false:
		if $Level/InactivityTimer.wait_time == $Level/InactivityTimer.time_left:
			$Level/InactivityTimer.start()


func level():
	var l = get_node("Level")
	return l


func has_max(object, type, limit, faction):
	
	var ret = false
	
	var amount = 0
	
	var list = []
	
	if type == "building":
		for building in buildings:
			list.append(building)
	elif type == "unit":
		for unit in units:
			list.append(unit)
	
	var dropshiped_units = []
	
	
	for dropship in units:
		
		if dropship.has_method("carry"):
			
			if dropship.faction == faction:
				var c = dropship.carrying
				
				for unit in c:
					
					dropshiped_units.append(unit[0])
	
	
	for unit in dropshiped_units:
		if unit == object:
			amount += 1
	
	
	for unit in list:
		if is_instance_valid(unit):
			if unit.type == object:
				if unit.faction == faction:
					amount += 1
		else:
			units.erase(unit)
	
	
	if amount >= limit:
		ret = true
	
	return ret



func in_oval(oval_pos, point_pos, height, width):
	var x = point_pos.x
	var y = point_pos.y
	
	var h = oval_pos.x
	var k = oval_pos.y
	
	
	var math_thingimajiggy = ( pow((x-h), 2.0) / pow(width, 2.0) ) + ( pow((y-k), 2.0) / pow(height, 2.0) )
	
	return math_thingimajiggy <= 1


func ovular_distance_to(oval_pos, point_pos, height, width):
	var x = point_pos.x
	var y = point_pos.y
	
	var h = oval_pos.x
	var k = oval_pos.y
	
	
	var math_thingimajiggy = ( pow((x-h), 2.0) / pow(width, 2.0) ) + ( pow((y-k), 2.0) / pow(height, 2.0) )
	
	return math_thingimajiggy



func setup():
	buildings = []
	type_buildings = []
	type_units = []
	units = []
