extends TileMap

onready var RadarShroud = get_parent().get_node("HUD/Radar/RadarShroud")


func _ready():
	Game.shroud = self
	
	show()


func _process(_delta):
	if Input.is_action_pressed("debug"):
		if Input.is_action_pressed("debugL"):
			clear()
			get_parent().get_node("HUD/Radar/RadarShroud").clear()
