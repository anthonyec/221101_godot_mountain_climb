extends PlayerState

var rope: RaycastRope
var start_position: Vector3
var direction: Vector3
var movement: Vector3

func enter(params: Dictionary) -> void:
	if params.has("rope"):
		rope = params.get("rope")
		
	assert(rope, "Abseil states need rope")
	
	# TODO: Set a way to reset the target. Also, need to change RaycastRope to AbseilRope.
	rope.target = player
	player.set_collision_mode("abseil")
	start_position = player.global_transform.origin
	
func exit() -> void:
	rope = null

func update(_delta: float) -> void:
	var last_joint_above_player: Vector3
	
	for index in range(rope.joints.size()):
		var backwards_index = (rope.joints.size() - 1) - index
		var joint_position = rope.joints[backwards_index]
		
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
		state_machine.transition_to("AbseilWall", { "rope": rope })
		return
	
	DebugDraw.draw_cube(last_joint_above_player, 1, Color.BLUE)
		
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if direction.length():
		player.animation.play("Run")
	else:
		player.animation.play("Idle")
	
func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("AbseilStartDown", { "rope": rope })
		return
		
	movement.x = direction.x * player.walk_speed
	movement.z = direction.z * player.walk_speed
	
	
	if rope.total_length > rope.max_length:
		var direction_to_end = player.global_transform.origin.direction_to(rope.target_position)
		var distance_to_end = player.global_transform.origin.distance_to(rope.target_position)
		
		movement += direction_to_end * distance_to_end * 5
		movement.y = 0
		
	# Gravity added after Y movement is zero-ed out so that there's no 
	# jittering between states.
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
		state_machine.transition_to("Move")
		return

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(player.get_action_name("start_hosting_abseil")):
		state_machine.transition_to("Move")
		return
