@tool
extends Control

@export var device: int = 0

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	Input.is_joy_button_pressed(device, JOY_BUTTON_A)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-20, -55, 60, 75), Color(0.1, 0.1, 0.1, 0.4))
	
	draw_button(Vector2.ZERO + Vector2.UP * 9, Input.is_joy_button_pressed(device, JOY_BUTTON_Y))
	draw_button(Vector2.ZERO + Vector2.DOWN * 9, Input.is_joy_button_pressed(device, JOY_BUTTON_A))
	draw_button(Vector2.ZERO + Vector2.LEFT * 9, Input.is_joy_button_pressed(device, JOY_BUTTON_X))
	draw_button(Vector2.ZERO + Vector2.RIGHT * 9, Input.is_joy_button_pressed(device, JOY_BUTTON_B))
	
	draw_bumper(Vector2.ZERO + Vector2.UP * 22, Input.is_joy_button_pressed(device, JOY_BUTTON_RIGHT_SHOULDER))
	
	draw_trigger(Vector2.ZERO + Vector2.UP * 42, Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT))
	
	draw_joystick(Vector2.ZERO - Vector2.LEFT * 25, Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y), Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_STICK))

func draw_button(position: Vector2, is_pressed: bool) -> void:
	var color = Color.RED if is_pressed else Color.WHITE
	draw_circle(position, 5, Color.BLACK)
	draw_circle(position, 4, color)

func draw_bumper(position: Vector2, is_pressed: bool) -> void:
	var color = Color.RED if is_pressed else Color.WHITE
	draw_rect(Rect2(position.x - 7, position.y - 7, 14, 10), Color.BLACK)
	draw_rect(Rect2(position.x - 6, position.y - 6, 12, 8), color)
	
func draw_trigger(position: Vector2, axis: float) -> void:	
	draw_rect(Rect2(position.x - 7, position.y - 7, 14, 16), Color.BLACK)
	draw_rect(Rect2(position.x - 6, position.y - 6, 12, 14), Color.WHITE)
	draw_rect(Rect2(position.x - 6, position.y - 6, 12, 14 * axis), Color.RED)

func draw_joystick(position: Vector2, axis_x: float, axis_y: float, is_pressed: bool) -> void:	
	var color = Color.RED if is_pressed else Color.WHITE	
	draw_circle(position, 7, Color.BLACK)
	draw_circle(position, 6, Color.GRAY)
	draw_circle(position, 5, Color.BLACK)
	draw_circle(position + Vector2(axis_x, axis_y) * 5, 5, Color.BLACK)
	draw_circle(position + Vector2(axis_x, axis_y) * 5, 4, color)
