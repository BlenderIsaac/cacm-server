extends Camera2D

var pos = Vector2()
export var SPEED = 1
export var shake_multiplyer = 1


var shake = 0


func _ready():
	pos = global_position


func _physics_process(_delta):
	
	
	if Input.is_action_pressed("cam_down"):
		pos.y += SPEED*zoom.y
	if Input.is_action_pressed("cam_up"):
		pos.y -= SPEED*zoom.y
	if Input.is_action_pressed("cam_left"):
		pos.x -= SPEED*zoom.x
	if Input.is_action_pressed("cam_right"):
		pos.x += SPEED*zoom.x
	
	
	if pos.x < limit_left + 300:
		pos.x = limit_left + 300
	
	if pos.x > limit_right - 300:
		pos.x = limit_right - 300
	
	if pos.y < limit_top + 200:
		pos.y = limit_top + 200
	
	if pos.y > limit_bottom - 200:
		pos.y = limit_bottom - 200
	
	
	global_position = pos#lerp(global_position, pos, 0.3)


func _process(delta):
	
	randomize()
	
	offset.x = lerp(offset.x, rand_range(-shake, shake)*shake_multiplyer, 0.5)
	offset.y = lerp(offset.x, rand_range(-shake, shake)*shake_multiplyer, 0.5)
	
	
	
	shake = lerp(shake, 0, 0.06)
	
	if shake < 0:
		shake = 0



