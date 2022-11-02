extends Area

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("start_abseil"):
		body.start_abseil(global_transform.origin, global_rotation)
