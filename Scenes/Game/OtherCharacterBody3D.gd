extends CharacterBody3D

var uid : String = ""
@onready var animation = $AnimationPlayer
signal player_hit(uid: String, damage: int)  # Déclare le signal

func _ready():
	animation.play("Armature|Idle")

func hit(damage):
	emit_signal("player_hit", uid, damage)
