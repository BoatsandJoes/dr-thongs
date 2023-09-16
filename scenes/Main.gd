extends Node2D
class_name Main

const GameManager = preload("res://scenes/Managers/GameManager/GameManager.tscn")
var gameManager: GameManager
const MainMenu = preload("res://scenes/UI/Menus/MainMenu/MainMenu.tscn")
var mainMenu: MainMenu
const Credits = preload("res://scenes/UI/Menus/Credits/Credits.tscn")
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
	remove_child(credits)
	if credits != null:
		credits.queue_free()
	if gameManager != null:
		gameManager.queue_free()
	mainMenu = MainMenu.instantiate()
	if muted:
		mainMenu.setMuted()
	if voiceMuted:
		mainMenu.setVoiceMuted()
	if sfxMuted:
		mainMenu.setSfxMuted()
	mainMenu.play.connect(navToGame)
	mainMenu.exit.connect(_on_mainMenu_exit)
	mainMenu.mute.connect(_on_mainMenu_mute)
	mainMenu.mute_voice.connect(_on_mainMenu_mute_voice)
	mainMenu.mute_sfx.connect(_on_mainMenu_mute_sfx)
	mainMenu.credits.connect(_on_mainMenu_credits)
	add_child(mainMenu)

func _on_mainMenu_credits():
	navToCredits()

func navToCredits():
	remove_child(mainMenu)
	mainMenu.queue_free()
	credits = Credits.instantiate()
	credits.back.connect(navToMain)
	add_child(credits)

func _on_mainMenu_mute_sfx():
	sfxMuted = !sfxMuted

func _on_mainMenu_mute_voice():
	voiceMuted = !voiceMuted

func _on_mainMenu_mute():
	muted = !muted

func _on_mainMenu_exit():
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
