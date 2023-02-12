extends Node3D

func _physics_process(_resultsdelta: float) -> void:
	var results = Raycast.collide_cylinder(global_transform.origin)
	
	for result in results:
		DebugDraw.draw_cube(result, 0.05, Color.RED)
