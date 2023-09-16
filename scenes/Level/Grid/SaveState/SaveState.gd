extends Node2D
class_name SaveState

var board: PackedInt32Array
var time_elapsed: float
var queues: Array
var timeElapsed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

static func of(board: Array[int], timeElapsed: float, queues: Array) -> SaveState:
	var result: SaveState = SaveState.new()
	result.board = board
	result.time_elapsed = timeElapsed
	result.queues = queues
	return result

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
