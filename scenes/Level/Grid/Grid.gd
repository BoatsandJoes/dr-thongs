extends Node2D
class_name Grid

var board: PackedInt32Array
const gridHeight: int = 13
const gridWidth: int = 13
const cellSize: int = 50
var clearDelay: Timer
var clearing: bool = false
var remainingColors: Array[int]
var sfxMuted: bool = false
signal victory
signal clearStart
signal clearsComplete
var placePieceSfx: AudioStreamPlayer
var PlacePieceSfx = preload("res://assets/audio/sfx/place.wav")
var bonkSfx: AudioStreamPlayer
var BonkSfxArray: Array = [preload("res://assets/audio/sfx/drop_002.wav"),
preload("res://assets/audio/sfx/drop_003.wav")]
var clearSfx: AudioStreamPlayer
var ClearSfxArray: Array = [
preload("res://assets/audio/sfx/jingles_PIZZI02.wav"), preload("res://assets/audio/sfx/jingles_PIZZI13.wav"),
preload("res://assets/audio/sfx/jingles_PIZZI15.wav"), preload("res://assets/audio/sfx/jingles_SAX02.wav"),
preload("res://assets/audio/sfx/jingles_SAX10.wav"), preload("res://assets/audio/sfx/jingles_SAX13.wav"),
preload("res://assets/audio/sfx/jingles_STEEL02.wav"), preload("res://assets/audio/sfx/jingles_STEEL10.wav"),
preload("res://assets/audio/sfx/jingles_STEEL13.wav")]

# Called when the node enters the scene tree for the first time.
func _ready():
	placePieceSfx = AudioStreamPlayer.new()
	placePieceSfx.stream = PlacePieceSfx
	add_child(placePieceSfx)
	clearSfx = AudioStreamPlayer.new()
	add_child(clearSfx)
	bonkSfx = AudioStreamPlayer.new()
	bonkSfx.set_bus("Boost")
	add_child(bonkSfx)
	clearDelay = Timer.new()
	clearDelay.wait_time = 4.0/3.0
	clearDelay.one_shot = true
	clearDelay.autostart = false
	clearStart.connect(_on_self_clearStart)
	clearDelay.timeout.connect(_on_clearDelay_timeout)
	add_child(clearDelay)
	board = []
	board.resize(gridHeight * gridWidth)
	remainingColors = []
	for i in board.size():
		var color: int = randi_range(0, Globals.PieceColor.size() - 1)
		setCell(color, get2DIndex(i))
		if color != Globals.PieceColor.Empty && !remainingColors.has(color):
			remainingColors.append(color)

func _on_self_clearStart():
	clearing = true
	clearDelay.start()
	if !sfxMuted:
		clearSfx.stream = ClearSfxArray[randi_range(0, ClearSfxArray.size() - 1)]
		clearSfx.play()

func _on_clearDelay_timeout():
	$ClearEffect.clear()
	checkVictory()
	if !checkClears() && clearing == true:
		clearing = false
		emit_signal("clearsComplete")

func muteSfx():
	sfxMuted = true

func getRemainingColors() -> Array[int]:
	return remainingColors

func setCell(color: int, coords: Vector2i):
	board[getFlatIndex(coords)] = color
	if color == Globals.PieceColor.Empty:
		$TileMap.erase_cell(0, coords)
	else:
		$TileMap.set_cells_terrain_connect(0, [coords], color - 1, 0)

func getFlatIndex(coords: Vector2i):
	return coords.y * gridWidth + coords.x

func get2DIndex(i: int) -> Vector2i:
	return Vector2i(i % gridWidth, i / gridWidth)

func getScreenPositionFor2DIndex(index: Vector2i) -> Vector2i:
	return Vector2i(index.x * cellSize, index.y * cellSize)

func updateRemainingColors():
	var colors: Array[int] = []
	for color in board:
		if color != Globals.PieceColor.Empty && !colors.has(color):
			colors.append(color)
	remainingColors = colors

func place(playerPiece: Piece, pieceXIndex: int, pieceYIndex: int) -> bool:
	var piece: Array = playerPiece.getCurrentShape()
	var cells: Array[int] = []
	for i in piece.size():
		if piece[i]:
			var cellIndex: Vector2i = Vector2i(pieceXIndex + i % 3, pieceYIndex + i / 3)
			var flatIndex: int = getFlatIndex(cellIndex)
			if board[flatIndex] == playerPiece.color:
				if !sfxMuted:
					bonkSfx.stream = BonkSfxArray[randi_range(0, BonkSfxArray.size() - 1)]
					bonkSfx.play()
				return false
			cells.append(flatIndex)
	for cell in cells:
		setCell(playerPiece.color, get2DIndex(cell))
	checkClears()
	updateRemainingColors()
	if !sfxMuted:
		placePieceSfx.play()
	return true

func checkClears() -> bool:
	# checkClears
	for row in gridHeight - 1: # 0 to 11: can't squeeze a 2x3 into only the last row
		var cell: int = row * gridWidth
		while cell < ((row + 1) * gridWidth) - 1: #check all cells in row except the last one
			var rightmostCell: int = cell + 1
			while (board[cell] != Globals.PieceColor.Empty && board[cell] == board[rightmostCell]
			&& rightmostCell < (row + 1) * gridWidth):
				rightmostCell += 1
			rightmostCell -= 1
			if rightmostCell - cell > 0:
				var leftCol: int = cell % gridWidth
				var rightCol: int = rightmostCell % gridWidth
				var scanRow: int = row + 1
				var clear: PackedInt32Array = []
				clear.append_array(range(cell, rightmostCell + 1))
				var mismatch: bool = false
				while scanRow < gridHeight:
					#scan down
					var start: int = leftCol + scanRow * gridWidth
					var end: int = rightCol + scanRow * gridWidth
					var done: bool = false
					if ((leftCol == 0 || board[start - 1] != board[start])
					&& (rightCol == gridWidth - 1 || board[end] != board[end + 1])):
						while start <= end:
							if board[start] != board[cell]:
								if start % gridWidth != leftCol:
									mismatch = true
								done = true
								break
							start += 1
						if !done:
							clear.append_array(range(leftCol + scanRow * gridWidth, end + 1))
							scanRow += 1
					else:
						break
					if done:
						break
				if clear.size() >= 6 && !mismatch && scanRow > row + 1:
					#check top and bottom row
					var disgrace: bool = false
					if row > 0:
						var start: int = leftCol + (row - 1) * gridWidth
						var end: int = rightCol + (row - 1) * gridWidth
						while start <= end:
							if board[start] == board[cell]:
								disgrace = true
								break
							start += 1
					if !disgrace && scanRow < gridHeight:
						var start: int = leftCol + scanRow * gridWidth
						var end: int = rightCol + scanRow * gridWidth
						while start <= end:
							if board[start] == board[cell]:
								disgrace = true
								break
							start += 1
					if !disgrace:
						emit_signal("clearStart")
						if !sfxMuted:
							clearSfx.stream = ClearSfxArray[randi_range(0, ClearSfxArray.size() - 1)]
							clearSfx.play()
						clearPieces(clear)
						return true
			cell = rightmostCell + 1
	return false

func clearPieces(cells: PackedInt32Array):
	var color: int = board[cells[0]]
	for i in cells:
		var twoDimensionalIndex: Vector2i = get2DIndex(i)
		$ClearEffect.set_cell(0, twoDimensionalIndex, 0, Vector2i(color, 0), 0)
		setCell(Globals.PieceColor.Empty, twoDimensionalIndex)

func checkVictory():
	for i in board.size():
		if board[i] != Globals.PieceColor.Empty:
			return
	emit_signal("victory")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !clearDelay.is_stopped():
		$ClearEffect.visible = ((clearDelay.time_left < 1.08 && clearDelay.time_left > 0.83)
		|| (clearDelay.time_left < 0.71 && clearDelay.time_left > 0.58)
		|| (clearDelay.time_left < 0.46 && clearDelay.time_left > 0.33)
		|| (clearDelay.time_left < 0.27 && clearDelay.time_left > 0.14)
		|| (clearDelay.time_left < 0.07))
