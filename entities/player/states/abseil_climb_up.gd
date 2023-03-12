extends PlayerState

func enter(_params: Dictionary) -> void:
	Debug.notify("Enter sub state")
	
func exit() -> void:
	Debug.notify("Exit sub state")
