extends CanvasLayer
class_name Mode

signal back(difficulty)
signal start(difficulty)

var DrThongs = preload("res://scenes/Actors/DrThongs/DrThongs.tscn")
var thongs: DrThongs
var difficulty = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	thongs = DrThongs.instantiate()
	thongs.position = Vector2(244, 420)
	thongs.scale = Vector2(-1, 1)
	add_child(thongs)
	%Mode.pressed.connect(_on_Mode_pressed)
	%Start.pressed.connect(_on_Start_pressed)
	%Back.pressed.connect(_on_Back_pressed)

func showAlt():
	$AltBackground.visible = true
	$Background.visible = false
	thongs.visible = false

func _on_Start_pressed():
	emit_signal("start", difficulty)

func _on_Mode_pressed():
	if difficulty == 0:
		setDifficulty(2)
	elif difficulty == 2:
		setDifficulty(1)
	else:
		setDifficulty(0)

func cycleModeBackwards():
	if difficulty == 0:
		setDifficulty(1)
	elif difficulty == 2:
		setDifficulty(0)
	else:
		setDifficulty(2)

func _on_Back_pressed():
	emit_signal("back", difficulty)

func setDifficulty(difficulty):
	self.difficulty = difficulty
	if self.difficulty == 1:
		%Mode.text = "\"\"\"Easy\"\"\""
		thongs.unflex()
	elif difficulty == 2:
		%Mode.text = "Hard"
		thongs.flexNoSpeech()
	else:
		thongs.lose()
		%Mode.text = "Very Hard"

func _input(event):
	if !event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("exit"):
		emit_signal("back", difficulty)
	elif event.is_action_pressed("place"):
		emit_signal("start", difficulty)
	elif ( event.is_action_pressed("cw") || event.is_action_pressed("right") || event.is_action_pressed("down")):
		_on_Mode_pressed()
	elif (event.is_action_pressed("ccw") || event.is_action_pressed("left") || event.is_action_pressed("up")):
		cycleModeBackwards()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
