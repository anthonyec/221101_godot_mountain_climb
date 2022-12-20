@tool
extends Control

@onready @export var player: Player
@export var percent: float = 0

func _process(delta: float) -> void:
	queue_redraw()
	
	var camera = get_viewport().get_camera_3d()
	
	if !camera or !player:
		return
		
	percent = player.balance.percent
	
	var screen_position = camera.unproject_position(player.global_transform.origin + player.global_transform.basis.y)
	position = screen_position - (size / 2)
	
	modulate = Color(1, 1, 1, 1) if  player.state == "balancing" else Color(1, 1, 1, 0)
	
func _draw() -> void:
	var half_width = size.x / 2
	
	draw_rect(Rect2(0, 0, size.x, size.y), Color.BLACK)
	draw_rect(Rect2(half_width, 1, 2, size.y - 2), Color.BLUE)
	draw_rect(Rect2(half_width + (half_width * percent), 1, 2, size.y - 2), Color.ORANGE)
