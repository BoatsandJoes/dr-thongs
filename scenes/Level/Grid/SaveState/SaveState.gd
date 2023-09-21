extends Node2D
class_name SaveState

var board: PackedInt32Array
var timeElapsed: float
var cellIndexes: PackedInt32Array
var cellsColor: int
var playerId: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

static func of(board: Array[int], timeElapsed: float, cellIndexes: PackedInt32Array,
cellsColor: int, playerId: int) -> SaveState:
	var result: SaveState = SaveState.new()
	result.board = board
	result.timeElapsed = timeElapsed
	result.cellIndexes = cellIndexes
	result.cellsColor = cellsColor
	result.playerId = playerId
	return result

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
