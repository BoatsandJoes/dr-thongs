extends Node2D
class_name Piece

var monominoRotations: Array = [[
	0,0,0,0,0,
	0,0,1,0,0,
	0,1,2,1,0,
	0,0,1,0,0,
	0,0,0,0,0
], [
	0,0,0,0,0,
	0,0,1,0,0,
	0,1,2,1,0,
	0,0,1,0,0,
	0,0,0,0,0
], [
	0,0,0,0,0,
	0,0,1,0,0,
	0,1,2,1,0,
	0,0,1,0,0,
	0,0,0,0,0
], [
	0,0,0,0,0,
	0,0,1,0,0,
	0,1,2,1,0,
	0,0,1,0,0,
	0,0,0,0,0
]];
var dominoRotations: Array = [[
	0,0,0,0,0,
	0,0,1,1,0,
	0,1,2,2,1,
	0,0,1,1,0
], [
	0,0,0,0,0,
	0,0,0,1,0,
	0,0,1,2,1,
	0,0,1,2,1,
	0,0,0,1,0
], [
	0,0,0,0,0,
	0,0,0,0,0,
	0,0,1,1,0,
	0,1,2,2,1,
	0,0,1,1,0
], [
	0,0,0,0,0,
	0,0,1,0,0,
	0,1,2,1,0,
	0,1,2,1,0,
	0,0,1,0,0
]];
var tRotations: Array = [[
	0,0,0,0,0,
	0,0,1,1,0,
	0,1,2,2,1,
	0,1,2,1,0,
	0,0,1,0,0
], [
	0,0,0,0,0,
	0,0,1,1,0,
	0,1,2,2,1,
	0,0,1,2,1,
	0,0,0,1,0
], [
	0,0,0,0,0,
	0,0,0,1,0,
	0,0,1,2,1,
	0,1,2,2,1,
	0,0,1,1,0
], [
	0,0,0,0,0,
	0,0,1,0,0,
	0,1,2,1,0,
	0,1,2,2,1,
	0,0,1,1,0
]];
var iRotations: Array = [[
	0,0,0,0,0,
	0,1,1,1,0,
	1,2,2,2,1,
	0,1,1,1,0,
	0,0,0,0,0
], [
	0,0,1,0,0,
	0,1,2,1,0,
	0,1,2,1,0,
	0,1,2,1,0,
	0,0,1,0,0
], [
	0,0,0,0,0,
	0,1,1,1,0,
	1,2,2,2,1,
	0,1,1,1,0,
	0,0,0,0,0,
], [
	0,0,1,0,0,
	0,1,2,1,0,
	0,1,2,1,0,
	0,1,2,1,0,
	0,0,1,0,0
]];
var jRotations: Array = [[
	0,0,0,0,0,
	0,1,1,1,0,
	1,2,2,2,1,
	0,1,1,2,1,
	0,0,0,1,0
], [
	0,0,1,0,0,
	0,1,2,1,0,
	0,1,2,1,0,
	1,2,2,1,0,
	0,1,1,0,0,
], [
	0,1,0,0,0,
	1,2,1,1,0,
	1,2,2,2,1,
	0,1,1,1,0,
	0,0,0,0,0
], [
	0,0,1,1,0,
	0,1,2,2,1,
	0,1,2,1,0,
	0,1,2,1,0,
	0,0,1,0,0
]];
var lRotations: Array = [[
	0,0,0,1,0,
	0,1,1,2,1,
	1,2,2,2,1,
	0,1,1,1,0,
	0,0,0,0,0
], [
	0,0,1,0,0,
	0,1,2,1,0,
	0,1,2,1,0,
	0,1,2,2,1,
	0,0,1,1,0
], [
	0,0,0,0,0,
	0,1,1,1,0,
	1,2,2,2,1,
	1,2,1,1,0,
	0,1,0,0,0
], [
	0,1,1,0,0,
	1,2,2,1,0,
	0,1,2,1,0,
	0,1,2,1,0,
	0,0,1,0,0
]];
var smashboyRotations: Array = [[
	0,0,0,0,0,
	0,0,1,1,0,
	0,1,2,2,1,
	0,1,2,2,1,
	0,0,1,1,0
], [
	0,0,0,0,0,
	0,0,1,1,0,
	0,1,2,2,1,
	0,1,2,2,1,
	0,0,1,1,0
], [
	0,0,0,0,0,
	0,0,1,1,0,
	0,1,2,2,1,
	0,1,2,2,1,
	0,0,1,1,0
], [
	0,0,0,0,0,
	0,0,1,1,0,
	0,1,2,2,1,
	0,1,2,2,1,
	0,0,1,1,0
]];
var color: int
var shapes = [self.monominoRotations, self.dominoRotations, self.tRotations, self.iRotations,
self.jRotations, self.lRotations, self.smashboyRotations]
var shape: Array
var state: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func setShape(shape: Array, state: int, color: int):
	self.shape = shape
	self.state = state
	self.color = color
	updateTilemap()

func setPiece(piece: Piece):
	self.shape = piece.shape
	self.state = piece.state
	self.color = piece.color
	updateTilemap()

func setRandomShape(colors: Array[int]):
	if colors.size() > 0:
		setShape(shapes[randi_range(0, shapes.size() - 1)], randi_range(0, 3),
		colors[randi_range(0, colors.size() - 1)])

func predictSpin(direction: int) -> Array:
	return shape[(state + direction) % 4]

func spin(direction: int):
	state = (state + direction) % 4
	updateTilemap()

func updateTilemap():
	$TileMap.clear()
	for i in self.shape[state].size():
		if self.shape[state][i] == 2:
			$TileMap.set_cell(0, Vector2i(i % 5, i / 5), 0, Vector2i(color, 0), 0)

func getCurrentShape() -> Array:
	return shape[state]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
