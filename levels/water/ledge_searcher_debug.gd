extends Node3D

var done: bool = false

func _process(_delta: float) -> void:
	if done:
		return
		
	var ledge: LedgeSearcher = $LedgeSearcher as LedgeSearcher 
	var ledge_info = ledge.get_ledge_info(global_transform.origin, -global_transform.basis.z)
	
	ledge.find_and_build_path(ledge_info, LedgeSearcher.Direction.RIGHT)
	ledge.find_and_build_path(ledge_info, LedgeSearcher.Direction.LEFT)
	
	done = true
