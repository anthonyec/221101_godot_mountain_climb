extends PlayerState

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO

func enter(params: Dictionary) -> void:
	Raycast.debug = true
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

func exit() -> void:
	player.stamina.can_recover = false

func update(delta: float) -> void:
	player.find_ledge_info()
	
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if direction.length():
		player.animation.play("Run")
	else:
		player.animation.play("Idle")

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		return state_machine.transition_to("Fall", {
			"movement": movement,
			"coyote_time_enabled": true,
		})
	
	movement.x = direction.x * player.walk_speed
	movement.z = direction.z * player.walk_speed
	movement.y -= player.gravity * delta
	
	player.face_towards(player.global_transform.origin + direction)
	player.set_velocity(movement)
	player.set_up_direction(Vector3.UP)
	player.set_floor_stop_on_slope_enabled(true)

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
	movement = player.velocity
	
func handle_input(event: InputEvent) -> void:
	# TODO: Do I need a floor check here?
	if event.is_action_pressed(player.get_action_name("jump")):
		return state_machine.transition_to("Jump", { "movement": movement })
		
	if event.is_action_pressed(player.get_action_name("grab")):
		for area in player.pickup_collision.get_overlapping_areas():
			if area.is_in_group("wood_pickup") and area.has_method("pick_up"):
				return state_machine.transition_to("Pickup", { "item": area })
