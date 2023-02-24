extends PlayerState

var position_on_ledge: float = 0

func awake() -> void:
	super.awake()

func enter(params: Dictionary) -> void:
	player.animation.play("Hang-loop_RobotArmature")
#	player.collision.disabled = true
	
	var ledge_info = params.get("ledge_info")
	assert(ledge_info, "Ledge info required for hang state to work")
	
	player.ledge.find_and_build_path(ledge_info, LedgeSearcher.Direction.RIGHT)
	player.ledge.find_and_build_path(ledge_info, LedgeSearcher.Direction.LEFT)
	assert(player.ledge.path, "Path should be found")

func exit() -> void:
	position_on_ledge = 0
#	player.collision.disabled = false
	player.ledge.reset()
	
func update(_delta: float) -> void:
	DebugDraw.set_text(
		"player " + str(player.player_number) + " ledge min/max", 
		str(Debug.round_to_dec(position_on_ledge, 2)) + " : " + 
		str(Debug.round_to_dec(player.ledge.min_length, 2)) + " " + 
		str(Debug.round_to_dec(player.ledge.max_length, 2))
	)
	DebugDraw.set_text(
		"player " + str(player.player_number) + " ledge path", 
		str(player.ledge.total_length) + ", " +
		str(player.ledge.path.size())
	)
	
	if !Input.is_action_pressed(player.get_action_name("grab")):
		state_machine.transition_to("Fall")
		return

func physics_update(delta: float) -> void:
	var direction = player.transform_direction_to_camera_angle(
		Vector3(player.input_direction.x, 0, player.input_direction.y)
	)
	
	# TODO: Remove last bit "RobotArmature" of animation name.
	if direction.length() != 0:
		player.animation.play("Hang-shimmy_RobotArmature")
	else:
		player.animation.play("Hang-loop_RobotArmature")
	
	if player.stamina.is_depleted():
		state_machine.transition_to("Fall")
		return 
		
	var hang_position = player.ledge.get_position_on_ledge(position_on_ledge)
	var hang_normal = player.ledge.get_normal_on_ledge(position_on_ledge)
	
	var ledge_direction = hang_normal.cross(Vector3.DOWN)
	var shimmy_strength = ledge_direction.dot(direction)
	var vault_strength = hang_normal.dot(-direction)
	
	# Keyboard only has 4 way directional control, so the movement should 
	# ignore any relative direction.
	if player.input_type == player.InputType.KEYBOARD:
		shimmy_strength = player.input_direction.x
		vault_strength = -player.input_direction.y

	position_on_ledge += shimmy_strength * delta
	position_on_ledge = clamp(position_on_ledge, player.ledge.min_length + 0.5, player.ledge.max_length - 0.5)
	player.stamina.use(15.0 * abs(shimmy_strength) * delta)
	
	player.global_transform.origin = hang_position + (hang_normal * 0.3) + (Vector3.DOWN * 0.15)
	player.face_towards(hang_position)

	if position_on_ledge > player.ledge.max_length - 0.6:
		player.ledge.extend_path(LedgeSearcher.Direction.RIGHT)

	if position_on_ledge < player.ledge.min_length + 0.6:
		player.ledge.extend_path(LedgeSearcher.Direction.LEFT)
		
	if vault_strength < -0.4 and Input.is_action_just_pressed(player.get_action_name("jump")):
		player.face_towards(player.global_transform.origin + hang_normal)
		player.stamina.use(30.0)
		
		# TODO: This should probably transition to a specfic VaultJump state that
		# ignores input_direction.
		state_machine.transition_to("Jump", {
			# TODO: Don't use magic numbers here for jump strength
			"movement": hang_normal * 5,
			"jump_strength": 5
		})
		return

	# TODO: Change time check input resetting.
	var ledge_info = player.ledge.get_ledge_info(player.global_transform.origin, -player.global_transform.basis.z)
	
	var start_position = player.global_transform.origin + Vector3.UP
	var end_position = ledge_info.position + Vector3.UP - (ledge_info.wall_normal * 0.45)
	var is_vault_area_hit = sweep_cylinder(start_position, end_position)
	
	if not is_vault_area_hit and Input.is_action_just_pressed(player.get_action_name("jump")) and state_machine.time_in_current_state > 200:
		state_machine.transition_to("Vault")
		return

# TODO: Turn iterations stuff into a Raycast helper. I think the name would be sweep. Might alreayd be build in, search ShapeSweep3D.
func sweep_cylinder(start_position: Vector3, end_position: Vector3) -> bool:
	var hit: Array = []
	var iterations: int = 5
	
	for index in range(0, iterations):
		var percent = float(index) / float(iterations)
		var check_position = start_position.lerp(end_position, percent)
		var shape_hit = Raycast.intersect_cylinder(check_position, 1.5, 0.25, 1, [self])
		
		if shape_hit:
			hit = shape_hit
			break
	
	return not hit.is_empty()
