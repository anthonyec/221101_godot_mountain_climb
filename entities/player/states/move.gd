extends PlayerState

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO
var is_ready_to_lift_companion: bool = false

func enter(params: Dictionary) -> void:
	player.up_direction = Vector3.UP
	player.floor_stop_on_slope = true
	player.stamina.can_recover = true
	player.set_collision_mode("default")
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
		player.snap_to_floor()

func exit() -> void:
	player.stamina.can_recover = false

func update(_delta: float) -> void:
	player.find_ledge_info()
	
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if direction.length():
		player.animation.play("Run")
	else:
		player.animation.play("Idle")

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("Fall", {
			"movement": movement,
			"coyote_time_enabled": true,
		})
		return
	
	var player_forward = -player.global_transform.basis.z
	
	movement = player_forward * direction.length() * player.walk_speed
	movement.y -= player.gravity * delta
	
	# TODO: Implement proper turning on spot.
	if direction.length() > 0.3:
		player.face_towards(player.global_transform.origin + direction, player.ground_turn_speed, delta)
	else:
		player.face_towards(player.global_transform.origin + direction)
		
	player.velocity = movement

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
	movement = player.velocity
	
	# TODO: Clean this up. Maybe it could use a step up animation or state.
	var curb_hit = Raycast.cast_in_direction(player.get_offset_position(0.0, -0.95), direction.normalized(), 0.35)
	
	if not curb_hit.is_empty() and curb_hit.normal.angle_to(Vector3.UP) > deg_to_rad(85):
		var curb_floor_hit = Raycast.cast_in_direction(curb_hit.position - (curb_hit.normal * 0.1) + Vector3.UP * 0.5, Vector3.DOWN, 0.5)
		
		if not curb_floor_hit.is_empty():
			DebugDraw.draw_cube(curb_floor_hit.position, 0.1, Color.RED)
			player.stand_at_position(curb_floor_hit.position)
	
	var distance_to_companion = player.global_transform.origin.distance_to(player.companion.global_transform.origin)
	var companion_state = player.companion.state_machine.current_state.name
	
	if Input.is_action_pressed(player.get_action_name("grab")) and Input.is_action_pressed(player.companion.get_action_name("grab")):
		if distance_to_companion < 1 and companion_state == "Move":
			DebugDraw.draw_line_3d(player.global_transform.origin, player.companion.global_transform.origin, Color.GREEN)
			is_ready_to_lift_companion = true
	else:
		is_ready_to_lift_companion = false
		
	if player.companion.rope:
		var nearest_position = player.companion.rope.get_nearest_position_to(player.global_transform.origin)
		var distance_nearest_position = player.global_transform.origin.distance_to(nearest_position)
		
		if distance_nearest_position < 1.5:
			DebugDraw.draw_cube(nearest_position, 0.25, Color.YELLOW)
		
		if distance_nearest_position < 1.5 and Input.is_action_pressed(player.get_action_name("grab")):
			state_machine.transition_to("AbseilGround", {
				"rope": player.companion.rope,
			})
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
		state_machine.transition_to("Jump", { "movement": movement })
		return
		
	if event.is_action_pressed(player.get_action_name("grab")):
		for area in player.pickup_collision.get_overlapping_areas():
			if area.is_in_group("wood_pickup") and area.has_method("pick_up"):
				state_machine.transition_to("Pickup", { "item": area })
				return
				
	if event.is_action_pressed(player.get_action_name("camp")):
		for area in player.pickup_collision.get_overlapping_areas():
			if area.get_parent().is_in_group("player"):
				var total_sticks = player.inventory.get_item_count("wood") + player.companion.inventory.get_item_count("wood")
				
				if total_sticks >= 6:
					player.companion.state_machine.transition_to("Camp")
					player.state_machine.transition_to("Camp")
					return
	


