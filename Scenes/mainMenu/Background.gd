extends Node3D

@onready var OtherPlayer = $OtherPlayers
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	var OtherPlayerAnimation = OtherPlayer.get_node("CharacterBody3D/AnimationPlayer")
	OtherPlayerAnimation.play("Armature|Idle")
