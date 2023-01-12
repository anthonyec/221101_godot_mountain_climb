extends PlayerState

var speed: float = 5

# This is used for setting up the camping players and not having them move
# around to user input. Kind of temporary.
var is_disabled: bool = false

func enter(params: Dictionary) -> void:
	is_disabled = params.get("disabled", false)
	player.animation.play("T-pose")
	player.stamina.can_recover = true
	player.stamina.regain(player.stamina.max_stamina)

func physics_update(delta: float) -> void:
	if is_disabled:
		return

	var direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if Input.is_action_pressed(player.get_action_name("jump")):
		direction = Vector3.ZERO
		direction.y = -player.input_direction.y
		
	if Input.is_action_pressed(player.get_action_name("grab")):
		direction = direction * 5
	
	player.global_transform.origin += direction * speed * delta
 
