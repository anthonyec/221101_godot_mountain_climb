extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO

func enter(_params: Dictionary) -> void:
	player.animation.play("Dive")
	player.global_transform.origin = player.get_offset_position(0, 0.5)
	movement = player.velocity * 0.5
	
	SFX.play_at_location("impact/water", player.global_transform.origin)
	
	# TODO: Add a special effects API like this?
	# ```gdscript
	# Particles.spawn_at_location("impact/water", player.global_transform.origin)
	# var water_trail = Particles.attach_to("water_trail", player)
	# ```
	
func exit() -> void:
	movement = Vector3.ZERO

func update(delta: float) -> void:
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	player.face_towards(player.global_transform.origin + direction, 5.0, delta)
	player.stamina.use(5.0 * delta)
	
func physics_update(delta: float) -> void:
	var player_forward = -player.global_transform.basis.z
	
	movement += player_forward * direction.length() * (player.walk_speed / 2) * delta
	movement *= 0.98
	
	player.velocity = movement
	player.move_and_slide()
	movement = player.velocity
		
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(player.get_action_name("jump")):
		state_machine.transition_to("Jump", {
			"movement": movement,
			"momentum_speed": 1
		})
		return
