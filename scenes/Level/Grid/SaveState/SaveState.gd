extends Node2D
class_name SaveState

var board: PackedInt32Array
var timeElapsed: float
var cellIndexes: PackedInt32Array
var cellsColor: int
var playerId: int
var clears: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

static func of(board: Array[int], timeElapsed: float, cellIndexes: PackedInt32Array,
cellsColor: int, playerId: int, clears: Array) -> SaveState:
	var result: SaveState = SaveState.new()
	result.board = board
	result.timeElapsed = timeElapsed
	result.cellIndexes = cellIndexes
	result.cellsColor = cellsColor
	result.playerId = playerId
	result.clears = clears
	return result

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
