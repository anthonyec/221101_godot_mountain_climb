extends PlayerState

var rope: RaycastRope = null

func enter(params: Dictionary) -> void:
	if params.get("rope"):
		# TODO: Is there a way to type this so sub-states get it? Maybe a class `AbseilState`?
		rope = params.get("rope") as RaycastRope
		rope.target = player
		
	player.set_collision_mode("abseil")
	
func exit() -> void:
	# TODO: Change RaycastRope to AbseilRope to replace this with a reset method.
	rope.target = rope.get_parent().get_node("RopeEnd")
	rope = null
	
	player.set_collision_mode("default")
