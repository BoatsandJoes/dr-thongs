extends CanvasLayer
class_name Lobby

var regex: RegEx

signal back

# Called when the node enters the scene tree for the first time.
func _ready():
	%Host.pressed.connect(_on_Host_pressed)
	%Join.pressed.connect(_on_Join_pressed)
	regex = RegEx.new()
	%IP.grab_focus.call_deferred()

func _on_Host_pressed():
	%HostJoin.visible = false

func _on_Join_pressed():
	if %IP.text != null:
		regex.compile("[1-2]?[0-9]?[0-9]\\.[1-2]?[0-9]?[0-9]\\.[1-2]?[0-9]?[0-9]\\.[1-2]?[0-9]?[0-9]")
		var result = regex.search(%IP.text)
		if result:
			var ip = result.get_string()
			%HostJoin.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("exit"):
		if %HostJoin.visible:
			emit_signal("back")
		else:
			%HostJoin.visible = true
	elif event.is_action_pressed("enter"):
		_on_Join_pressed()
