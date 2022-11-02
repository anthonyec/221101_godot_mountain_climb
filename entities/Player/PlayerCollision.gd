extends Area

func _on_area_shape_entered(area_rid: RID, area: Area, area_shape_index: int, local_shape_index: int) -> void:
	print("WOW")


func _on_area_entered(area: Area) -> void:
	print("OMG")


func _on_body_entered(body: Node) -> void:
	print("_on_body_entered", body)
