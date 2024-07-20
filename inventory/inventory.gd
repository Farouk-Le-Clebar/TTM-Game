extends PanelContainer

# Préchargez la scène du slot
const Slot = preload("res://inventory/slot.tscn")
@onready var item_grid : GridContainer = $MarginContainer/ItemGrid 

func set_inventory_data(inventory_data : InventoryData) -> void:
	if not inventory_data.inventory_updated.is_connected(populate_item_grid):
		inventory_data.inventory_updated.connect(populate_item_grid)
	populate_item_grid(inventory_data)

func clear_inventory_data(inventory_data : InventoryData) -> void:
	inventory_data.inventory_updated.disconnect(populate_item_grid)

func populate_item_grid(inventory_data : InventoryData) -> void:
	# Libérez tous les enfants actuels de l'item_grid
	for child in item_grid.get_children():
		child.queue_free()
	
	# Ajoutez de nouveaux slots basés sur slot_datas
	for slot_data in inventory_data.slot_datas:
		var slot = Slot.instantiate()
		item_grid.add_child(slot)
		
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		
		if slot_data:
			slot.set_slot_data(slot_data)
			
	
func add_item_to_inventory_at_position(inventory_data: InventoryData, slot_data: SlotData, index: int) -> void:
	if inventory_data.add_item_to_inventory(slot_data, index):
		populate_item_grid(inventory_data)
	else:
		print("Impossible d'ajouter l'élément à la position donnée")
