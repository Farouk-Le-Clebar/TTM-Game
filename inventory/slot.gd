extends PanelContainer

signal slot_clicked(index : int, button : int)

@onready var texture_rect : TextureRect = $MarginContainer/TextureRect
@onready var qunatity_label : Label = $QuantityLabel

func set_slot_data(slot_data : SlotData) -> void:
	var item_data = slot_data.item_data
	texture_rect.texture = item_data.texture
	tooltip_text = "%s\n%s\n%s" % [item_data.name, item_data.description, item_data.rarity]
	
	if slot_data.quantity > 1:
		qunatity_label.text = "x%s" % slot_data.quantity
		qunatity_label.show()
	else:
		qunatity_label.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton \
			and (event.button_index == MOUSE_BUTTON_LEFT \
			or event.button_index == MOUSE_BUTTON_RIGHT) \
			and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)

func change_texture_scale(size : float) -> void:
	texture_rect.scale = Vector2(size, size)
