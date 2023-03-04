extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO
var is_ready_to_lift_companion: bool = false

var last_slope_percent: float = 0
var momentum: Vector3 = Vector3.ZERO
var momentum_speed: float = 0
var floor_normal_lerped: Vector3 = Vector3.UP

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
	player.model.transform.basis = Basis.IDENTITY
	player.model.transform.origin = Vector3.ZERO
	floor_normal_lerped = Vector3.UP

func update(delta: float) -> void:
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	player.face_towards(player.global_transform.origin + direction, 10, delta)
	
	if direction.length():
		player.animation.play("Run")
		player.animation.speed_scale = player.velocity.length() / player.walk_speed
	else:
		player.animation.play("Idle")
		player.animation.speed_scale = 1

func physics_update(delta: float) -> void:
	var player_forward = -player.global_transform.basis.z
	
	movement = player_forward * direction.length() * player.walk_speed
	
#	player.velocity = movement
	
	if player.velocity.length() >= 20.0:
		player.velocity = player.velocity.normalized() * 20.0

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
	movement = player.velocity
		
	if not player.is_near_ground():
		state_machine.transition_to("Fall", {
			"movement": movement,
			"coyote_time_enabled": true
		})
		return
	
	player.snap_to_ground()
	
	var floor_hit = Raycast.cast_in_direction(player.global_transform.origin, Vector3.DOWN, player.height, player.WORLD_COLLISION_MASK)
	assert(not floor_hit.is_empty())
	
	var floor_normal_right = floor_hit.normal.cross(Vector3.DOWN).normalized()
	var up_slope_direction = floor_hit.normal.cross(floor_normal_right)
	
	var momentum_on_slope = Plane(floor_hit.normal).project(momentum).normalized()
	
	# Bigger than 1 is downhill, less than 1 is up hill and 1 is flat.
	var slope_percent = 1 - momentum_on_slope.y
	
	if player.velocity.length() > 4 and slope_percent > 1.2:
		floor_normal_lerped += (floor_hit.normal - floor_normal_lerped) * delta * 5.0
	else:
		floor_normal_lerped += (Vector3.UP - floor_normal_lerped) * delta * 5.0
	
	var forward_on_slope = Plane(floor_normal_lerped).project(player.global_transform.basis.z).normalized()
	var right_on_slope = floor_hit.normal.cross(forward_on_slope).normalized()
	var model_basis = Basis(right_on_slope, floor_normal_lerped, forward_on_slope).orthonormalized()
	
	player.model.global_transform.basis = model_basis
	
	var model_position = floor_hit.position + floor_normal_lerped
	
	player.model.global_transform.origin = model_position
	
	DebugDraw.draw_ray_3d(floor_hit.position, model_basis.x, 2, Color.RED)
	DebugDraw.draw_ray_3d(floor_hit.position, model_basis.y, 2, Color.GREEN)
	DebugDraw.draw_ray_3d(floor_hit.position, model_basis.z, 2, Color.CYAN)
	DebugDraw.draw_line_3d(floor_hit.position, model_position, Color.WHITE)
	
#	DebugDraw.draw_ray_3d(floor_hit.position, floor_normal_right, 2, Color.RED)
	DebugDraw.draw_ray_3d(floor_hit.position, floor_normal_lerped, 3, Color.GREEN)
#	DebugDraw.draw_ray_3d(floor_hit.position, up_slope_direction, 2, Color.CYAN)

	
	DebugDraw.draw_ray_3d(floor_hit.position, momentum_on_slope, 2, Color.WHITE)
	
#	DebugDraw.draw_ray_3d(floor_hit.position, floor_hit.normal.cross(player.global_transform.basis.x), 1, Color.PINK)
#	DebugDraw.draw_ray_3d(floor_hit.position, slope_direction, 1, Color.GREEN)
#	DebugDraw.draw_ray_3d(floor_hit.position + (Vector3.UP * 0.1), momentum.normalized(), 1, Color.CYAN)
	
#	var dot = momentum.normalized().dot(up_slope_direction)
	
#	print(dot)
	
#	momentum += direction * momentum_speed
#	momentum *= 0.85
	
#	momentum += direction * delta * (player.walk_speed * 1.5)
#	momentum *= 0.9
	
	momentum = direction
	
	var target_speed = player.walk_speed * slope_percent
	momentum_speed = lerp(momentum_speed, target_speed, delta)
	
	player.velocity = momentum * momentum_speed
	
	last_slope_percent = slope_percent
	
	DebugDraw.set_text("target_speed", target_speed)
	DebugDraw.set_text("momentum_speed", momentum_speed)
	DebugDraw.set_text("slope_percent", slope_percent)
	
#	var up = floor_hit.normal
#
#	player.model.transform.origin = Vector3(0, 0, 0)
#	player.model.global_transform.basis.y = up
#	player.model.global_transform.basis.x = -player.model.global_transform.basis.z.cross(up)
#	player.model.global_transform.basis = player.model.global_transform.basis.orthonormalized()
#	player.model.transform.origin = Vector3(0, 1, 0)

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
	


