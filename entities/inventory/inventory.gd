class_name Inventory
extends Node

var items: Dictionary = {}

func add_item(item_name: String, amount: int = 1) -> void:
	if items.has(item_name):
		items[item_name] = items[item_name] + abs(amount)
	else:
		items[item_name] = amount

func use_item(item_name: String, amount: int = 1) -> void:
	if items.has(item_name):
		items[item_name] = items[item_name] - abs(amount)
	else:
		items[item_name] = amount
	
# Remove all instances of the item.
func remove_item(item_name: String) -> void:
	items.erase(item_name)

# Returns true if there is at least one item in the inventory.
func has_item(item_name: String) -> bool:
	return items.has(item_name) and items[item_name] > 0
 
func get_item_count(item_name: String) -> int:
	if items.has(item_name):
		return items[item_name]
	else:
		return 0
