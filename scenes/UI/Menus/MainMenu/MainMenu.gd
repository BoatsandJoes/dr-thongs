extends CanvasLayer
class_name MainMenu
signal play
signal exit
signal mute
signal mute_voice
signal credits

# Called when the node enters the scene tree for the first time.
func _ready():
	%Play.pressed.connect(_on_Play_pressed)
	%Mute.pressed.connect(_on_Mute_pressed)
	%MuteVoice.pressed.connect(_on_MuteVoice_pressed)
	%Credits.pressed.connect(_on_Credits_pressed)
	%Exit.pressed.connect(_on_Exit_pressed)

func _on_Credits_pressed():
	emit_signal("credits")

func _on_Play_pressed():
	emit_signal("play")

func setMuted():
	%Mute.text = "Unmute Music"

func setVoiceMuted():
	%MuteVoice.text = "Unmute Voice"

func _on_Mute_pressed():
	if %Mute.text == "Mute Music":
		%Mute.text = "Unmute Music"
	else:
		%Mute.text = "Mute Music"
	emit_signal("mute")

func _on_MuteVoice_pressed():
	if %MuteVoice.text == "Mute Voice":
		%MuteVoice.text = "Unmute Voice"
	else:
		%MuteVoice.text = "Mute Voice"
	emit_signal("mute_voice")

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
