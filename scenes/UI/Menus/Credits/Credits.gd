extends CanvasLayer
class_name Credits
signal back

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	get_viewport().set_input_as_handled()
	if(event.is_pressed()):
		emit_signal("back")
