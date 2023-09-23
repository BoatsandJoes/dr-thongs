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
signal disconnected
signal won_very_hard
var voiceMuted: bool = false
var sfxMuted: bool = false
var musicMuted: bool = false
var won: bool = false
var difficulty: int = 0
var mode: int = 0
var multiFlag = false
var pingTimer: Timer
var pingTestTimeElapsed: float
var pingTestCount: int = 0
var mutex: Mutex

# Called when the node enters the scene tree for the first time.
func _ready():
	mutex = Mutex.new()
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
	grid.lost.connect(_on_grid_lost)
	grid.difficulty = difficulty
	add_child(grid)
	grid.init()
	ghostPiece = Piece.instantiate()
	ghostPiece.set_modulate(Color(1,1,1,0.6))
	add_child(ghostPiece)
	playerPiece = Piece.instantiate()
	add_child(playerPiece)
	if difficulty == 1:
		playerPiece.easy()
	generatePieceSequence()
	playerPiece.setRandomShape(mode, multiplayer.is_server(), grid.getRemainingColors(),
	pieceSequence[pieceSeqIndex % pieceSequence.size()])
	pieceYIndex = grid.gridWidth / 2 - 2
	queue = [Piece.instantiate(), Piece.instantiate()]
	for piece in range(queue.size()):
		add_child(queue[piece])
		queue[piece].setRandomShape(mode, multiplayer.is_server(), grid.getRemainingColors(),
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

func _on_multiplayer_peer_disconnected():
	emit_signal("disconnected")

func loadMultiplayer():
	pingTimer = Timer.new()
	pingTimer.autostart = false
	pingTimer.one_shot = true
	pingTimer.timeout.connect(_on_pingTimer_timeout)
	add_child(pingTimer)
	multiFlag = true
	grid.multiFlag = true
	if multiplayer.is_server():
		pieceXIndex = grid.gridWidth / 2 - 2 - 3
	else:
		pieceXIndex = grid.gridWidth / 2 - 2 + 3
	drawPlayerPiecePosition()
	playerPiece.visible = false
	drawQueuePosition()
	#TODO load the two doctors
	thongs = DrThongs.instantiate()
	thongs.position = Vector2(1066, 415)
	add_child(thongs)
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
	ghostPiece.setRandomShape(mode, true, grid.getRemainingColors(),
	ghostSeq[ghostSeqIndex % ghostSeq.size()])
	ghostPieceYIndex = grid.gridWidth / 2 - 2
	ghostPieceXIndex = grid.gridWidth / 2 - 2 - 3
	updateGhostPosition()
	timeElapsed = 0.0
	previousStates.append(SaveState.of(grid.board, -1.0, PackedInt32Array(),
	Globals.PieceColor.Empty, 1, [], -1))
	syncStateServer.rpc(JSON.stringify({"pieceSeq": pieceSequence}))

@rpc("any_peer","call_remote","reliable")
func syncStateServer(pieceSeq: String):
	ghostSeq = pieceSeqDictFixTypes(JSON.parse_string(pieceSeq)["pieceSeq"])
	ghostPiece.setRandomShape(mode, false, grid.getRemainingColors(),
	ghostSeq[ghostSeqIndex % ghostSeq.size()])
	ghostPieceYIndex = grid.gridWidth / 2 - 2
	ghostPieceXIndex = grid.gridWidth / 2 - 2 + 3
	updateGhostPosition()
	timeElapsed = 0.0
	previousStates.append(SaveState.of(grid.board, -1.0, PackedInt32Array(),
	Globals.PieceColor.Empty, 1, [], -1))
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
	if mode != 2:
		gameTimer.start()
	else:
		hud.hideTimer()
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
		if !gameTimer.is_stopped() || (mode == 2 && thongs.isFlex()):
			gameEndSfx.stream = VictoryVoice
		else:
			gameEndSfx.stream = GameOverVoice
		voicePlayed = true
		if !voiceMuted:
			gameEndSfx.play()
	else:
		voicePlayed = false
		enableQuickExit = true

func _on_grid_lost():
	gameTimer.paused = true
	grid.clearDelay.stop()
	_on_gameTimer_timeout()

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
	if false: #multiFlag:
		#todo multiplayer victory check
		pass
	else:
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
			if !multiFlag:
				emit_signal("won_very_hard")
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
		if thongs.isFlex():
			thongs.unflex()
		gameTimer.paused = false
		if !playerPiece.visible:
			advanceQueue()
		if !ghostPiece.visible:
			advanceGhostQueue()

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
	playerPiece.spin(direction)
	if multiFlag:
		rotateGhost.rpc(playerPiece.state)

func drawPlayerPiecePosition():
	if multiFlag:
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

@rpc("any_peer", "call_remote", "reliable")
func backToLobby():
	emit_signal("backToMenu")

func _input(event):
	if !event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
	if enableQuickExit && event.is_action_pressed("place"):
		if multiFlag:
			backToLobby.rpc()
		emit_signal("backToMenu")
	elif event.is_action_pressed("exit") || event.is_action_pressed("start"):
		if multiFlag:
			backToLobby.rpc()
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
		if multiFlag:
			placeAndResimulateLocal()
		elif grid.place(playerPiece, pieceXIndex, pieceYIndex):
			advanceQueue()

#xxx hide ghost on lose or win

@rpc("any_peer", "call_remote", "reliable")
func placeAndResimulate(seqIndex: int, x: int, y: int, rotate: int, timeElapsed: float, color: int):
	mutex.lock()
	var i: int = previousStates.size() - 1
	while previousStates[i].timeElapsed > timeElapsed:
		i -= 1
	var state = previousStates[i]
	if state.timeElapsed == timeElapsed:
		if state.playerId != 1 && !multiplayer.is_server():
			i -= 1
			state = previousStates[i]
		elif ((state.playerId == 1 && !multiplayer.is_server())
		|| (state.playerId != 1 && multiplayer.is_server())):
			#two placements in one frame: ignore. I think this is paranoid coding though.
			mutex.unlock()
			return false
	var piece = ghostSeq[ghostSeqIndex]
	var shape = playerPiece.shapes[piece["shape"]][rotate]
	var pieceCells = PackedInt32Array()
	for j in shape.size():
		if shape[j] == 2:
			pieceCells.append(grid.getFlatIndex(Vector2i(x + (j % 5), y + (j / 5))))
	var newBoard = grid.placePieceIntoBoard(pieceCells, color, state.board)
	if newBoard == null:
		mutex.unlock()
		return false
	else:
		ghostPieceYIndex = grid.gridWidth / 2 - 2
		if multiplayer.is_server():
			ghostPieceXIndex = grid.gridWidth / 2 - 2 + 3
		else:
			ghostPieceXIndex = grid.gridWidth / 2 - 2 - 3
		updateGhostPosition()
		var serverBonkIndex = -2
		var clientBonkIndex = -2
		grid.placeSfx()
		var id = 2
		if !multiplayer.is_server():
			id = 1
		#check for clears
		var clears = []
		var clearedBoard = grid.removeAllClears(newBoard)
		if clearedBoard != null:
			newBoard = clearedBoard["clearedBoard"]
			clears = clearedBoard["clears"]
			grid.playClearSfx()
			#Start their clear delay if we aren't already in clear delay. End of clear delay will advance queue
			if grid.clearDelay.is_stopped():
				grid.clearDelay.start(4.0/3.0 - self.timeElapsed - timeElapsed)
				ghostPiece.visible = false
			elif (thongs.isFlex() && 4.0/3.0 - grid.clearDelay.time_left <
			self.timeElapsed - timeElapsed):
				_on_grid_clearsComplete() #xxx
		previousStates.insert(i + 1,SaveState.of(newBoard, timeElapsed, pieceCells, color, id,
		clears, seqIndex))
		#resimulate, basically just repeating what we just did for every save state until the end.
		var allClears: Array = []
		if clears.size() > 0:
			allClears.append_array(clears)
		var statesToRemove: Array[int] = []
		for r in range(i + 2, previousStates.size()):
			var prevBoard = previousStates[r - 1]["board"]
			var resimulateState = previousStates[r]
			if ((resimulateState.playerId == 1 && serverBonkIndex > -2)
			|| (resimulateState.playerId != 1 && clientBonkIndex > -2)):
				resimulateState.board = prevBoard
				statesToRemove.append(r)
			else:
				var nextBoard = grid.placePieceIntoBoard(resimulateState.cellIndexes,
				resimulateState.cellsColor, prevBoard)
				if nextBoard == null:
					#Bonk. All later states for this id should be removed.
					resimulateState.board = prevBoard
					statesToRemove.append(r)
					if resimulateState.playerId == 1:
						serverBonkIndex = resimulateState.pieceSeqIndex
					else:
						clientBonkIndex = resimulateState.pieceSeqIndex
				else:
					#check for clears
					var clearedCells: PackedInt32Array = PackedInt32Array()
					var boardAfterClears = grid.removeAllClears(nextBoard)
					if boardAfterClears != null:
						nextBoard = boardAfterClears["clearedBoard"]
						clearedCells = boardAfterClears["clears"]
						#todo Invalid get index 'clears' (on base: 'Nil').
						#at: GameManager.placeAndResimulate (res://scenes/Managers/GameManager/GameManager.gd:608)
						allClears.append_array(clearedCells)
						#todo the way we handle clear delay here should be a tiny bit different.
			#			if grid.clearDelay.is_stopped():
			#				grid.clearDelay.start(4.0/3.0)
			#				playerPiece.visible = false
			#				thongs.flex()
					previousStates[r] = SaveState.of(nextBoard, resimulateState.timeElapsed,
					resimulateState.cellIndexes, resimulateState.cellsColor, resimulateState.playerId,
					clearedCells, resimulateState.pieceSeqIndex)
		#visual update of clears
		grid.updateClearsMulti(allClears)
		#todo log array and look for ints
		for v in range(statesToRemove.size() - 1, -1, -1):
			previousStates.remove_at(statesToRemove[v])
		#todo only update cells that have changed, instead of all.
		grid.updateBoard(previousStates[previousStates.size() - 1].board) 
		grid.checkVictory(mode, multiplayer.is_server())
		ghostSeqIndex = seqIndex + 1
		updateGhostQueueToIndex(ghostSeqIndex)
		if (serverBonkIndex > -2 && !multiplayer.is_server()) || (clientBonkIndex > -2 && multiplayer.is_server()):
			updateGhostQueueToIndex(clientBonkIndex)
		if (serverBonkIndex > -2 && multiplayer.is_server()) || (clientBonkIndex > -2 && !multiplayer.is_server()):
			updateQueueToIndex(serverBonkIndex)
		mutex.unlock()
		return true
	mutex.unlock()

func placeAndResimulateLocal() -> bool:
	mutex.lock()
	var i: int = previousStates.size() - 1
	while previousStates[i].timeElapsed > timeElapsed:
		i -= 1
	var state = previousStates[i]
	if state.timeElapsed == timeElapsed:
		if state.playerId != 1 && multiplayer.is_server():
			i -= 1
			state = previousStates[i]
		elif ((state.playerId == 1 && multiplayer.is_server())
		|| (state.playerId != 1 && !multiplayer.is_server())):
			#two placements in one frame: ignore. I think this is paranoid coding though.
			mutex.unlock()
			return false
	var shape = playerPiece.getCurrentShape()
	var pieceCells = PackedInt32Array()
	for j in shape.size():
		if shape[j] == 2:
			pieceCells.append(grid.getFlatIndex(Vector2i(pieceXIndex + (j % 5), pieceYIndex + (j / 5))))
	var newBoard = grid.placePieceIntoBoard(pieceCells, playerPiece.color, state.board)
	if newBoard == null:
		grid.bonkSfxPlay()
		mutex.unlock()
		return false
	else:
		var serverBonkIndex = -2
		var clientBonkIndex = -2
		placeAndResimulate.rpc(pieceSeqIndex, pieceXIndex, pieceYIndex, playerPiece.state, timeElapsed,
		playerPiece.color)
		grid.placeSfx()
		var id = 2
		if multiplayer.is_server():
			id = 1
		#check for clears
		var clears = []
		var clearedBoard = grid.removeAllClears(newBoard)
		if clearedBoard != null:
			newBoard = clearedBoard["clearedBoard"]
			clears = clearedBoard["clears"]
			grid.playClearSfx()
			#Start clear delay if we aren't already in clear delay. End of clear delay will advance queue
			if grid.clearDelay.is_stopped():
				grid.clearDelay.start(4.0/3.0)
				playerPiece.visible = false
				thongs.flex()
		previousStates.insert(i + 1,SaveState.of(newBoard, timeElapsed, pieceCells, playerPiece.color, id,
		clears, pieceSeqIndex))
		#resimulate, basically just repeating what we just did for every save state until the end.
		var allClears: Array = []
		if clears.size() > 0:
			allClears.append_array(clears)
		var statesToRemove: Array[int] = []
		for r in range(i + 2, previousStates.size()):
			var prevBoard = previousStates[r - 1]["board"]
			var resimulateState = previousStates[r]
			if ((resimulateState.playerId == 1 && serverBonkIndex > -2)
			|| (resimulateState.playerId != 1 && clientBonkIndex > -2)):
				resimulateState.board = prevBoard
				statesToRemove.append(r)
			else:
				var nextBoard = grid.placePieceIntoBoard(resimulateState.cellIndexes,
				resimulateState.cellsColor, prevBoard)
				if nextBoard == null:
					#Bonk. All later states for this id should be removed.
					resimulateState.board = prevBoard
					statesToRemove.append(r)
					if resimulateState.playerId == 1:
						serverBonkIndex = resimulateState.pieceSeqIndex
					else:
						clientBonkIndex = resimulateState.pieceSeqIndex
				else:
					#check for clears
					var clearedCells: PackedInt32Array = PackedInt32Array()
					var boardAfterClears = grid.removeAllClears(nextBoard)
					if boardAfterClears != null:
						nextBoard = boardAfterClears["clearedBoard"]
						clearedCells = boardAfterClears["clears"]
						allClears.append_array(clearedCells)
						#todo the way we handle clear delay here should be a tiny bit different.
			#			if grid.clearDelay.is_stopped():
			#				grid.clearDelay.start(4.0/3.0)
			#				playerPiece.visible = false
			#				thongs.flex()
					previousStates[r] = SaveState.of(nextBoard, resimulateState.timeElapsed,
					resimulateState.cellIndexes, resimulateState.cellsColor, resimulateState.playerId,
					clearedCells, resimulateState.pieceSeqIndex)
		#visual update of clears
		grid.updateClearsMulti(allClears)
		for v in range(statesToRemove.size() - 1, -1, -1):
			previousStates.remove_at(statesToRemove[v])
		#todo only update cells that have changed, instead of all.
		grid.updateBoard(previousStates[previousStates.size() - 1].board) 
		grid.checkVictory(mode, multiplayer.is_server())
		if (serverBonkIndex > -2 && !multiplayer.is_server()) || (clientBonkIndex > -2 && multiplayer.is_server()):
			updateGhostQueueToIndex(clientBonkIndex)
		if (serverBonkIndex > -2 && multiplayer.is_server()) || (clientBonkIndex > -2 && !multiplayer.is_server()):
			updateQueueToIndex(serverBonkIndex)
		elif playerPiece.visible:
			advanceQueue()
		mutex.unlock()
		return true

func updateGhostQueueToIndex(index):
	ghostSeqIndex = index
	ghostPiece.setRandomShape(mode, !multiplayer.is_server(), grid.getRemainingColors(),
	ghostSeq[ghostSeqIndex % ghostSeq.size()])
#	for i in queue.size(): todo update for ghostly queue
#		queue[i].setRandomShape(grid.getRemainingColors(),
#		pieceSequence[(pieceSeqIndex + i + 1) % pieceSequence.size()])

func updateQueueToIndex(index):
	pieceSeqIndex = index
	playerPiece.setRandomShape(mode, multiplayer.is_server(), grid.getRemainingColors(),
	pieceSequence[pieceSeqIndex % pieceSequence.size()])
	for i in queue.size():
		queue[i].setRandomShape(mode, multiplayer.is_server(), grid.getRemainingColors(),
		pieceSequence[(pieceSeqIndex + i + 1) % pieceSequence.size()])

func advanceGhostQueue():
	ghostPiece.visible = true
	ghostPiece.setRandomShape(mode, !multiplayer.is_server(), grid.getRemainingColors(),
	ghostSeq[ghostSeqIndex % ghostSeq.size()])
	ghostPieceYIndex = grid.gridHeight / 2 - 2
	if multiplayer.is_server():
		ghostPieceXIndex = grid.gridWidth / 2 - 2 + 3
	else:
		ghostPieceXIndex = grid.gridWidth / 2 - 2 - 3
	updateGhostPosition()

func advanceQueue():
	#todo make sure that color sequence modification doesn't result in WILD bugs.
	if !grid.clearing:
		playerPiece.visible = true
		pieceSeqIndex += 1
		if multiFlag:
			playerPiece.setPiece(queue[0])
			for i in queue.size():
				if i == queue.size() - 1:
					queue[i].setRandomShape(mode, multiplayer.is_server(), grid.getRemainingColors(),
					pieceSequence[(pieceSeqIndex + i + 1) % pieceSequence.size()])
				else:
					queue[i].setPiece(queue[i + 1])
		else:
			playerPiece.setPiece(queue[0])
			for i in range(0, queue.size() - 1):
				queue[i].setPiece(queue[i + 1])
			queue[queue.size() - 1].setShape(playerPiece.shapes[randi_range(0, playerPiece.shapes.size() -1)],
			randi_range(0, 3), grid.remainingColors[randi_range(0, grid.remainingColors.size() - 1)])
		pieceYIndex = grid.gridHeight / 2 - 2
		if multiFlag:
			if multiplayer.is_server():
				pieceXIndex = grid.gridWidth / 2 - 2 - 3
			else:
				pieceXIndex = grid.gridWidth / 2 - 2 + 3
		else:
			pieceXIndex = grid.gridWidth / 2 - 2
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
