extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO
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

func exit() -> void:
	player.stamina.can_recover = false

func update(_delta: float) -> void:
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	player.face_towards(player.global_transform.origin + direction)
	
	if direction.length():
		player.animation.play("Run")
	else:
		player.animation.play("Idle")

func physics_update(delta: float) -> void:
	var player_forward = -player.global_transform.basis.z
	
	movement = player_forward * direction.length() * player.walk_speed
	
	player.velocity = movement
	
	if player.velocity.length() >= 20.0:
		player.velocity = player.velocity.normalized() * 20.0

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
	movement = player.velocity
		
	if player.is_near_ground():
		player.snap_to_ground()
	else:
		state_machine.transition_to("Fall", {
			"movement": movement,
			"coyote_time_enabled": true
		})
		return
	
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
		state_machine.transition_to("Jump", { "movement": movement })
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
	


