extends PlayerState

var rope: AbseilRope = null

func enter(params: Dictionary) -> void:
	Raycast.debug = true
	
	if params.get("rope"):
		# TODO: Is there a way to type this so sub-states get it? Maybe a class `AbseilState`?
		rope = params.get("rope") as AbseilRope
		rope.grab(player)
		
	player.set_collision_mode("abseil")
	
func exit() -> void:
	Raycast.debug = false
	
	rope.release()
	rope = null
	
	player.set_collision_mode("default")
