extends PlayerState

var start_position: Vector3
var direction: Vector3
var movement: Vector3

func enter(_params: Dictionary) -> void:
	player.set_collision_mode("abseil")
	start_position = player.global_transform.origin
	
	var raycast_rope_scene = load("res://entities/raycast_rope/raycast_rope.tscn")
	
	if not player.rope:
		var raycast_rope = raycast_rope_scene.instantiate() as RaycastRope
		raycast_rope.global_transform.origin = start_position
		raycast_rope.target = player
		
		player.rope = raycast_rope
		player.get_parent().add_child(raycast_rope)

func update(_delta: float) -> void:
	var last_joint_above_player: Vector3
	
	for index in range(player.rope.joints.size()):
		var backwards_index = (player.rope.joints.size() - 1) - index
		var joint_position = player.rope.joints[backwards_index]
		
		if joint_position.y > player.global_transform.origin.y + 2:
			last_joint_above_player = joint_position
			break
	
	var horizontal_distance = Vector3(last_joint_above_player.x, 0, last_joint_above_player.z).distance_to(
		Vector3(player.global_transform.origin.x, 0, player.global_transform.origin.z)
	)
	
	var last_joint_direction_to_player: Vector3 = last_joint_above_player.direction_to(player.global_transform.origin)
	var angle_to_last_joint: float = rad_to_deg(last_joint_direction_to_player.angle_to(Vector3.DOWN))
	
	# TODO: Tweak these values and somehow notify when they can or cannot climb up.
	if Input.is_action_just_pressed(player.get_action_name("jump")) and angle_to_last_joint < 20 and horizontal_distance < 10:
		# TODO: Change o abseil start up state.
		player.global_transform.origin = player.get_offset_position(0.0, 1.0)
		player.move_and_slide()
		return state_machine.transition_to("AbseilWall")
	
	DebugDraw.draw_cube(last_joint_above_player, 1, Color.BLUE)
		
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if direction.length():
		player.animation.play("Run")
	else:
		player.animation.play("Idle")
	
func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		return state_machine.transition_to("AbseilStartDown")
		
	movement.x = direction.x * player.walk_speed
	movement.z = direction.z * player.walk_speed
	movement.y -= player.gravity * delta
	
	player.face_towards(start_position)
	player.set_velocity(movement)
	player.set_up_direction(Vector3.UP)
	player.set_floor_stop_on_slope_enabled(true)

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
	movement = player.velocity
	
	if !Input.is_action_pressed(player.get_action_name("grab")):
		player.get_parent().remove_child(player.rope)
		player.rope = null
		return state_machine.transition_to("Move")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(player.get_action_name("start_hosting_abseil")):
		# TODO: Move this clean up in exit and check for next state is move. I guess 
		# this is where substates come in handy.
		player.get_parent().remove_child(player.rope)
		player.rope = null
		return state_machine.transition_to("Move")
