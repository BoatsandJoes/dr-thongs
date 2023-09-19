extends Node2D
class_name GameManager

const Grid = preload("res://scenes/Level/Grid/Grid.tscn")
var grid: Grid
const Piece = preload("res://scenes/Actors/Piece/Piece.tscn")
var playerPiece: Piece
var queue: Array[Piece]
var pieceXIndex: int
var pieceYIndex: int
var horizontalDas: Timer
var verticalDas: Timer
var horizontalDirection: int = 0
var verticalDirection: int = 0
var previousStates: Array[SaveState] = []
var timeElapsed: float = 0.0
var gameTimer: Timer
const HUD = preload("res://scenes/UI/HUD/HUD.tscn")
var hud: HUD
var DrThongs = preload("res://scenes/Actors/DrThongs/DrThongs.tscn")
var thongs: DrThongs
var GameOverSfx = preload("res://assets/audio/sfx/game_over.wav")
var GameOverVoice = preload("res://assets/audio/sfx/you_lose.wav")
var VictorySfx = preload("res://assets/audio/sfx/jingles_HIT04.wav")
var VictoryVoice = preload("res://assets/audio/sfx/you_win.wav")
var MusicArray = [preload("res://assets/audio/music/Luke-Bergs-Tropical-Soulmp3(chosic.com).mp3"),
preload("res://assets/audio/music/Luke-Bergs-Dancin_Mp3(chosic.com).mp3"),
preload("res://assets/audio/music/Luke-Bergs-Daybreak(chosic.com).mp3"),
preload("res://assets/audio/music/Luke-Bergs-Feel-Lovemp3(chosic.com).mp3")]
var music: AudioStreamPlayer
var gameEndSfx: AudioStreamPlayer
var voicePlayed: bool = false
var enableQuickExit: bool = false
signal backToMenu
var voiceMuted: bool = false
var sfxMuted: bool = false
var won: bool = false
var difficulty: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	music = AudioStreamPlayer.new()
	music.set_bus("Reduce")
	music.stream = MusicArray[randi_range(0, MusicArray.size() - 1)]
	music.finished.connect(_on_music_finished)
	add_child(music)
	gameEndSfx = AudioStreamPlayer.new()
	gameEndSfx.finished.connect(_on_gameEndSfx_finished)
	add_child(gameEndSfx)
	hud = HUD.instantiate()
	add_child(hud)
	randomize()
	grid = Grid.instantiate()
	grid.clearStart.connect(_on_grid_clearStart)
	grid.clearsComplete.connect(_on_grid_clearsComplete)
	grid.victory.connect(_on_grid_victory)
	grid.difficulty = difficulty
	add_child(grid)
	grid.init()
	saveState()
	playerPiece = Piece.instantiate()
	add_child(playerPiece)
	if difficulty == 1:
		playerPiece.easy()
	playerPiece.setRandomShape(grid.getRemainingColors())
	thongs = DrThongs.instantiate()
	thongs.position = Vector2(1066, 415)
	add_child(thongs)
	pieceXIndex = grid.gridWidth / 2 - 2
	pieceYIndex = grid.gridWidth / 2 - 2
	drawPlayerPiecePosition()
	queue = [Piece.instantiate(), Piece.instantiate()]
	for piece in range(queue.size()):
		add_child(queue[piece])
		queue[piece].setRandomShape(grid.getRemainingColors())
	drawQueuePosition()
	horizontalDas = Timer.new()
	verticalDas = Timer.new()
	horizontalDas.autostart = false
	verticalDas.autostart = false
	horizontalDas.one_shot = true
	verticalDas.one_shot = true
	horizontalDas.wait_time = 1.0/6.0
	verticalDas.wait_time = 1.0/6.0
	horizontalDas.timeout.connect(_on_horizontalDas_timeout)
	verticalDas.timeout.connect(_on_verticalDas_timeout)
	add_child(horizontalDas)
	add_child(verticalDas)
	gameTimer = Timer.new()
	gameTimer.autostart = true
	gameTimer.one_shot = true
	gameTimer.wait_time = 120
	gameTimer.timeout.connect(_on_gameTimer_timeout)
	add_child(gameTimer)

func setDifficulty(difficulty: int):
	self.difficulty = difficulty

func playMusic():
	music.play()

func muteCountdown():
	hud.muteCountdown()
	voiceMuted = true

func muteSfx():
	sfxMuted = true
	grid.muteSfx()

func _on_music_finished():
	music.play()

func _on_gameEndSfx_finished():
	if !voicePlayed:
		gameEndSfx.set_bus("Reduce")
		if gameTimer.is_stopped():
			gameEndSfx.stream = GameOverVoice
		else:
			gameEndSfx.stream = VictoryVoice
		voicePlayed = true
		if !voiceMuted:
			gameEndSfx.play()
	else:
		voicePlayed = false
		enableQuickExit = true

func _on_gameTimer_timeout():
	music.stop()
	playerPiece.visible = false
	hud.updateResult("     You Lose")
	thongs.lose()
	if !sfxMuted:
		gameEndSfx.stream = GameOverSfx
		gameEndSfx.play()
	elif !voiceMuted:
		_on_gameEndSfx_finished()

func _on_grid_victory():
	won = true
	thongs.flex()
	music.stop()
	gameTimer.paused = true
	grid.setCells(Globals.PieceColor.Red, range(0, grid.board.size(), 2), {})
	grid.setCells(Globals.PieceColor.Green, range(1, grid.board.size(), 2), {})
	hud.updateResult("You Win!")
	if !sfxMuted:
		gameEndSfx.stream = VictorySfx
		gameEndSfx.play()
	elif !voiceMuted:
		_on_gameEndSfx_finished()

func _on_grid_clearStart():
	gameTimer.paused = true
	thongs.flex()

func _on_grid_clearsComplete():
	if !won:
		thongs.unflex()
		gameTimer.paused = false
		advanceQueue()

func saveState():
	previousStates.append(SaveState.of(grid.board, timeElapsed, [])) #todo queue
	#todo check if this state is not the latest and if not, perform a rollback

func _on_horizontalDas_timeout():
	shiftPiece(horizontalDirection, 0)
	horizontalDas.wait_time = 1.0/60.0
	horizontalDas.start()

func _on_verticalDas_timeout():
	shiftPiece(0, verticalDirection)
	verticalDas.wait_time = 1.0/60.0
	verticalDas.start()

func shiftPiece(horizontal: int, vertical: int):
	if playerPiece.visible:
		# walls
		var ok: bool = true
		for i in playerPiece.getCurrentShape().size():
			var newX = pieceXIndex + i % 5 + horizontal
			var newY = pieceYIndex + i / 5 + vertical
			if (playerPiece.getCurrentShape()[i] == 2
			&& (newX < 0 || newX >= grid.gridWidth
			|| newY < 0 || newY >= grid.gridHeight)):
				ok = false
				break
			if !ok:
				break
		if ok:
			pieceXIndex += horizontal
			pieceYIndex += vertical
			drawPlayerPiecePosition()

func spin(direction: int):
	var ghost: Array = playerPiece.predictSpin(direction)
	for i in ghost.size():
		var newX = pieceXIndex + i % 5
		var newY = pieceYIndex + i / 5
		var shifted: bool = false
		if ghost[i] == 2:
			if newX < 0:
				shiftPiece(1, 0)
				shifted = true
			elif newX >= grid.gridWidth:
				shiftPiece(-1, 0)
				shifted = true
			elif newY < 0:
				shiftPiece(0, 1)
				shifted = true
			elif newY >= grid.gridHeight:
				shiftPiece(0, -1)
				shifted = true
		if shifted:
			break
	#todo das to wall (very minor qol)
	playerPiece.spin(direction)

func drawPlayerPiecePosition():
	if difficulty == 1:
		playerPiece.position = Vector2i(10 + pieceXIndex * grid.cellSize, 10 + pieceYIndex * grid.cellSize)
	else:
		playerPiece.position = Vector2i(50 + pieceXIndex * grid.cellSize, 35 + pieceYIndex * grid.cellSize)

func drawQueuePosition():
	for i in queue.size():
		queue[i].position = Vector2i(26 + (13) * 50,
		(50 * 13 * 1) / 2 - ((4 * i) + 1) * 50)

func _input(event):
	if !event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
	if enableQuickExit && event.is_action_pressed("place"):
		emit_signal("backToMenu")
	elif event.is_action_pressed("exit") || event.is_action_pressed("start"):
		emit_signal("backToMenu")
	elif event.is_action_pressed("left"):
		if horizontalDirection == 1:
			releaseHorizontal()
		elif horizontalDirection == 0:
			horizontalDirection = -1
			shiftPiece(-1, 0)
			horizontalDas.start()
	elif event.is_action_pressed("right"):
		if horizontalDirection == -1:
			releaseHorizontal()
		elif horizontalDirection == 0:
			horizontalDirection = 1
			shiftPiece(1, 0)
			horizontalDas.start()
	elif event.is_action_pressed("up"):
		if verticalDirection == 1:
			releaseVertical()
		elif verticalDirection == 0:
			verticalDirection = -1
			shiftPiece(0, -1)
			verticalDas.start()
	elif event.is_action_pressed("down"):
		if verticalDirection == -1:
			releaseVertical()
		elif verticalDirection == 0:
			verticalDirection = 1
			shiftPiece(0, 1)
			verticalDas.start()
	elif event.is_action_released("left"):
		if Input.is_action_pressed("right"):
			horizontalDirection = 1
			shiftPiece(1, 0)
			horizontalDas.start()
		else:
			releaseHorizontal()
	elif event.is_action_released("right"):
		if Input.is_action_pressed("left"):
			horizontalDirection = -1
			shiftPiece(-1, 0)
			horizontalDas.start()
		else:
			releaseHorizontal()
	elif event.is_action_released("up"):
		if Input.is_action_pressed("down"):
			verticalDirection = 1
			shiftPiece(0, 1)
			verticalDas.start()
		else:
			releaseVertical()
	elif event.is_action_released("down"):
		if Input.is_action_pressed("up"):
			verticalDirection = -1
			shiftPiece(0, -1)
			verticalDas.start()
		else:
			releaseVertical()
	elif event.is_action_pressed("cw"):
		spin(1)
	elif event.is_action_pressed("ccw"):
		spin(-1)
	elif event.is_action_pressed("place") && playerPiece.visible:
		if grid.place(playerPiece, pieceXIndex, pieceYIndex):
			advanceQueue()
			saveState()
			#todo if a player clears two blocks then how do you track ownership of the second?
			# The game doesn't know the difference.
			# and if the other player adds to it and clears it, who owns it now?
			#timeout place is another special case because I think it plays a different sound,
			#and failed placement throws the piece away

func advanceQueue():
	if !grid.clearing:
		playerPiece.visible = true
		playerPiece.setPiece(queue[0])
		for i in queue.size() - 1:
			queue[i].setPiece(queue[i + 1])
		queue[queue.size() - 1].setRandomShape(grid.getRemainingColors())
		pieceXIndex = grid.gridWidth / 2 - 2
		pieceYIndex = grid.gridHeight / 2 - 2
		drawPlayerPiecePosition()
	else:
		playerPiece.visible = false

func releaseHorizontal():
	horizontalDirection = 0
	horizontalDas.stop()
	horizontalDas.wait_time = 1.0/6.0

func releaseVertical():
	verticalDirection = 0
	verticalDas.stop()
	verticalDas.wait_time = 1.0/6.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timeElapsed += delta
	hud.updateTimer(gameTimer.time_left)
