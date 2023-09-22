extends Node
class_name PieceSequence

var color_order: PackedInt32Array
var shape: int
var state: int

static func getRandom() -> Dictionary:
	var result = {"color_order": null, "shape": 0, "state": 0}
	result.shape = randi_range(0, 6)
	result.state = randi_range(0, 3)
	result.color_order = PackedInt32Array()
	var colors: Array = []
	for i in Globals.PieceColor.size():
		if i != Globals.PieceColor.Empty:
			colors.append(i)
	while colors.size() > 0:
		var index = randi_range(0, colors.size() - 1)
		result.color_order.append(colors.pop_at(index))
	return result
