extends Node2D
class_name Main

const GameManager = preload("res://scenes/Managers/GameManager/GameManager.tscn")
var gameManager: GameManager
const MainMenu = preload("res://scenes/UI/Menus/MainMenu/MainMenu.tscn")
var mainMenu: MainMenu
const Credits = preload("res://scenes/UI/Menus/Credits/Credits.tscn")
const Options = preload("res://scenes/UI/Menus/Options/Options.tscn")
var options: Options
var credits: Credits
var muted = false
var voiceMuted = false
var sfxMuted = false

# Called when the node enters the scene tree for the first time.
func _ready():
	navToMain()

func navToGame():
	remove_child(mainMenu)
	if mainMenu != null:
		mainMenu.queue_free()
	gameManager = GameManager.instantiate()
	gameManager.backToMenu.connect(navToMain)
	add_child(gameManager)
	if !muted:
		gameManager.playMusic()
	if voiceMuted:
		gameManager.muteCountdown()
	if sfxMuted:
		gameManager.muteSfx()

func navToMain():
	remove_child(gameManager)
	remove_child(options)
	if options != null:
		options.queue_free()
	if gameManager != null:
		gameManager.queue_free()
	mainMenu = MainMenu.instantiate()
	mainMenu.play.connect(navToGame)
	mainMenu.options.connect(navToOptions)
	mainMenu.exit.connect(_on_mainMenu_exit)
	add_child(mainMenu)

func navToOptions():
	remove_child(credits)
	remove_child(mainMenu)
	if mainMenu != null:
		mainMenu.queue_free()
	if credits != null:
		credits.queue_free()
	options = Options.instantiate()
	options.mute_music.connect(_on_options_mute_music)
	options.mute_voice.connect(_on_options_mute_voice)
	options.mute_sfx.connect(_on_options_mute_sfx)
	options.credits.connect(_on_options_credits)
	options.back.connect(_on_options_back)
	add_child(options)
	if voiceMuted:
		options.setVoiceMuted()
	if muted:
		options.setMusicMuted()
	if sfxMuted:
		options.setSfxMuted()

func _on_options_credits():
	navToCredits()

func navToCredits():
	remove_child(options)
	options.queue_free()
	credits = Credits.instantiate()
	credits.back.connect(navToOptions)
	add_child(credits)

func _on_options_mute_sfx():
	sfxMuted = !sfxMuted

func _on_options_mute_voice():
	voiceMuted = !voiceMuted

func _on_options_mute_music():
	muted = !muted

func _on_options_back():
	navToMain()

func _on_mainMenu_exit():
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
