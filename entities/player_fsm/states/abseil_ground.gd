extends PlayerState

var start_position: Vector3
var direction: Vector3
var movement: Vector3

func enter(_params: Dictionary) -> void:
	start_position = player.global_transform.origin
	
	var raycast_rope_scene = load("res://entities/raycast_rope/raycast_rope.tscn")
	
	if not player.rope:
		var raycast_rope = raycast_rope_scene.instantiate() as RaycastRope
		raycast_rope.global_transform.origin = start_position
		raycast_rope.target = player
		
		player.rope = raycast_rope
		player.get_parent().add_child(raycast_rope)

func update(_delta: float) -> void:
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if direction.length():
		player.animation.play("Run")
	else:
		player.animation.play("Idle")
	
func physics_update(delta: float) -> void:
#	if not player.is_on_floor() and player.rope.joints.size() > 1:
#		return state_machine.transition_to("Swing", {
#			"use_rope": true,
#			"length": 1
#		})

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

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(player.get_action_name("start_hosting_abseil")):
		player.get_parent().remove_child(player.rope)
		player.rope = null
		return state_machine.transition_to("Move")
