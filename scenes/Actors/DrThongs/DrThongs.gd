extends Node2D
class_name DrThongs

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func flex():
	$AnimatedSprite2D.frame = 1
	$AnimatedSprite2D.position = Vector2(0, -89)
	%Speech.visible = true
	%Speech.frame = randi_range(0, 2)

func unflex():
	$AnimatedSprite2D.frame = 0
	$AnimatedSprite2D.position = Vector2(0, 0)
	%Speech.visible = false

func lose():
	$AnimatedSprite2D.frame = 2
	$AnimatedSprite2D.position = Vector2(0, 212)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
