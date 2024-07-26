extends Button

@onready var websocket = $"../../../WebSocketClient"

func _on_pressed():
	var json_like_string = '{"CMD": "RESPAWN", "uid": "%s"}' % [Global.uid]
	websocket.send(json_like_string)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
