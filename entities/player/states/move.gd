extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var speed_percent: float = 0 
var max_speed: float = 6
var acceleration: float = 60
var deceleration: float = 60

var input_direction: Vector3 = Vector3.ZERO
var momentum: Vector3 = Vector3.ZERO
var momentum_speed: float = 0
var is_ready_to_lift_companion: bool = false

func enter(params: Dictionary) -> void:
	player.up_direction = Vector3.UP
	player.floor_stop_on_slope = true
	player.stamina.can_recover = true
	player.animation.play("Idle")
	
	# Seeking is a work around to avoid a 1 frame delay from playing an animation.
	# Without this and when using changing the position, the player would move to 
	# the `global_origin` position in the first frame, then change animation in the next frame,
	# even though the animation says it's in the new animation!
	# Solution found here: https://github.com/godotengine/godot/issues/29187#issuecomment-496078025
	player.animation.seek(0, true)
	
	if params.has("move_to"):
		player.global_transform.origin = params.get("move_to")

	# Do a collision check when entering the state to ensure the player
	# so that `is_on_floor()` does not return `false` on the first physics update.
	# This fixes "vault" to "move" state causing it to breifly enter the "fall" state.
	if params.get("snap_to_floor"):
		player.snap_to_ground()
		
	if params.has("momentum_speed"):
		momentum_speed = clamp(params.get("momentum_speed", 0) * 0.9, 0, 1)
		
func exit() -> void:
	player.stamina.can_recover = false
	player.animation.speed_scale = 1
	player.reset_model_alignment()
	
	input_direction = Vector3.ZERO
	momentum = Vector3.ZERO
	momentum_speed = 0

func update(delta: float) -> void:
	return
	DebugDraw.draw_ray_3d(player.global_transform.origin, player.camera_relative_input_direction, 1, Color.WHITE)
	DebugDraw.draw_ray_3d(player.global_transform.origin, player.forward, 1, Color.CYAN)
	DebugDraw.draw_ray_3d(player.get_offset(Vector3(0, -0.05, 0)), player.velocity.normalized(), 1, Color.RED)

func get_slope_percent() -> float:
	# TODO: Combine this stuff with the `snap_to_ground` and other player floor methods.
	var floor_hit = Raycast.cast_in_direction(player.global_transform.origin, Vector3.DOWN, player.height, player.WORLD_COLLISION_MASK)
	assert(not floor_hit.is_empty())
	
	var projected_velocity = Plane(floor_hit.normal).project(player.velocity).normalized()
	
	# clamp(slope_percent_old, 0.9, 2)

	# Bigger than 1 is downhill, less than 1 is up hill and 1 is flat.
	return 1 - projected_velocity.y

func physics_update(delta: float) -> void:
	DebugGraph.plot(str(player.player_number) + "_player.velocity", player.velocity.length())
	
	if not player.is_near_ground():
		state_machine.transition_to("Fall", {
			"coyote_time_enabled": true
		})
		return
	
	var facing_direction_percent = clamp(player.camera_relative_input_direction.dot(player.forward), 0, 1)
	
	var input_length: float = player.camera_relative_input_direction.length()	
	input_length = clamp(input_length, 0.5, 1) if input_length > 0.1 else 0
	
	var is_input_length_zero: float = is_zero_approx(input_length)
	var velocity_change_speed: float = deceleration if is_input_length_zero else acceleration
	
	var speed_toward_speed: float = 30 if is_input_length_zero else 1.5

	var unit_forward_velocity: Vector3 = player.velocity.normalized() * (player.velocity.length() / max_speed)
	var forward_speed_percent: float = unit_forward_velocity.dot(player.forward)	
	DebugDraw.set_text("forward_speed_percent", forward_speed_percent)
	
	speed_percent = move_toward(speed_percent, input_length, speed_toward_speed * delta)
	
	DebugGraph.plot(str(player.player_number) + "_speed_percent", speed_percent)
	DebugDraw.set_text("speed_percent", speed_percent)
	
	var target_velocity = player.forward * max_speed * input_length
	
	player.velocity = player.velocity.move_toward(
		target_velocity, 
		velocity_change_speed * delta
	)
	
	if player.input_direction.length() > 0.2:
		player.animation.play("Run")
		player.animation.speed_scale = input_length
	else:
		player.animation.play("Idle")
		player.animation.speed_scale = 1
	
	player.face_towards(player.get_offset(player.camera_relative_input_direction), 10, delta)
	player.move_and_slide()
	player.snap_to_ground()
	player.align_model_to_floor(delta)

	if player.companion:
		var distance_to_companion = player.global_transform.origin.distance_to(player.companion.global_transform.origin)
		var companion_state = player.companion.state_machine.current_state.name
		
		if Input.is_action_pressed(player.get_action_name("grab")) and Input.is_action_pressed(player.companion.get_action_name("grab")):
			if distance_to_companion < 1 and companion_state == "Move":
				DebugDraw.draw_line_3d(player.global_transform.origin, player.companion.global_transform.origin, Color.GREEN)
				is_ready_to_lift_companion = true
		else:
			is_ready_to_lift_companion = false
			
	var collisions = player.pickup_collision.get_overlapping_areas()
	var water_collision = collisions.filter(func (area: Area3D):
		return area.is_in_group("water")
	)
	
	if not water_collision.is_empty():
		var water_area = water_collision[0]
		
		# TODO: Pass water area to swim state?
		state_machine.transition_to("Swim")
		return
	
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(player.get_action_name("start_hosting_abseil")):
		state_machine.transition_to("Belay")
		return
		
	if event.is_action_pressed(player.get_action_name("jump")) and is_ready_to_lift_companion:
		# TODO: Use `send_message` to send message instead of forcing states.
		player.companion.state_machine.transition_to("Lift")
		player.state_machine.transition_to("Held")
		return

	# TODO: Do I need a floor check here?
	if event.is_action_pressed(player.get_action_name("jump")):
		state_machine.transition_to("Jump", {
			"movement": momentum,
			"momentum_speed": momentum_speed
		})
		return
		
	if event.is_action_pressed(player.get_action_name("grab")):
		for area in player.pickup_collision.get_overlapping_areas():
			if area.is_in_group("wood_pickup") and area.has_method("pick_up"):
				state_machine.transition_to("Pickup", { "item": area })
				return
				
	if event.is_action_pressed(player.get_action_name("grab")):
		var abseil_ropes = get_tree().get_nodes_in_group("abseil_rope")
		
		if abseil_ropes.is_empty():
			return
		
		for abseil_rope in abseil_ropes:
			# TODO: Abstract get nearest stuff away into AbseilRope.
			var rope = abseil_rope as AbseilRope
			var nearest_position = rope.get_nearest_position_to(player.global_transform.origin)
			
			if nearest_position.distance_to(player.global_transform.origin) < 1.5:
				state_machine.transition_to("Abseil", { "rope": rope })
				return
				
	if event.is_action_pressed(player.get_action_name("camp")):
		for area in player.pickup_collision.get_overlapping_areas():
			if area.get_parent().is_in_group("player"):
				var total_sticks = player.inventory.get_item_count("wood") + player.companion.inventory.get_item_count("wood")
				
				if total_sticks >= 6:
					player.companion.state_machine.transition_to("Camp")
					player.state_machine.transition_to("Camp")
					return
	


