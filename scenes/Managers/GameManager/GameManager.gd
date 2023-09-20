extends Node2D
class_name GameManager

const Grid = preload("res://scenes/Level/Grid/Grid.tscn")
var grid: Grid
const Piece = preload("res://scenes/Actors/Piece/Piece.tscn")
var playerPiece: Piece
var ghostPiece: Piece
var queue: Array[Piece]
var pieceSequence: Array
var pieceSeqIndex: int = 0
var ghostSeq: Array
var ghostSeqIndex: int = 0
var ghostPieceXIndex: int
var ghostPieceYIndex: int
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
signal loaded_multiplayer
var voiceMuted: bool = false
var sfxMuted: bool = false
var musicMuted: bool = false
var won: bool = false
var difficulty: int = 0
var multiFlag = false
var pingTimer: Timer
var pingTestTimeElapsed: float
var pingTestCount: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	music = AudioStreamPlayer.new()
	music.set_bus("Reduce")
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
	ghostPiece = Piece.instantiate()
	ghostPiece.set_modulate(Color(0,0,0,0.5))
	add_child(ghostPiece)
	playerPiece = Piece.instantiate()
	add_child(playerPiece)
	if difficulty == 1:
		playerPiece.easy()
	generatePieceSequence()
	playerPiece.setRandomShape(grid.getRemainingColors(),
	pieceSequence[pieceSeqIndex % pieceSequence.size()])
	pieceYIndex = grid.gridWidth / 2 - 2
	queue = [Piece.instantiate(), Piece.instantiate()]
	for piece in range(queue.size()):
		add_child(queue[piece])
		queue[piece].setRandomShape(grid.getRemainingColors(),
		pieceSequence[(pieceSeqIndex + piece + 1) % pieceSequence.size()])
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
	gameTimer.autostart = false
	gameTimer.one_shot = true
	gameTimer.wait_time = 120
	gameTimer.timeout.connect(_on_gameTimer_timeout)
	add_child(gameTimer)

func generatePieceSequence():
	pieceSequence = []
	for i in 180:
		pieceSequence.append(PieceSequence.getRandom())

@rpc("authority", "call_local", "reliable")
func setUpMusic(track: int):
	music.stream = MusicArray[track]
	if !musicMuted:
		playMusic()

func start_singleplayer_game():
	remove_child(ghostPiece)
	ghostPiece.queue_free
	setUpMusic(randi_range(0, MusicArray.size() - 1))
	thongs = DrThongs.instantiate()
	thongs.position = Vector2(1066, 415)
	add_child(thongs)
	pieceXIndex = grid.gridWidth / 2 - 2
	drawPlayerPiecePosition()
	drawQueuePosition()
	gameTimer.start()

func loadMultiplayer():
	pingTimer = Timer.new()
	pingTimer.autostart = false
	pingTimer.one_shot = true
	pingTimer.timeout.connect(_on_pingTimer_timeout)
	add_child(pingTimer)
	multiFlag = true
	if multiplayer.is_server():
		pieceXIndex = grid.gridWidth / 2 - 2 - 3
	else:
		pieceXIndex = grid.gridWidth / 2 - 2 + 3
	drawPlayerPiecePosition()
	playerPiece.visible = false
	drawQueuePosition()
	#TODO load the two doctors
	emit_signal("loaded_multiplayer")

# Called only on the server.
func start_multiplayer_game():
	# All peers are ready to receive RPCs in this scene.
	setUpMusic.rpc(randi_range(0, MusicArray.size() - 1))
	syncStateClient.rpc(JSON.stringify({"pieceSeq": pieceSequence, "board": grid.board}))

func pieceSeqDictFixTypes(seq: Array)->Array:
	for i in seq:
		i.shape = int(i.shape)
		i.state = int(i.state)
		var order = PackedInt32Array()
		for j in i.color_order:
			order.append(int(j))
		i.color_order = order
	return seq

func floatArrayToPackedInt32(array: Array)->PackedInt32Array:
	var result = PackedInt32Array()
	for i in array:
		result.append(int(i))
	return result

@rpc("authority","call_remote","reliable")
func syncStateClient(json: String):
	var result = JSON.parse_string(json)
	grid.updateBoard(floatArrayToPackedInt32(result["board"]))
	ghostSeq = pieceSeqDictFixTypes(result["pieceSeq"])
	ghostPiece.setRandomShape(grid.getRemainingColors(),
	ghostSeq[ghostSeqIndex % ghostSeq.size()])
	ghostPieceYIndex = grid.gridWidth / 2 - 2
	ghostPieceXIndex = grid.gridWidth / 2 - 2 - 3
	updateGhostPosition()
	timeElapsed = 0.0
	saveState()
	syncStateServer.rpc(JSON.stringify({"pieceSeq": pieceSequence}))

@rpc("any_peer","call_remote","reliable")
func syncStateServer(pieceSeq: String):
	ghostSeq = pieceSeqDictFixTypes(JSON.parse_string(pieceSeq)["pieceSeq"])
	ghostPiece.setRandomShape(grid.getRemainingColors(),
	ghostSeq[ghostSeqIndex % ghostSeq.size()])
	ghostPieceYIndex = grid.gridWidth / 2 - 2
	ghostPieceXIndex = grid.gridWidth / 2 - 2 + 3
	updateGhostPosition()
	timeElapsed = 0.0
	saveState()
	#test ping
	pingTestTimeElapsed = timeElapsed
	testPing.rpc()

@rpc("authority", "call_remote", "reliable")
func testPing():
	testPong.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func testPong():
	pingTestCount += 1
	if pingTestCount == 5:
		pingTestTimeElapsed = timeElapsed - pingTestTimeElapsed
		startTimer.rpc(pingTestTimeElapsed / 10.0) #/5 because 5 tests, and /2 because round trip
	else:
		testPing.rpc()

@rpc("authority", "call_local", "reliable")
func startTimer(halfPing: float):
	if multiplayer.is_server():
		pingTimer.wait_time = halfPing
		pingTimer.start()
	else:
		_on_pingTimer_timeout()

func _on_pingTimer_timeout():
	timeElapsed = 0
	gameTimer.start()
	playerPiece.visible = true

func setDifficulty(difficulty: int):
	self.difficulty = difficulty

func playMusic():
	music.play()

func muteMusic():
	musicMuted = true

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
	if difficulty == 1:
		grid.setCells(Globals.PieceColor.Red, range(0, grid.board.size(), 2), {})
		grid.setCells(Globals.PieceColor.Green, range(1, grid.board.size(), 2), {})
	elif difficulty == 2:
		grid.setCells(Globals.PieceColor.Red, range(0, grid.board.size(), 3), {})
		grid.setCells(Globals.PieceColor.Green, range(1, grid.board.size(), 3), {})
		grid.setCells(Globals.PieceColor.Blue, range(2, grid.board.size(), 3), {})
	elif difficulty == 0:
		grid.setCells(Globals.PieceColor.Red, range(0, grid.board.size(), 4), {})
		grid.setCells(Globals.PieceColor.Green, range(1, grid.board.size(), 4), {})
		grid.setCells(Globals.PieceColor.Blue, range(2, grid.board.size(), 4), {})
		grid.setCells(Globals.PieceColor.Yellow, range(3, grid.board.size(), 4), {})
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
			if multiFlag:
				if horizontal != 0:
					moveGhostX.rpc(pieceXIndex)
				if vertical != 0:
					moveGhostY.rpc(pieceYIndex)
			drawPlayerPiecePosition()

@rpc("any_peer", "call_remote", "unreliable_ordered")
func rotateGhost(newState: int):
	ghostPiece.setSpin(newState)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func moveGhostX(newX: int):
	ghostPieceXIndex = newX
	updateGhostPosition()

@rpc("any_peer", "call_remote", "unreliable_ordered")
func moveGhostY(newY: int):
	ghostPieceYIndex = newY
	updateGhostPosition()

func updateGhostPosition():
	ghostPiece.position = Vector2i(50 + ghostPieceXIndex * grid.cellSize,
		35 + ghostPieceYIndex * grid.cellSize)

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
	if multiFlag:
		rotateGhost.rpc(playerPiece.state)

func drawPlayerPiecePosition():
	if multiFlag: #todo
		playerPiece.position = Vector2i(50 + pieceXIndex * grid.cellSize,
		35 + pieceYIndex * grid.cellSize)
	else:
		if difficulty == 1:
			playerPiece.position = Vector2i(9 + pieceXIndex * grid.cellSize,
			11 + pieceYIndex * grid.cellSize)
		else:
			playerPiece.position = Vector2i(50 + pieceXIndex * grid.cellSize,
			35 + pieceYIndex * grid.cellSize)

func drawQueuePosition():
	if multiFlag:
		for i in queue.size():
			queue[i].position = Vector2i(26 + (13) * 50,
			(50 * 13 * 1) / 2 - ((4 * i) + 1) * 50)
	else:
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
		pieceSeqIndex += 1
		playerPiece.setRandomShape(grid.getRemainingColors(),
		pieceSequence[pieceSeqIndex % pieceSequence.size()])
		for i in queue.size():
			queue[i].setRandomShape(grid.getRemainingColors(),
			pieceSequence[(pieceSeqIndex + i + 1) % pieceSequence.size()])
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
