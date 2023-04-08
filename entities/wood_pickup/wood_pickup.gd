extends Area3D

func pick_up(inventory: Inventory):
	inventory.add_item("wood")
	queue_free()
