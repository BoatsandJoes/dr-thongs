extends CanvasLayer
class_name Lobby

var regex: RegEx
var port: String
var ip: String
var hosting = false
var GameManager = preload("res://scenes/Managers/GameManager/GameManager.tscn")
var gameManager: GameManager

signal back
signal start(gameManager)
# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

# This will contain player info for every player, with the keys being each player's unique IDs.
var players = {}
# This is the local player info. This should be modified locally before the connection is made.
# It will be passed to every other peer.
var player_info = {"name": "Host"}
var players_loaded = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	%Host.pressed.connect(_on_Host_pressed)
	%Join.pressed.connect(_on_Join_pressed)
	%Start.pressed.connect(_on_Start_pressed)
	%BackToText.pressed.connect(_on_BackToText_pressed)
	%Exit.pressed.connect(_on_Exit_pressed)
	regex = RegEx.new()
	%IP.grab_focus.call_deferred()
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_server_disconnected():
	%ConnectStatus.text = "Host disconnected"
	multiplayer.multiplayer_peer = null
	server_disconnected.emit()

func _on_connected_fail():
	%ConnectStatus.text = "Connection failed"
	multiplayer.multiplayer_peer = null

func _on_connected_ok():
	%ConnectStatus.text = "Connected! Waiting for start..."
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	_register_player.rpc_id(id, player_info)
	%ConnectStatus.text = "Connected"
	%Start.disabled = false

func _on_player_disconnected(id):
	player_info.erase(id)
	player_disconnected.emit(id)
	%ConnectStatus.text = "Waiting for connection..."
	%Start.disabled = true

func _on_Exit_pressed():
	emit_signal("back")

func _on_BackToText_pressed():
	closeLobby()

func join_game(ip: String, port: String):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, int(port))
	if error:
		return error
	multiplayer.multiplayer_peer = peer

func create_game(port: String):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(int(port), 1)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	players[1] = player_info
	player_connected.emit(1, player_info)

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null

# When the server decides to start the game from a UI scene, do Lobby.load_game.rpc(params)
@rpc("call_local", "reliable")
func load_game(mode: int):
	gameManager = GameManager.instantiate()
	emit_signal("start", gameManager)

func _on_Start_pressed():
	load_game.rpc(0) #If there's a game mode, can pass it here

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
	%PortText.text = port
	%ConnectStatus.text = "Waiting for connection..."
	%Start.disabled = true
	%Lobby.visible = true
	if hosting:
		%Start.visible = true
		%Mode.text = "Hosting"
		%IPInfo.visible = false
		player_info["name"] = "Host"
		create_game(port)
	else:
		%Start.visible = false
		%Mode.text = "Joining"
		%IPText.text = ip
		%IPInfo.visible = true
		player_info["name"] = "Client"
		join_game(ip, port)

func closeLobby():
	%Lobby.visible = false
	%HostJoin.visible = true
	remove_multiplayer_peer()

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
		if %HostJoin.visible:
			if %Port.text != null && %Port.text != "":
				_on_Host_pressed()
			elif %IP.text != null && %IP.text != "":
				_on_Join_pressed()
