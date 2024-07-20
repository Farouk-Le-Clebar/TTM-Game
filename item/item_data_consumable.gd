extends ItemData
class_name ItemDataConsumable

@export var heal_value : int
@export var feed : int
@export var thirsty : int

func use(target) -> void:
	if heal_value != 0:
		target.heal(heal_value)
