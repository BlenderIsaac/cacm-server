extends TextureButton

export var function_name = "start"
export (NodePath) var node


#func _ready():
#	randomize()
#	$flash.seek(rand_range(0, 3), true)


func press():
	get_node(node).call(function_name)


func button_over():
	$Bonk.play()


func button_on():
	$Beep.play()


func _process(delta):
	if is_hovered():
		$Flash.hide()
		$flash.seek(0.5, true)
	else:
		$Flash.show()
