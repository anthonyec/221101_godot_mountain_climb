extends PlayerState

var position_on_ledge: float = 0

func awake() -> void:
	super.awake()

func enter(params: Dictionary) -> void:
	Raycast.debug = true
	player.ledge.debug = true
	
	player.animation.play("Hang-loop_RobotArmature")
	player.collision.disabled = true
	
	var ledge_info = params.get("ledge_info")
	assert(ledge_info, "Ledge info required for hang state to work")
	
	player.ledge.find_and_build_path(ledge_info, LedgeSearcher.Direction.RIGHT)
	player.ledge.find_and_build_path(ledge_info, LedgeSearcher.Direction.LEFT)
	assert(player.ledge.path, "Path should be found")

func exit() -> void:
	Raycast.debug = false
	position_on_ledge = 0
	player.collision.disabled = false
	player.ledge.reset()
	player.model.scale = Vector3(1, 1, 1)

func physics_update(delta: float) -> void:
	position_on_ledge += player.input_direction.x * delta
	position_on_ledge = clamp(position_on_ledge, player.ledge.min_length, player.ledge.max_length)
	
	var hang_position = player.ledge.get_position_on_ledge(position_on_ledge)
	var hang_normal = player.ledge.get_normal_on_ledge(position_on_ledge)
	
	player.global_transform.origin = hang_position + (hang_normal * 0.3) + (Vector3.DOWN * 0.15)
	player.face_towards(hang_position)

	if position_on_ledge > player.ledge.max_length - 0.5:
		player.ledge.extend_path(LedgeSearcher.Direction.RIGHT)

	if position_on_ledge < player.ledge.min_length + 0.5:
		player.ledge.extend_path(LedgeSearcher.Direction.LEFT)
	
	DebugDraw.draw_cube(hang_position, 0.1, Color.RED)
	
func handle_input(event: InputEvent) -> void:		
	if event is InputEventKey and event.keycode == 4194305 and event.pressed:
		state_machine.transition_to_previous_state()
