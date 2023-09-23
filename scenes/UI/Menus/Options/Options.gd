extends CanvasLayer
class_name Options

signal mute_music
signal mute_voice
signal mute_sfx
signal credits
signal back
signal volume(volume)

var volumeLevel: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	%Sound.pressed.connect(_on_Sound_pressed)
	%Volume.pressed.connect(_on_Volume_pressed)
	%MuteMusic.pressed.connect(_on_MuteMusic_pressed)
	%MuteSfx.pressed.connect(_on_MuteSfx_pressed)
	%MuteVoice.pressed.connect(_on_MuteVoice_pressed)
	%Credits.pressed.connect(_on_Credits_pressed)
	%Back.pressed.connect(_on_Back_pressed)

func setVolume(vol: float):
	vol = vol - 6.0
	if vol < -60.0:
		vol = 0.0
	volumeLevel = vol
	_on_Volume_pressed()

func _on_Volume_pressed():
	if volumeLevel == 0.0:
		volumeLevel = -60.0
		%Volume.text = "Volume 0%"
	elif volumeLevel == -60.0:
		volumeLevel = -54.0
		%Volume.text = "Volume 10%"
	elif volumeLevel == -54.0:
		volumeLevel = -48.0
		%Volume.text = "Volume 20%"
	elif volumeLevel == -48.0:
		volumeLevel = -42.0
		%Volume.text = "Volume 30%"
	elif volumeLevel == -42.0:
		volumeLevel = -36.0
		%Volume.text = "Volume 40%"
	elif volumeLevel == -36.0:
		volumeLevel = -30.0
		%Volume.text = "Volume 50%"
	elif volumeLevel == -30.0:
		volumeLevel = -24.0
		%Volume.text = "Volume 60%"
	elif volumeLevel == -24.0:
		volumeLevel = -18.0
		%Volume.text = "Volume 70%"
	elif volumeLevel == -18.0:
		volumeLevel = -12.0
		%Volume.text = "Volume 80%"
	elif volumeLevel == -12.0:
		volumeLevel = -6.0
		%Volume.text = "Volume 90%"
	elif volumeLevel == -6.0:
		volumeLevel = 0.0
		%Volume.text = "Volume 100%"
	emit_signal("volume", volumeLevel)

func _on_Sound_pressed():
	%Credits.visible = false
	%Sound.visible = false
	%Volume.visible = true
	%MuteMusic.visible = true
	%MuteSfx.visible = true
	%MuteVoice.visible = true

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
	if %Volume.visible:
		%Credits.visible = true
		%Sound.visible = true
		%Volume.visible = false
		%MuteMusic.visible = false
		%MuteSfx.visible = false
		%MuteVoice.visible = false
	else:
		emit_signal("back")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if !event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("exit") || event.is_action_pressed("start"):
		_on_Back_pressed()
