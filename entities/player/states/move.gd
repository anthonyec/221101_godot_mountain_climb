extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var is_ready_to_lift_companion: bool = false

var input_direction: Vector3 = Vector3.ZERO
var momentum: Vector3 = Vector3.ZERO
var momentum_speed: float = 0
var input_length: float = 0

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
	
	input_length = 0
	input_direction = Vector3.ZERO
	momentum = Vector3.ZERO
	momentum_speed = 0

func update(delta: float) -> void:
	input_direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	# TODO: Messy way to do this, maybe it should be based on a curve?
	var is_slow_turn_speed = player.velocity.length() > (player.walk_speed - 1)
	var turn_speed = 5 if is_slow_turn_speed else 10
	
	if player.velocity.length() < 0.1:
		turn_speed = 20
	
	player.face_towards(player.global_transform.origin + input_direction.normalized(), turn_speed, delta)
	
	if input_direction.length() == 0:
		input_length = 0
	else:
		input_length = remap(input_direction.length(), 0, 1, 0.2, 1)
	
	if player.velocity.length() > 0.2:
		player.animation.play("Run")
		player.animation.speed_scale = player.velocity.length() / player.walk_speed
	else:
		player.animation.play("Idle")
		player.animation.speed_scale = 1

func physics_update(delta: float) -> void:
	var player_forward = -player.global_transform.basis.z
	
	if not player.is_near_ground():
		state_machine.transition_to("Fall", {
			"movement": player.velocity,
			"momentum_speed": momentum_speed,
			"coyote_time_enabled": true
		})
		return
	
	var floor_hit = Raycast.cast_in_direction(player.global_transform.origin, Vector3.DOWN, player.height, player.WORLD_COLLISION_MASK)
	assert(not floor_hit.is_empty())
	
	var momentum_projected_on_slope = Plane(floor_hit.normal).project(momentum).normalized()
	
	# Bigger than 1 is downhill, less than 1 is up hill and 1 is flat.
	var slope_percent = 1 - momentum_projected_on_slope.y
	
	slope_percent = clamp(slope_percent, 0.9, 2)
	
	# This acts as the friction. When the player starts running, we want to 
	# gain speed slowly. When the player stops, we want to loose speed quickly.
	var momentum_lerp_speed = 8 if input_length == 0 else 2
	
	momentum_speed = lerp(momentum_speed, input_length * slope_percent, momentum_lerp_speed * delta)
	momentum = -player.global_transform.basis.z * player.walk_speed * momentum_speed
	
	player.velocity = momentum
	player.move_and_slide()
	player.snap_to_ground()
	player.align_model_to_floor(delta)
	
	DebugDraw.draw_ray_3d(floor_hit.position, player.velocity * 0.5, 2, Color.WHITE)
	DebugDraw.set_text("input_length", input_length)
	DebugDraw.set_text("momentum_lerp_speed", momentum_lerp_speed)
	DebugDraw.set_text("momentum_speed", momentum_speed)

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
	


