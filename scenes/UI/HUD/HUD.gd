extends CanvasLayer
class_name HUD

var CountdownSfx: Array = [
	preload("res://assets/audio/sfx/1.wav"), preload("res://assets/audio/sfx/2.wav"),
	preload("res://assets/audio/sfx/3.wav"), preload("res://assets/audio/sfx/4.wav"),
	preload("res://assets/audio/sfx/5.wav"), preload("res://assets/audio/sfx/6.wav"),
	preload("res://assets/audio/sfx/7.wav"), preload("res://assets/audio/sfx/8.wav"),
	preload("res://assets/audio/sfx/9.wav"), preload("res://assets/audio/sfx/10.wav")]
var countdownSfx: AudioStreamPlayer
var playedCountdown: int = 11

# Called when the node enters the scene tree for the first time.
func _ready():
	countdownSfx = AudioStreamPlayer.new()
	countdownSfx.set_bus("Reduce")
	add_child(countdownSfx)

func muteCountdown():
	playedCountdown = 0

func updateResult(text: String):
	%Result.text = text

func updateTimer(seconds: float):
	var secondsInt = floori(seconds)
	if secondsInt > 59:
		%TimerDisplay.text = " " + str(secondsInt / 60) + ":" + pad(str(secondsInt % 60))
	else:
		%TimerDisplay.text = "  " + str(secondsInt)
		if secondsInt < playedCountdown && secondsInt > 0:
			countdownSfx.stream = CountdownSfx[secondsInt - 1]
			countdownSfx.play()
			playedCountdown = secondsInt

func pad(str: String) -> String:
	if str.length() == 1:
		str = "0" + str
	return str

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
