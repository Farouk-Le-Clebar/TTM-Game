extends Control

signal drop_slot_data(slot_data : SlotData)

@onready var player_inventory : PanelContainer = $PlayerInventory
@onready var external_inventory : PanelContainer = $ExternalInventory
@onready var grabbed_slot : PanelContainer = $GrabbedSlot

@onready var helmet_inventory : PanelContainer = $HelmetInventory
@onready var eyes_inventory : PanelContainer = $EyesInventory
@onready var armor_inventory : PanelContainer = $ArmorInventory
@onready var ears_inventory : PanelContainer = $EarsInventory

@onready var primary_weapon_inventory : PanelContainer = $PrimaryWeaponInventory
@onready var secondary_weapon_inventory : PanelContainer = $SecondaryWeaponInventory

@onready var scope_inventory : PanelContainer = $ScopeInventory

@onready var webSocket = $"../../WebSocketClient"
 
var grabbed_slot_data : SlotData
var external_inventory_owner

func _physics_process(delta):
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5, 5)
		
func set_player_inventory_data(inventory_data : InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func set_helmet_inventory_data(inventory_data : InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	helmet_inventory.set_inventory_data(inventory_data)

func set_armor_inventory_data(inventory_data : InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	armor_inventory.set_inventory_data(inventory_data)

func set_eyes_inventory_data(inventory_data : InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	eyes_inventory.set_inventory_data(inventory_data)

func set_ears_inventory_data(inventory_data : InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	ears_inventory.set_inventory_data(inventory_data)

func set_primary_weapon_inventory_data(inventory_data : InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	primary_weapon_inventory.set_inventory_data(inventory_data)

func set_secondary_weapon_inventory_data(inventory_data : InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	secondary_weapon_inventory.set_inventory_data(inventory_data)

func set_scope_inventory_data(inventory_data : InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	scope_inventory.set_inventory_data(inventory_data)

func set_external_inventory(_external_inventory_owner) -> void:
	external_inventory_owner = _external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	external_inventory.set_inventory_data(inventory_data)
	
	external_inventory.show()

func clear_external_inventory() -> void:
	if external_inventory_owner:
		var inventory_data = external_inventory_owner.inventory_data
	
		inventory_data.inventory_interact.disconnect(on_inventory_interact)
		external_inventory.clear_inventory_data(inventory_data)
	
		external_inventory.hide()
		external_inventory_owner = null	

func on_inventory_interact(inventory_data : InventoryData, index : int, button: int) -> void:
	var json_like_string = ""
	match[grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			json_like_string = '{"CMD": "GRABITEM", "uid": "%s", "index": "%d"}' % [Global.uid, index]
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]:
			var type = ""
			type = findType()
			if grabbed_slot_data.item_data is ItemDataArmor or grabbed_slot_data.item_data is ItemDataHelmet:
				json_like_string = '{"CMD": "DROPITEM", "uid": "%s", "index": "%d", "id": "%s", "quantity": "%d", "type": "%s", "resistance": "%d"}' % [Global.uid, index, grabbed_slot_data.item_data.name, grabbed_slot_data.quantity, type, grabbed_slot_data.item_data.defense]
			else:
				json_like_string = '{"CMD": "DROPITEM", "uid": "%s", "index": "%d", "id": "%s", "quantity": "%d", "type": "%s"}' % [Global.uid, index, grabbed_slot_data.item_data.name, grabbed_slot_data.quantity, type]
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, MOUSE_BUTTON_RIGHT]:
			var selectedData = inventory_data.get_slot_data_at_index(index)
			if selectedData.item_data is ItemDataConsumable:
				inventory_data.use_slot_data(index)
				json_like_string = '{"CMD": "USEITEM", "uid": "%s", "index": "%d"}' % [Global.uid, index]
			if selectedData.item_data is ItemDataWeapon:
				json_like_string = '{"CMD": "USEWEAPON", "uid": "%s", "index": "%d"}' % [Global.uid, index]
		[_, MOUSE_BUTTON_RIGHT]:
			var type = ""
			type = findType()
			if grabbed_slot_data.item_data is ItemDataArmor or grabbed_slot_data.item_data is ItemDataHelmet:
				json_like_string = '{"CMD": "DROPITEM", "uid": "%s", "index": "%d", "id": "%s", "quantity": "1", "type": "%s", "resistance": "%d"}' % [Global.uid, index, grabbed_slot_data.item_data.name, type, grabbed_slot_data.item_data.defense]
			else:
				json_like_string = '{"CMD": "DROPITEM", "uid": "%s", "index": "%d", "id": "%s", "quantity": "1", "type": "%s"}' % [Global.uid, index, grabbed_slot_data.item_data.name, type]
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)

	json_like_string = json_like_string.rstrip('}')
	if inventory_data is InventoryDataWeapon:
			json_like_string += ', "inventory": "weapon"}'
	elif inventory_data is InventoryDataArmor:
			json_like_string += ', "inventory": "armor"}'
	elif inventory_data is InventoryDataHelmet:
			json_like_string += ', "inventory": "helmet"}'
	elif inventory_data is InventoryDataEars:
			json_like_string += ', "inventory": "ears"}'
	elif inventory_data is InventoryDataEyes:
			json_like_string += ', "inventory": "eyes"}'
	elif inventory_data is InventoryDataScope:
			json_like_string += ', "inventory": "scope"}'
	elif inventory_data is InventoryData:
			json_like_string += ', "inventory": "pocket"}'
	
	print(json_like_string)
	webSocket.send(json_like_string)
	update_grabbed_slot()

func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()


func _on_gui_input(event):
	if event is InputEventMouseButton \
			and event.is_pressed() \
			and grabbed_slot_data:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				drop_slot_data.emit(grabbed_slot_data)
				grabbed_slot_data = null
			MOUSE_BUTTON_RIGHT:
				drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
				if grabbed_slot_data.quantity < 1:
					grabbed_slot_data = null
		
		update_grabbed_slot()


func _on_visibility_changed():
	if not visible and grabbed_slot_data:
		drop_slot_data.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()

func findType() -> String:
	if grabbed_slot_data.item_data is ItemDataConsumable:
		return "consumable"
	if grabbed_slot_data.item_data is ItemDataWeapon:
		return "weapon"
	if grabbed_slot_data.item_data is ItemDataHelmet:
		return "helmet"
	if grabbed_slot_data.item_data is ItemDataArmor:
		return "armor"
	if grabbed_slot_data.item_data is ItemDataEars:
		return "ears"
	if grabbed_slot_data.item_data is ItemDataEyes:
		return "eyes"
	if grabbed_slot_data.item_data is ItemDataScope:
		return "scope"
	return "data"
		
