extends CharacterBody3D

var uid : String = ""
@onready var animation = $AnimationPlayer
signal player_hit(uid: String, damage: int)  # Déclare le signal

func _ready():
	pass

func hit(damage):
	emit_signal("player_hit", uid, damage)
