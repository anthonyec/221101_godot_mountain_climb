extends Spatial

export var move_left_action: String
export var move_right_action: String
export var move_forward_action: String
export var move_backward_action: String
export var jump_action: String
export var start_hosting_abseil_action: String

func _process(_delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
		move_left_action,
		move_right_action,
		move_forward_action,
		move_backward_action
	)

	get_parent().set_input_direction(input_direction)
	get_parent().set_jump(Input.is_action_just_pressed(jump_action))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(start_hosting_abseil_action):
		get_parent().start_hosting_abseil()
