extends CanvasLayer

@onready var music = $AudioStreamPlayer

func _ready():
	if not music.stream:
		music.stream = preload("res://assets/music/Silent_Echo.mp3")
	music.l
	music.play() 
