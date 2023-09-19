extends CanvasLayer
class_name Options

signal mute_music
signal mute_voice
signal mute_sfx
signal credits
signal back

# Called when the node enters the scene tree for the first time.
func _ready():
	%MuteMusic.pressed.connect(_on_MuteMusic_pressed)
	%MuteSfx.pressed.connect(_on_MuteSfx_pressed)
	%MuteVoice.pressed.connect(_on_MuteVoice_pressed)
	%Credits.pressed.connect(_on_Credits_pressed)
	%Back.pressed.connect(_on_Back_pressed)

func _on_Credits_pressed():
	emit_signal("credits")

func setSfxMuted():
	%MuteSfx.text = "Unmute SFX"


func setMusicMuted():
	%MuteMusic.text = "Unmute Music"

func setVoiceMuted():
	%MuteVoice.text = "Unmute Voice"

func _on_MuteMusic_pressed():
	if %MuteMusic.text == "Mute Music":
		%MuteMusic.text = "Unmute Music"
	else:
		%MuteMusic.text = "Mute Music"
	emit_signal("mute_music")

func _on_MuteVoice_pressed():
	if %MuteVoice.text == "Mute Voice":
		%MuteVoice.text = "Unmute Voice"
	else:
		%MuteVoice.text = "Mute Voice"
	emit_signal("mute_voice")

func _on_MuteSfx_pressed():
	if %MuteSfx.text == "Mute SFX":
		%MuteSfx.text = "Unmute SFX"
	else:
		%MuteSfx.text = "Mute SFX"
	emit_signal("mute_sfx")

func _on_Back_pressed():
	emit_signal("back")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if !event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("exit") || event.is_action_pressed("start"):
		_on_Back_pressed()
