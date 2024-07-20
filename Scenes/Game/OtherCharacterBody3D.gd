extends CharacterBody3D

var uid : String = ""
@onready var websocket = $"../WebSocketClient"
# @onready var animation = $AnimationPlayer
func _ready():
	pass

func hit(damage):
	var json_like_string = '{"CMD": "HIT", "uid": "%s", "damage": %d}' % [uid, damage]
	websocket.send(json_like_string)
