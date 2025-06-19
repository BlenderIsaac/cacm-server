extends AnimatedSprite

onready var Game = get_parent().get_parent()

export (PackedScene) var scorch

var sound_finished = false
var type = "large"
var disabled = false
var check = true

onready var explosion = load("res://Effects/BOOM.tscn")


func _ready():
	hide()
	frame = 0
	playing = true
	

func set_explosion():
	show()
	if type == "puff":
		animation = "none"
		$pulse.show()
		$puff.play("puff")
		
	
	elif type == "quad":
		for thing in range(0, 3):
			var new_exp = explosion.instance()
			
			randomize()
			
			get_parent().add_child(new_exp)
			
			new_exp.global_position = global_position + Vector2(rand_range(-25, 25), rand_range(-25, 25))
			new_exp.type = "large"
			new_exp.check = false


func load_sound(new_sound):
	$DeathDoomDestruction.stream = load(str("res://Sounds/sfx/", new_sound, ".ogg"))
	$DeathDoomDestruction.play()


var set = false

func _process(_delta):
	
	
	if frame == 2:
		if check == true:
			get_parent().get_parent().check_if_wonlost() # Uncomment eventually + needs to be changed
			check = false
	
	
	if disabled == false:
		
		var s = scorch.instance()
		
		get_parent().add_child(s)
		
		s.global_position = global_position
		
		disabled = true
	
	if set == false:
		set_explosion()
		set = true
	
	
	if frame == 10:
		
		if sound_finished == true:
			queue_free()
		



func _on_DeathDoomDestruction_finished():
	sound_finished = true
