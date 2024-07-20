extends TextureButton

var multiplayer_peer = ENetMultiplayerPeer.new()

var connected_peer_ids = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	multiplayer_peer.create_server(4242, 2)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(
		func(new_peer_id):
			await get_tree().create_timer(1).timeout
			rpc("add_newly_connected_player_character", new_peer_id)
			rpc_id(new_peer_id, "add_previously_connected_player_characters", connected_peer_ids)
			add_player_character(new_peer_id)
	) 

func add_player_character(peer_id):
	connected_peer_ids.append(peer_id)
	var player_character = preload("res://Scenes/PlayerCharacter/player_character.tscn").instantiate()
	player_character.set_multiplayer_authority(peer_id)
	add_child(player_character)

@rpc	
func add_newly_connected_player_character(new_peer_id):
	add_player_character(new_peer_id)
	
@rpc
func add_previously_connected_player_characters(peer_ids):
	for peer_id in peer_ids:
		add_player_character(peer_id)
