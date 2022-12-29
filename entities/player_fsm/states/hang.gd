extends PlayerState

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO
var climb_up_position: Vector3 = Vector3.ZERO

func enter(params: Dictionary) -> void:	
	# TODO: Should this be renamed to "hang_position"? At the moment it is 
	# consistent with the `move` state.
	if params.has("move_to"):
		player.global_transform.origin = params.get("move_to")
	
	if params.has("face_towards"):
		player.face_towards(params.get("face_towards"))
	
	player.animation.play("Hang-loop_RobotArmature")

func update(delta: float) -> void:
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if direction.length() != 0:
		player.animation.play("Hang-shimmy_RobotArmature")
	else:
		player.animation.play("Hang-loop_RobotArmature") # TODO: Remove last bit of animation name
	
	player.stamina.use(1.5 * delta)
	
	if player.stamina.is_depleted():
		return state_machine.transition_to("Fall")

	player.set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap_vector`
	player.set_up_direction(Vector3.UP)
	player.set_floor_stop_on_slope_enabled(true)
	var _move_and_slide = player.move_and_slide()
	movement = player.velocity
	
	var ledge_info = player.find_ledge_info()
	
	if ledge_info.is_empty():
		push_warning("Failed to find ledge info in grab state")
		return state_machine.transition_to("Move")
	
	var shimmy_direction = ledge_info.edge_direction
	var shimmy_strength = -player.global_transform.basis.x.dot(direction)
	var shimmy_strength_clamped = clamp(
		shimmy_strength,
		## TODO: Any way to fix this so it isn't flipped round in a very unintutive way?
		-1 if !ledge_info.has_reached_right_bound else 0,
		1 if !ledge_info.has_reached_left_bound else 0,
	)
	
	player.stamina.use(15.0 * abs(shimmy_strength) * delta)
	
	var climb_up_strength = -player.global_transform.basis.z.dot(direction)
	
	movement = shimmy_direction * shimmy_strength_clamped
	
	player.global_transform.origin = ledge_info.hang_position
	player.face_towards(ledge_info.wall.position)
	
	var start_climb_up_position: Vector3 = ledge_info.floor.position + (player.global_transform.basis.y * 1.25) + (ledge_info.wall.normal * 0.6)
	var end_climb_up_position: Vector3 = ledge_info.floor.position + (player.global_transform.basis.y * 1.25) + (-ledge_info.wall.normal * 0.5)
	
	var debug_prev = Raycast.debug
	Raycast.debug = false
	# TODO: Turn iterations stuff into a Raycast helper. I think the name would be sweep. Might alreayd be build in, search ShapeSweep3D.
	var hit: Array = []
	var iterations: int = 5
	
	for index in range(0, iterations):
		var percent = float(index) / float(iterations)
		var check_position = start_climb_up_position.lerp(end_climb_up_position, percent)
		var shape_hit = Raycast.intersect_cylinder(check_position, 1.5, 0.25)
		
		if shape_hit:
			hit = shape_hit
			break
	Raycast.debug = debug_prev
	
	climb_up_position = ledge_info.floor.position + (player.global_transform.basis.y)
	
	if hit.is_empty() and Raycast.debug:
		DebugDraw.draw_line_3d(player.global_transform.origin, climb_up_position, Color.GREEN)
		DebugDraw.draw_cube(climb_up_position, 0.5, Color.GREEN)
		
	if Raycast.debug:
		DebugDraw.draw_ray_3d(player.global_transform.origin, direction, 2, Color.GREEN)
	
	if climb_up_strength > 0.8 and state_machine.time_in_current_state > 200 and hit.is_empty():
		return state_machine.transition_to("Vault")
	
	# TODO: Change time check input resetting.
	if abs(climb_up_strength) == 0 and Input.is_action_just_pressed(player.get_action_name("jump")) and hit.is_empty():
		return state_machine.transition_to("Vault")
		
	if Input.is_action_just_pressed(player.get_action_name("jump")) and climb_up_strength < -0.4:
		player.face_towards(player.global_transform.origin + direction)
		player.stamina.use(30.0)
		
		# TODO: This should probably transition to a specfic VaultJump state.
		return state_machine.transition_to("Jump", {
			# TODO: Don't use magic numbers here for jump strength
			"movement": direction * 5,
			"jump_strength": 5
		})
		
	if !Input.is_action_pressed(player.get_action_name("grab")):
		return state_machine.transition_to("Fall")
	
	
	
