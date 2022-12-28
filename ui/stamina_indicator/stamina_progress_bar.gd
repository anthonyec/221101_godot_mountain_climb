extends ProgressBar

func _process(_delta: float) -> void:
	queue_redraw()
	
func _draw() -> void:
	var percent = value / max_value
	
	draw_rect(Rect2(0, 0, size.x, size.y), Color.BLACK)
	draw_rect(Rect2(1, 1, (size.x - 2) * percent, size.y - 2), Color.GREEN)
