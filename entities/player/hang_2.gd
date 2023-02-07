extends PlayerState

var position_on_ledge: float = 0

func awake() -> void:
	super.awake()

func enter(params: Dictionary) -> void:
	Raycast.debug = true
	player.ledge.debug = true
	
	player.animation.play("Hang-loop_RobotArmature")
	player.collision.disabled = true
#	player.model.scale = Vector3(0.5, 0.5, 0.5)
	
	# TODO: Find out why this sometimes fails.
	player.ledge.find_path(1)
	player.ledge.find_path(-1)
	
	assert(player.ledge.path)

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
	
	# TODO: Get normal from path rather than finding a ledge each frame :).
#	var ledge_info = player.ledge.get_ledge_info(player.global_transform.origin, -player.global_transform.basis.z)
#
#	if ledge_info.has_error():
#		ledge_info.normal = Vector3.RIGHT
	
	player.global_transform.origin = hang_position + (hang_normal * 0.3) + (Vector3.DOWN * 0.15)
	player.face_towards(hang_position)

	if position_on_ledge > player.ledge.max_length - 0.5:
		player.ledge.find_path(1, true)

	if position_on_ledge < player.ledge.min_length + 0.5:
		player.ledge.find_path(-1, true)
	
	DebugDraw.draw_cube(hang_position, 0.1, Color.RED)
	
func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == 78 and event.pressed:
		player.ledge.find_path(-1, true)
		
	if event is InputEventKey and event.keycode == 77 and event.pressed:
		player.ledge.find_path(1, true)
		
	if event is InputEventKey and event.keycode == 4194305 and event.pressed:
		state_machine.transition_to_previous_state()
