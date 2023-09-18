extends CanvasLayer
class_name Lobby

var regex: RegEx
var port: String
var ip: String
var hosting = false

signal back

# Called when the node enters the scene tree for the first time.
func _ready():
	%Host.pressed.connect(_on_Host_pressed)
	%Join.pressed.connect(_on_Join_pressed)
	regex = RegEx.new()
	%IP.grab_focus.call_deferred()

func _on_Host_pressed():
	if %Port.text != null:
		regex.compile("[0-9]?[0-9]?[0-9]?[0-9][0-9]")
		var result = regex.search(%Port.text)
		if result:
			port = result.get_string()
			hosting = true
			openLobby()

func _on_Join_pressed():
	if %IP.text != null:
		regex.compile("[1-2]?[0-9]?[0-9]\\.[1-2]?[0-9]?[0-9]\\.[1-2]?[0-9]?[0-9]\\.[1-2]?[0-9]?[0-9]")
		var result = regex.search(%IP.text)
		if result:
			regex.compile(":[0-9]?[0-9]?[0-9]?[0-9][0-9]")
			var result2 = regex.search(%IP.text)
			if result2:
				ip = result.get_string()
				port = result2.get_string().substr(1)
				hosting = false
				openLobby()

func openLobby():
	%HostJoin.visible = false
	%Lobby.visible = true

func closeLobby():
	%Lobby.visible = false
	%HostJoin.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("exit"):
		if %HostJoin.visible:
			emit_signal("back")
		else:
			closeLobby()
	elif event.is_action_pressed("enter"):
		_on_Join_pressed()
