extends PlayerState

var speed: float = 5

func enter(_params: Dictionary) -> void:
	player.animation.play("T-pose")
	player.stamina.can_recover = true
	player.stamina.regain(player.stamina.max_stamina)

func physics_update(delta: float) -> void:
	var direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if Input.is_action_pressed(player.get_action_name("jump")):
		direction = Vector3.ZERO
		direction.y = -player.input_direction.y
		
	if Input.is_action_pressed(player.get_action_name("grab")):
		direction = direction * 5
	
	player.global_transform.origin += direction * speed * delta
 
