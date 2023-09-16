extends Node2D
class_name Piece

var monominoRotations: Array = [[
	false,false,false,
	false,true,false,
	false,false,false
], [
	false,false,false,
	false,true,false,
	false,false,false
], [
	false,false,false,
	false,true,false,
	false,false,false
], [
	false,false,false,
	false,true,false,
	false,false,false
]];
var dominoRotations: Array = [[
	false,false,false,
	false,true,true,
	false,false,false
], [
	false,false,false,
	false,false,true,
	false,false,true
], [
	false,false,false,
	false,false,false,
	false,true,true
], [
	false,false,false,
	false,true,false,
	false,true,false
]];
var tRotations: Array = [[
	false,false,false,
	false,true,true,
	false,true,false
], [
	false,false,false,
	false,true,true,
	false,false,true
], [
	false,false,false,
	false,false,true,
	false,true,true
], [
	false,false,false,
	false,true,false,
	false,true,true
]];
var iRotations: Array = [[
	false,false,false,
	true,true,true,
	false,false,false
], [
	false,true,false,
	false,true,false,
	false,true,false
], [
	false,false,false,
	true,true,true,
	false,false,false
], [
	false,true,false,
	false,true,false,
	false,true,false
]];
var jRotations: Array = [[
	false,false,false,
	true,true,true,
	false,false,true
], [
	false,true,false,
	false,true,false,
	true,true,false
], [
	true,false,false,
	true,true,true,
	false,false,false
], [
	false,true,true,
	false,true,false,
	false,true,false
]];
var lRotations: Array = [[
	false,false,true,
	true,true,true,
	false,false,false
], [
	false,true,false,
	false,true,false,
	false,true,true
], [
	false,false,false,
	true,true,true,
	true,false,false
], [
	true,true,false,
	false,true,false,
	false,true,false
]];
var smashboyRotations: Array = [[
	false,false,false,
	false,true,true,
	false,true,true
], [
	false,false,false,
	false,true,true,
	false,true,true
], [
	false,false,false,
	false,true,true,
	false,true,true
], [
	false,false,false,
	false,true,true,
	false,true,true
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
	for i in 9:
		if self.shape[state][i]:
			$TileMap.set_cell(0, Vector2i(i % 3, i / 3), 0, Vector2i(color, 0), 0)

func getCurrentShape() -> Array:
	return shape[state]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
