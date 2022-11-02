extends Position3D

func _process(delta: float) -> void:
	var player_1 = get_parent().get_node("Player1")
	var player_2 = get_parent().get_node("Player2")
	var target_position = player_1.global_transform.origin + (player_2.global_transform.origin - player_1.global_transform.origin) * 0.5
	
	global_transform.origin = target_position
