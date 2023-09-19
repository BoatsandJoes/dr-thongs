extends CanvasLayer
class_name Mode

signal back(difficulty)
signal start(difficulty)

var DrThongs = preload("res://scenes/Actors/DrThongs/DrThongs.tscn")
var thongs: DrThongs
var difficulty = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	thongs = DrThongs.instantiate()
	thongs.position = Vector2(394, 420)
	thongs.scale = Vector2(-1, 1)
	add_child(thongs)
	%Mode.pressed.connect(_on_Mode_pressed)
	%Back.pressed.connect(_on_Back_pressed)

func _on_Mode_pressed():
	if %Mode.text == "Hard!!!":
		setDifficulty(1)
	else:
		setDifficulty(0)

func _on_Back_pressed():
	emit_signal("back", difficulty)

func setDifficulty(difficulty):
	self.difficulty = difficulty
	if self.difficulty == 1:
		%Mode.text = "\"\"Easy\"\""
		thongs.flexNoSpeech()
	else:
		thongs.lose()
		%Mode.text = "Hard!!!"

func _input(event):
	if !event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("exit"):
		emit_signal("back", difficulty)
	elif event.is_action_pressed("place"):
		emit_signal("start", difficulty)
	elif (event.is_action_pressed("ccw") || event.is_action_pressed("cw") || event.is_action_pressed("left")
	|| event.is_action_pressed("right") || event.is_action_pressed("up") || event.is_action_pressed("down")):
		_on_Mode_pressed()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
