extends Node2D
class_name Main

const GameManager = preload("res://scenes/Managers/GameManager/GameManager.tscn")
var gameManager: GameManager
const MainMenu = preload("res://scenes/UI/Menus/MainMenu/MainMenu.tscn")
var mainMenu: MainMenu
const Credits = preload("res://scenes/UI/Menus/Credits/Credits.tscn")
const Options = preload("res://scenes/UI/Menus/Options/Options.tscn")
const Lobby = preload("res://scenes/UI/Menus/Lobby/Lobby.tscn")
var lobby: Lobby
var options: Options
var credits: Credits
const Mode = preload("res://scenes/UI/Menus/Mode/Mode.tscn")
var mode: Mode
var muted = false
var voiceMuted = false
var sfxMuted = false
var players_loaded = 0
var difficulty = 2
var playersLoadedIntoLobby: int = 0
var won = false
var volume: float = -6.0

# Called when the node enters the scene tree for the first time.
func _ready():
	navToMain()

func _on_Options_volume(volume):
	self.volume = volume
	setVol()

func setVol():
	if volume <= -60.0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume)

# Every peer will call this when they have loaded the game scene. Lobby.player_loaded.rpc_id(1)
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == 2:
			gameManager.start_multiplayer_game()
			players_loaded = 0

func _on_lobby_start(game, mode):
	remove_child(lobby)
	gameManager = game
	gameManager.loaded_multiplayer.connect(_on_gameManager_loaded_multiplayer)
	gameManager.backToMenu.connect(onlineGameBackToLobby)
	gameManager.disconnected.connect(_on_mainMenu_multi) #todo disconnected never emits.
	gameManager.mode = mode
	add_child(gameManager, true)
	if muted:
		gameManager.muteMusic()
	if voiceMuted:
		gameManager.muteCountdown()
	if sfxMuted:
		gameManager.muteSfx()
	gameManager.loadMultiplayer()

func onlineGameBackToLobby():
	#lobby.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(lobby, true)
	remove_child(gameManager)
	if gameManager != null:
		gameManager.queue_free()
	loadBackIntoLobby.rpc_id(1)

@rpc("authority", "call_local", "reliable")
func processLobby(): #lobby.process_mode = Node.PROCESS_MODE_INHERIT
	if multiplayer.is_server():
		lobby.startEnabled = true

@rpc("any_peer", "call_local", "reliable")
func loadBackIntoLobby():
	if multiplayer.is_server():
		playersLoadedIntoLobby += 1
		if playersLoadedIntoLobby == 2:
			playersLoadedIntoLobby = 0
			processLobby.rpc()

func _on_gameManager_loaded_multiplayer():
	player_loaded.rpc_id(1)

func _on_mainMenu_multi():
	remove_child(gameManager)
	remove_child(mainMenu)
	if mainMenu != null:
		mainMenu.queue_free()
	if gameManager != null:
		gameManager.queue_free()
	if lobby != null:
		lobby.queue_free()
	lobby = Lobby.instantiate()
	lobby.back.connect(navToMain)
	lobby.start.connect(_on_lobby_start)
	add_child(lobby, true)

func navToMode():
	remove_child(mainMenu)
	remove_child(gameManager)
	if mainMenu != null:
		mainMenu.queue_free()
	if gameManager != null:
		gameManager.queue_free()
	mode = Mode.instantiate()
	mode.back.connect(_on_mode_back)
	mode.start.connect(_on_mode_start)
	add_child(mode)
	if won:
		mode.showAlt()
	mode.setDifficulty(difficulty)

func _on_mode_start(difficulty):
	self.difficulty = difficulty
	navToGame()

func _on_mode_back(difficulty):
	self.difficulty = difficulty
	navToMain()

func navToGame():
	remove_child(mode)
	if mode != null:
		mode.queue_free()
	gameManager = GameManager.instantiate()
	gameManager.backToMenu.connect(navToMode)
	gameManager.setDifficulty(difficulty)
	gameManager.won_very_hard.connect(_on_gameManager_won_very_hard)
	add_child(gameManager)
	if muted:
		gameManager.muteMusic()
	if voiceMuted:
		gameManager.muteCountdown()
	if sfxMuted:
		gameManager.muteSfx()
	gameManager.start_singleplayer_game()

func _on_gameManager_won_very_hard():
	won = true

func navToMain():
	remove_child(gameManager)
	remove_child(options)
	remove_child(lobby)
	remove_child(mode)
	if mode != null:
		mode.queue_free()
	if options != null:
		options.queue_free()
	if gameManager != null:
		gameManager.queue_free()
	if lobby != null:
		lobby.queue_free()
	mainMenu = MainMenu.instantiate()
	mainMenu.multi.connect(_on_mainMenu_multi)
	mainMenu.play.connect(navToMode)
	mainMenu.options.connect(navToOptions)
	mainMenu.exit.connect(_on_mainMenu_exit)
	add_child(mainMenu)
	if won:
		mainMenu.showAltBackground()

func navToOptions():
	remove_child(credits)
	remove_child(mainMenu)
	if mainMenu != null:
		mainMenu.queue_free()
	if credits != null:
		credits.queue_free()
	options = Options.instantiate()
	options.volume.connect(_on_Options_volume)
	options.mute_music.connect(_on_options_mute_music)
	options.mute_voice.connect(_on_options_mute_voice)
	options.mute_sfx.connect(_on_options_mute_sfx)
	options.credits.connect(_on_options_credits)
	options.back.connect(_on_options_back)
	add_child(options)
	options.setVolume(volume)
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
