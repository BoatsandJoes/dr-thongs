extends Node2D
class_name Grid

var board: PackedInt32Array
var gridHeight: int
var gridWidth: int
var cellSize: int
var clearDelay: Timer
var clearing: bool = false
var remainingColors: Array[int]
var sfxMuted: bool = false
var difficulty: int = 2
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
var tilemap

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $TileMap

func init():
	var trash
	var trash2
	if difficulty == 1:
		trash2 = $TileMap
		tilemap = $BigTileMap
		gridHeight = 7
		gridWidth = 7
		cellSize = 100
		%Thirteen.visible = false
		%gridSeven.visible = true
		trash = %Thirteen
	else:
		trash2 = $BigTileMap
		tilemap = tilemap
		gridHeight = 13
		gridWidth = 13
		cellSize = 50
		%Thirteen.visible = true
		%gridSeven.visible = false
		trash = %gridSeven
	remove_child(trash)
	remove_child(trash2)
	trash.queue_free()
	trash2.queue_free()
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
	var pieceMap: Dictionary = {
		Globals.PieceColor.Red: [],
		Globals.PieceColor.Green: [],
		Globals.PieceColor.Blue: [],
		Globals.PieceColor.Yellow: []
	}
	for i in board.size():
		var numColors = Globals.PieceColor.size() - 1
		if difficulty == 2:
			numColors -= 1
		var color: int = randi_range(0, numColors)
		if difficulty == 2:
			for iter in 3:
				if color != Globals.PieceColor.Empty:
					#reroll to maybe get empty instead.
					color = randi_range(0, numColors)
		if color != Globals.PieceColor.Empty:
			pieceMap[color].append(i)
			if !remainingColors.has(color):
				remainingColors.append(color)
	#debug cheater win
	#pieceMap[1].append(16)
	#remainingColors.append(1)
	for color in pieceMap.keys():
		setCells(color, pieceMap[color], {})

func _on_self_clearStart():
	clearing = true
	clearDelay.start()
	if !sfxMuted:
		clearSfx.stream = ClearSfxArray[randi_range(0, ClearSfxArray.size() - 1)]
		clearSfx.play()

func _on_clearDelay_timeout():
	tilemap.clear_layer(1)
	checkVictory()
	if !checkClears() && clearing == true:
		clearing = false
		emit_signal("clearsComplete")

func muteSfx():
	sfxMuted = true

func getRemainingColors() -> Array[int]:
	return remainingColors

func updateBoard(board: PackedInt32Array):
	tilemap.clear()
	board.fill(Globals.PieceColor.Empty)
	remainingColors.clear()
	var pieceMap: Dictionary = {
		Globals.PieceColor.Red: [],
		Globals.PieceColor.Green: [],
		Globals.PieceColor.Blue: [],
		Globals.PieceColor.Yellow: []
	}
	for i in board.size():
		var color = board[i]
		if color != Globals.PieceColor.Empty:
			pieceMap[color].append(i)
			if !remainingColors.has(color):
				remainingColors.append(color)
	for color in pieceMap.keys():
		setCells(color, pieceMap[color], {})

func setCells(color: int, cells: Array, neighbors: Dictionary):
	var coords: Array[Vector2i] = []
	for cell in cells:
		board[cell] = color #internal representation of the board.
		# now update visual representation of the board.
		coords.append(get2DIndex(cell))
	tilemap.set_cells_terrain_connect(0, coords, color - 1, 0)
	#update neighbor connections by erasing them and putting them back.
	for neighborColor in range(1, Globals.PieceColor.size()):
		if neighbors.has(neighborColor):
			for cell in neighbors[neighborColor]:
				tilemap.erase_cell(0,cell)
			tilemap.set_cells_terrain_connect(0, neighbors[neighborColor], neighborColor - 1, 0, 1)


func visuallyEraseCells(coordsArray: Array[int], color: int):
	#var top: int
	#var bot: int
	#var left: int
	#var right: int
	var clearCoords: Array[Vector2i] = []
	for i in coordsArray.size():
		var coords: Vector2i = get2DIndex(coordsArray[i])
		tilemap.erase_cell(0, coords)
		clearCoords.append(coords)
		#Assume coordinates are ordered left to right, top to bottom, and we're erasing more than 1 cell.
		#if i == 0:
		#	top = coords.y
		#	left = coords.x
		#elif i == coordsArray.size() - 1:
		#	right = coords.x
		#	bot = coords.y
	#Update connections in area around the clear.(THERE ARE NONE, SILLY)!
	#var borders: Array[Vector2i] = []
	#if top != 0:
	#	for i in range(left, right + 1):
	#		var border = Vector2i(i, top - 1)
	#		if board[getFlatIndex(border)] == color:
	#			borders.append(border)
	#if left != 0:
	#	for i in range(top, bot + 1):
	#		var border = Vector2i(Vector2i(left - 1, i))
	#		if board[getFlatIndex(border)] == color:
	#			borders.append(border)
	#if bot != gridHeight - 1:
	#	for i in range(left, right + 1):
	#		var border = Vector2i(Vector2i(i, bot + 1))
	#		if board[getFlatIndex(border)] == color:
	#			borders.append(border)
	#if right != gridWidth - 1:
	#	for i in range(top, bot + 1):
	#		var border = Vector2i(Vector2i(right + 1, i))
	#		if board[getFlatIndex(border)] == color:
	#			borders.append(border)
	#tilemap.set_cells_terrain_connect(0, borders, color - 1, 0)
	# Clear effect
	tilemap.set_cells_terrain_connect(1, clearCoords, color - 1, 0)

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
	var neighbors: Dictionary = {
				Globals.PieceColor.Red: [],
				Globals.PieceColor.Green: [],
				Globals.PieceColor.Blue: [],
				Globals.PieceColor.Yellow: []
			}
	for i in piece.size():
		if piece[i] == 2:
			var cellIndex: Vector2i = Vector2i(pieceXIndex + i % 5, pieceYIndex + i / 5)
			var flatIndex: int = getFlatIndex(cellIndex)
			if board[flatIndex] == playerPiece.color:
				if !sfxMuted:
					bonkSfx.stream = BonkSfxArray[randi_range(0, BonkSfxArray.size() - 1)]
					bonkSfx.play()
				return false
			cells.append(flatIndex)
		elif piece[i] == 1:
			#TODO update neighbors of different colors, because godot 4 won't
			var cellIndex: Vector2i = Vector2i(pieceXIndex + i % 5, pieceYIndex + i / 5)
			var flatIndex: int = getFlatIndex(cellIndex)
			var color
			if (cellIndex.x < gridWidth && cellIndex.x >= 0
			&& cellIndex.y < gridHeight && cellIndex.y >= 0):
				color = board[flatIndex]
				if color != Globals.PieceColor.Empty && color != playerPiece.color:
					neighbors[color].append(cellIndex)
	setCells(playerPiece.color, cells, neighbors)
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
		board[i] = Globals.PieceColor.Empty
	visuallyEraseCells(cells, color)

func checkVictory():
	for i in board.size():
		if board[i] != Globals.PieceColor.Empty:
			return
	emit_signal("victory")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !clearDelay.is_stopped():
		tilemap.set_layer_enabled(1, ((clearDelay.time_left < 1.08 && clearDelay.time_left > 0.83)
		|| (clearDelay.time_left < 0.71 && clearDelay.time_left > 0.58)
		|| (clearDelay.time_left < 0.46 && clearDelay.time_left > 0.33)
		|| (clearDelay.time_left < 0.27 && clearDelay.time_left > 0.14)
		|| (clearDelay.time_left < 0.07)))
