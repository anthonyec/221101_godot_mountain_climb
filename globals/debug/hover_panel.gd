class_name HoverPanel extends Panel

@export var vector: Vector3

func _process(_delta: float) -> void:
	queue_redraw()
	
func _draw() -> void:
	var center = size / 2
	var target = Vector2(vector.x, vector.z).normalized() * 30
	
	draw_line(center, center + target, Color.WHITE)
