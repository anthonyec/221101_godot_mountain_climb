extends Area3D

func _process(_delta: float) -> void:
	pass

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("end_abseil"):
		body.end_abseil(global_transform.origin + (global_transform.basis.z * 0.5))
