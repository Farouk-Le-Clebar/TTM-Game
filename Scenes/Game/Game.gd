extends Node3D

@onready var WebSocket = $WebSocketClient
@onready var MainPlayer = $CharacterBody3D
@onready var inventory_interface = $UI/InventoryInterface
@onready var DamageOverlay = $CharacterBody3D/CanvasLayer/DamageOverlay
@onready var DeadInterface = $UI/DeadInterface

const PickUp = preload("res://item/pickUp/pick_up.tscn")
var otherPlayers = {}

func _ready():
	MainPlayer.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(MainPlayer.inventory_data)
	inventory_interface.set_helmet_inventory_data(MainPlayer.helmet_inventory_data)
	inventory_interface.set_armor_inventory_data(MainPlayer.armor_inventory_data)
	inventory_interface.set_ears_inventory_data(MainPlayer.ears_inventory_data)
	inventory_interface.set_eyes_inventory_data(MainPlayer.eyes_inventory_data)
	inventory_interface.set_primary_weapon_inventory_data(MainPlayer.primary_weapon_inventory_data)
	inventory_interface.set_secondary_weapon_inventory_data(MainPlayer.secondary_weapon_inventory_data)
	var json_like_string = '{"CMD": "NP", "uid": "%s"}' % [Global.uid]
	WebSocket.send(json_like_string)
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_inventory_interface(external_inventory_owner = null) -> void:
	inventory_interface.visible = not inventory_interface.visible
	
	if inventory_interface.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()

func _on_web_socket_client_message_received(message):
	var json_obj = JSON.parse_string(message)
	if json_obj.has("state"):
		return
	var cmd = json_obj["CMD"]

	if cmd == "GP":
		var posX = str(json_obj["posX"]).to_float()
		var posY = str(json_obj["posY"]).to_float()
		var posZ = str(json_obj["posZ"]).to_float()
		MainPlayer.set_position_player(posX, posY, posZ)

	if cmd == "PP":
		var uid = json_obj["uid"]
		var posX = json_obj["posX"]
		var posY = json_obj["posY"]
		var posZ = json_obj["posZ"]
		var rotY = json_obj["rotY"]
		if otherPlayers == {}:
			return
		update_other_player_position(uid, posX, posY, posZ, rotY)

	if cmd == "NP":
		var uid = json_obj["uid"]
		var posX = str(json_obj["posX"]).to_float()
		var posY = str(json_obj["posY"]).to_float()
		var posZ = str(json_obj["posZ"]).to_float()
		var rotY = str(json_obj["rotY"]).to_float()
		_create_other_player(uid, posX, posY, posZ, rotY)

	if cmd == "ROT":
		var uid = json_obj["uid"]
		var rotY = str(json_obj["rotY"]).to_float()
		_rotate_other_player(uid, rotY)

	if cmd == "HIT":
		var life = json_obj["life"]
		_hit_player(life)
		
	if cmd == "GI":
		var pocket = json_obj["pocket"]
		var weapon = json_obj["weapon"]
		var helmet = json_obj["helmet"]
		var armor = json_obj["armor"]
		var eyes = json_obj["eyes"]
		var ears = json_obj["ears"]
		_load_inventory(pocket, weapon, helmet, armor, eyes, ears)

	if cmd == "RESPAWN":
		print("respawn")
		var life = str(json_obj["life"]).to_int()
		var posX = str(json_obj["posX"]).to_float()
		var posY = str(json_obj["posY"]).to_float()
		var posZ = str(json_obj["posZ"]).to_float()
		_respawn_player(life, posX, posY, posZ)

func _on_web_socket_client_connected_to_server():
		var json_like_string = '{"CMD": "DP", "uid": "%s"}' % [Global.uid]
		WebSocket.send(json_like_string)

func _on_web_socket_client_connection_closed():
	var ws = WebSocket.get_socket()
	print("Client disconnected with code %s, reason: %s" % [ws.get_close_code(), ws.get_close_reason()]) 

func _create_other_player(uid: String, posX: float, posY: float, posZ: float, rotY: float):
	print("Creating other player with UID: %s" % uid)
	
	# Vérifiez si un joueur avec cet UID existe déjà
	if otherPlayers.has(uid):
		print("Player with UID %s already exists." % uid)
		return

	# Charger la scène
	var otherPlayerScene = load("res://Scenes/Game/other_players.tscn")
	if otherPlayerScene == null:
		print("Failed to load other_players.tscn")
		return

	# Instancier la scène
	var otherPlayerInstance = otherPlayerScene.instantiate()
	if otherPlayerInstance == null:
		print("Failed to instantiate other player scene.")
		return
	
	# Ajouter l'instance à la scène
	var otherPlayersNode = $OtherPlayers
	if otherPlayersNode == null:
		print("$OtherPlayers node not found.")
		return

	otherPlayerInstance.scale = Vector3(0.35, 0.35, 0.35)

	otherPlayersNode.add_child(otherPlayerInstance)
	
	# Obtenez le corps du joueur et définissez les propriétés
	var playerBody = otherPlayerInstance.get_node("CharacterBody3D")
	if playerBody == null:
		print("CharacterBody3D node not found in other player instance.")
		return

	playerBody.uid = uid
	playerBody.global_transform.origin = Vector3(posX, posY, posZ)
	playerBody.global_transform.basis = Basis(Vector3(0, 1, 0), rotY)
	
	playerBody.player_hit.connect(_on_player_hit)

	# Ajouter à la liste des autres joueurs
	otherPlayers[uid] = otherPlayerInstance
	print("Other player created and added with UID: %s" % uid)

func _on_player_hit(uid: String, damage: int):
	var json_like_string = '{"CMD": "HIT", "uid": "%s", "damage": "%d"}' % [uid, damage]
	WebSocket.send(json_like_string)

func update_other_player_position(uid: String, posX: float, posY: float, posZ: float, rotY: float):
	if otherPlayers.has(uid):
		var playerInstance = otherPlayers[uid]
		var playerBody = playerInstance.get_node("CharacterBody3D")
		playerBody.global_transform.origin = Vector3(posX, posY, posZ)
		var transform = playerBody.global_transform
		transform.basis = Basis(Vector3(0, 1, 0), rotY)
		playerBody.global_transform = transform
		var animation_player = playerBody.get_node("AnimationPlayer")
		animation_player.play("Armature|Walk")
	else:
		print("Player with UID", uid, "not found.")

func _rotate_other_player(uid: String, rotY: float):
	if otherPlayers.has(uid):
		var playerInstance = otherPlayers[uid]
		var playerBody = playerInstance.get_node("CharacterBody3D")
		var transform = playerBody.global_transform
		transform.basis = Basis(Vector3(0, 1, 0), rotY)
		playerBody.global_transform = transform
	else:
		print("Player with UID", uid, "not found.")

func _hit_player(life : int):
	if life == 0:
		DamageOverlay.material.set_shader_parameter("EffectStrength", 0);
		Global.isDead = true
		DeadInterface.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif life <= 25:
		DamageOverlay.material.set_shader_parameter("EffectStrength", 1);
	elif life <= 50:
		DamageOverlay.material.set_shader_parameter("EffectStrength", 0.75);
	elif life <= 75:
		DamageOverlay.material.set_shader_parameter("EffectStrength", 0.5);
	else:
		DamageOverlay.material.set_shader_parameter("EffectStrength", 0);
	Global.life = life

func _on_inventory_interface_drop_slot_data(slot_data):
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = MainPlayer.get_drop_position()

func _load_inventory(pocket, weapon, helmet, armor, eyes, ears):
	var item_data
	var index = 0
	
	for item in pocket:
		if item[0] != "":
			item_data = loadItem(item[0], item[2], item[1])
			MainPlayer.inventory_data.add_item_to_inventory(item_data, index)
		else:
			MainPlayer.inventory_data.remove_item_to_inventory(index)
		index += 1
	index = 0
	for item in weapon:
		if item[0] != "":
			item_data = loadItem(item[0], item[2], item[1])
			MainPlayer.primary_weapon_inventory_data.add_item_to_inventory(item_data, index)
		else:
			MainPlayer.inventory_data.remove_item_to_inventory(index)
		index += 1
	index = 0
	for item in helmet:
		if item[0] != "":
			item_data = loadItem(item[0], item[2], item[1])
			MainPlayer.helmet_inventory_data.add_item_to_inventory(item_data, index)
		else:
			MainPlayer.inventory_data.remove_item_to_inventory(index)
		index += 1
	index = 0
	for item in armor:
		if item[0] != "":
			item_data = loadItem(item[0], item[2], item[1])
			MainPlayer.armor_inventory_data.add_item_to_inventory(item_data, index)
		else:
			MainPlayer.inventory_data.remove_item_to_inventory(index)
		index += 1
	index = 0
	for item in eyes:
		if item[0] != "":
			item_data = loadItem(item[0], item[2], item[1])
			MainPlayer.eyes_inventory_data.add_item_to_inventory(item_data, index)
		else:
			MainPlayer.inventory_data.remove_item_to_inventory(index)
		index += 1
	index = 0
	for item in ears:
		if item[0] != "":
			item_data = loadItem(item[0], item[2], item[1])
			MainPlayer.ears_inventory_data.add_item_to_inventory(item_data, index)
		else:
			MainPlayer.inventory_data.remove_item_to_inventory(index)
		index += 1
	index = 0

	inventory_interface.set_player_inventory_data(MainPlayer.inventory_data)
	inventory_interface.set_primary_weapon_inventory_data(MainPlayer.primary_weapon_inventory_data)
	inventory_interface.set_helmet_inventory_data(MainPlayer.helmet_inventory_data)
	inventory_interface.set_armor_inventory_data(MainPlayer.armor_inventory_data)
	inventory_interface.set_eyes_inventory_data(MainPlayer.eyes_inventory_data)
	inventory_interface.set_ears_inventory_data(MainPlayer.ears_inventory_data)

func loadItem(itemName : String, itemType : String, quantity : int):
	var item_path = "res://item/items/" + itemName + ".tres"
	print("itemPath")
	print(item_path)
	var slot_data = SlotData.new()
	if itemType == "data":
		slot_data.item_data = load(item_path) as ItemData
	if itemType == "consumable":
		slot_data.item_data = load(item_path) as ItemDataConsumable
	if itemType == "weapon":
		slot_data.item_data = load(item_path) as ItemDataWeapon
	if itemType == "helmet":
		slot_data.item_data = load(item_path) as ItemDataHelmet
	if itemType == "armor":
		slot_data.item_data = load(item_path) as ItemDataArmor
	if itemType == "eyes":
		slot_data.item_data = load(item_path) as ItemDataEyes
	if itemType == "ears":
		slot_data.item_data = load(item_path) as ItemDataEars
		
	return slot_data
		
func _respawn_player(life, posX, posY, posZ):
	MainPlayer.set_position_player(posX, posY, posZ)
	Global.life = 100
	Global.isDead = false
	DeadInterface.hide()
	print(posX)
	print(posY)
	print(posZ)
	
