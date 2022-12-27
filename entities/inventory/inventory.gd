class_name Inventory
extends Node

var items: Dictionary = {}

func add_item(item_name: String, amount: int = 1) -> void:
	if items.has(item_name):
		items[item_name] = items[item_name] + abs(amount)
	else:
		items[item_name] = amount

func remove_item(item_name: String, amount: int = 1) -> void:
	if items.has(item_name):
		items[item_name] = items[item_name] - abs(amount)
	else:
		items[item_name] = amount
	
func clear_item(item_name: String) -> void:
	items.erase(item_name)

func get_item_count(item_name: String) -> int:
	if items.has(item_name):
		return items[item_name]
	else:
		return 0
