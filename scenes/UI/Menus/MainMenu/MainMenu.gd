extends CanvasLayer
class_name MainMenu
signal play
signal multi
signal options
signal exit

# Called when the node enters the scene tree for the first time.
func _ready():
	%Play.pressed.connect(_on_Play_pressed)
	%Multiplayer.pressed.connect(_on_Multiplayer_pressed)
	%Options.pressed.connect(_on_Options_pressed)
	%Exit.pressed.connect(_on_Exit_pressed)

func showAltBackground():
	$Background.visible = false
	$AltBackground.visible = true
	%DrThongs.set_modulate(Color(1,1,1,0))

func _on_Play_pressed():
	emit_signal("play")

func _on_Multiplayer_pressed():
	emit_signal("multi")

func _on_Options_pressed():
	emit_signal("options")

func _on_Exit_pressed():
	emit_signal("exit")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("exit"):
		_on_Exit_pressed()
	elif event.is_action_pressed("start") || event.is_action_pressed("place"):
		_on_Play_pressed()
