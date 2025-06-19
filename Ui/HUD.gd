extends CanvasLayer

var building_scroll = 0
var unit_scroll = 0

var power_state = "good"

var starting_money = 0

var last_warned = "good"


func _ready():
	scale.x = 1
	Game.HUD = self
	Game.blips = $Radar/Blips
	
	$Sell.connect("pressed", get_parent().get_node("Cursor"), "sell_stuff")
	$Repair.connect("pressed", get_parent().get_node("Cursor"), "repair_stuff")
	$Pause.connect("pressed", get_parent(), "pause")
	$fadeout/AnimationPlayer.connect("animation_finished", get_parent(), "_on_AnimationPlayer_animation_finished")



func _process(_delta):
	
	$Label.text = str("FPS: ", Engine.get_frames_per_second())
	
	$Money.text = str("$", Game.level().get_money(Game.level().faction))
	
	$Units.rect_position.y = lerp($Units.rect_position.y, (unit_scroll*-30)+212, 0.1)
	$Buildings.rect_position.y = lerp($Buildings.rect_position.y, (building_scroll*-30)+212, 0.1)
	
	if not Game.level().faction == "astro":
		
		$Overlays.get_node(Game.level().faction).show()
	
	
	
	if unit_scroll >= get_visible_children_count(get_node("Units"))-6:
		unit_scroll = get_visible_children_count(get_node("Units"))-6
	
	if building_scroll >= get_visible_children_count(get_node("Buildings"))-6:
		building_scroll = get_visible_children_count(get_node("Buildings"))-6
	
	
	if building_scroll <= 0:
		building_scroll = 0
	
	if unit_scroll <= 0:
		unit_scroll = 0
	
	if building_scroll == 0:
		$Control/BuildingUp.disabled = true
	else:
		$Control/BuildingUp.disabled = false
	
	if unit_scroll == 0:
		$Control/UnitUp.disabled = true
	else:
		$Control/UnitUp.disabled = false
	
	if building_scroll >= get_visible_children_count(get_node("Buildings"))-6:
		$Control/BuildingDown.disabled = true
	else:
		$Control/BuildingDown.disabled = false
	
	if unit_scroll >= get_visible_children_count(get_node("Units"))-6:
		$Control/UnitDown.disabled = true
	else:
		$Control/UnitDown.disabled = false
	
	
	
	update_power(Game.level().faction)


var power = 0


func update_power(fact):
	var bl = []
	
	for building in Game.buildings:
		if building.faction == fact:
			bl.append(building)
	
	var used = 0.0
	var supply = 0.0
	
	
	for b in bl:
		
		var ratio = b.health/b.max_health
		
		if Game.building_power.get(b.type) > 0:
			supply += Game.building_power.get(b.type)*ratio
		else:
			used += Game.building_power.get(b.type)
	
	
	if supply < 360:
		$PowerBar/Green.scale.y = supply*0.53
		$PowerBar/Green.position.y = (-supply*0.53)/2
		
		$PowerBar/Yellow.scale.y = used*0.53
		$PowerBar/Yellow.position.y = (used*0.53)/2
	else:
		$PowerBar/Green.scale.y = 360*0.53
		$PowerBar/Green.position.y = (-360*0.53)/2
		
		var c = used*(360.0/supply)*.53
		$PowerBar/Yellow.scale.y = c
		$PowerBar/Yellow.position.y = c/2
	
	
	var amount = used+supply
	
	
	if amount < 0:
		$PowerBar/Yellow.modulate = Color("ff0000") # Red
		power_state = "disabled"
		
	elif amount < 35:
		$PowerBar/Yellow.modulate = Color("ff0000") # Red
		power_state = "slowed"
	else:
		$PowerBar/Yellow.modulate = Color("f7ff00") # Yellow
		power_state = "good"
	
	if not last_warned == power_state:
		
		match power_state:
			"disabled":
				display("Insufficient Power - Guns Offline", true, 1.75)
			"slowed":
				display("Low Power - Building Slowed", true, 1.75)
			"good":
				display("Full Power Restored", false, 1.75)
		
		last_warned = power_state




func display(text, sound=false, time=1, colour=Color("ffffff")):
	var Text = $Text
	
	if sound == true:
		Text.get_node("WarningSound").play()
	
	Text.set("custom_colors_font_color", colour)
	Text.text = text
	if not time <= 0.0:
		Text.get_node("Timer").wait_time = time
	else:
		Text.get_node("Timer").wait_time = 0.0001
	Text.get_node("Timer").start()


func get_visible_children_count(node):
	var list = node.get_children()
	
	var amount = 0
	
	for child in list:
		if child.visible == true:
			amount += 1
	
	return amount


func _on_UnitDown_pressed():
	unit_scroll += 1


func _on_BuildingDown_pressed():
	building_scroll += 1


func _on_BuildingUp_pressed():
	building_scroll -= 1


func _on_UnitUp_pressed():
	unit_scroll -= 1


func _on_Timer_timeout():
	$Text.text = ""


