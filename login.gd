extends TextureButton

var websocket_url = "ws://localhost:8765"
var messageToSend = ""
@onready var email : TextEdit = get_parent().get_node("email")
@onready var password : TextEdit = get_parent().get_node("password")
@onready var WebSocket = $WebSocketClient
@onready var circleState : Sprite2D = get_parent().get_node("serverState").get_node("circleState")
@onready var labelState : Label = get_parent().get_node("serverState").get_node("LabelState")
@onready var textureServerOn = preload("res://assets/loginMenu/serverOnline.png")
@onready var textureServerOff = preload("res://assets/loginMenu/serverOffline.png")

func _connect_to_game():
	var error = WebSocket.connect_to_url(websocket_url)
	
	if error != OK:
		print("ERROR: connection to websocket: %s" % [websocket_url])
		if labelState.text != "Server ON":
			labelState.text = "Server ON"
			circleState.texture = textureServerOn
		return
	
	if labelState.text != "Server ON":
		labelState.text = "Server ON"
		circleState.texture = textureServerOn
	

func _ready():
	print("Attempting to connect to server ...")
	_connect_to_game()


func _on_web_socket_client_message_received(message):
	print("Message received: %s" % message)
	var json_obj = JSON.parse_string(message)
	var cmd = json_obj["state"]

	if cmd == "OK":
		var uid = json_obj["uid"]
	
		Global.uid = uid
		Global.email = email.text
		Global.password = password.text
		print("UID extracted: %s" % Global.uid)
		get_tree().change_scene_to_file("res://Scenes/mainMenu/menu.tscn")
	else:
		print("No UID found in the message")

func _on_web_socket_client_connected_to_server():
	print("Client connected...")

func _on_web_socket_client_connection_closed():
	var ws = WebSocket.get_socket()
	print("Client disconnected with code %s, reason: %s" % [ws.get_close_code(), ws.get_close_reason()]) 

func _on_pressed():
	if email.text != "" and password.text != "":	
		var json_like_string = '{"CMD": "AUTH", "email": "%s", "password": "%s"}' % [email.text, password.text]
		WebSocket.send(json_like_string)
		
