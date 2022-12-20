extends Control

@onready var balance: Balance = $Balance

func _process(delta: float) -> void:
	var horizontal_axis = Input.get_action_strength("move_right_2") - Input.get_action_strength("move_left_2")
	
	balance.lean(horizontal_axis * 2)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 100, 20), Color.BLACK)
	draw_rect(Rect2(50 + (50 * balance.percent), 0, 1, 20), Color.ORANGE)
	pass
