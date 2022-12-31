extends PlayerState

var swing_power: float = 0.1
var swing_damping: float = 0.98

var pivot_position: Vector3 = Vector3.ZERO
var pivot_axis: Vector3 = Vector3.LEFT

var length: float = 2
var gravity: float = 0.5
var current_angle: float = 0
var angle_velocity: float = 0
var angle_acceleration: float = 0
var use_rope: bool = false

var camera: GameplayCamera

func awake() -> void:
	super.awake()
	pivot_position = player.get_offset_position(0.0, 2.5)
	
func enter(params: Dictionary) -> void:
	player.animation.play("WallSlide")
	pivot_position = params.get("pivot_position", Vector3.ZERO) as Vector3
	pivot_axis = params.get("pivot_axis", Vector3.LEFT) as Vector3
	length = params.get("length", length)
	use_rope = params.get("use_rope", false)
	
	if use_rope:
		var rope_normal = player.rope.get_last_edge_info()["normal"]
		rope_normal.y = 0
		rope_normal = rope_normal.normalized()
		pivot_axis = rope_normal
	
	# TODO: This is a hacky hack to align the camera correctly.
	camera = player.get_parent().get_node("GameplayCamera") as GameplayCamera
	var yaw = rad_to_deg(pivot_axis.signed_angle_to(camera.global_transform.basis.z, Vector3.UP))
	
	camera.yaw = camera.yaw - yaw
	camera.pitch = 45
#	camera.distance = 5

# Based of the coding train video on pendulums: https://www.youtube.com/watch?v=NBWMtlbbOag
# TODO: Should some of this stuff move the physics process? It's a mess atm.
func update(delta: float) -> void:
	if use_rope:
		if not player.rope.get_last_edge_info().is_empty():
			var rope_position = player.rope.get_last_edge_info()["position"]

			pivot_position = rope_position
			length = player.global_transform.origin.distance_to(rope_position)
		else:
			state_machine.transition_to("Abseil")
	
	DebugDraw.draw_cube(pivot_position, 0.2, Color.RED)
	DebugDraw.draw_line_3d(pivot_position, pivot_position + pivot_axis, Color.WHITE)
	DebugDraw.draw_line_3d(pivot_position, pivot_position + -camera.global_transform.basis.z, Color.BLUE)
	
	var force: float = (gravity * delta) * sin(current_angle)  

	# TODO: Invert direction based on camera angle to axis normal
	force += -player.input_direction.x * swing_power * delta
	
	angle_acceleration = (-1 * force) / length
	angle_velocity += angle_acceleration
	current_angle += angle_velocity
	angle_velocity *= swing_damping

	# TODO: Not sure why I have to use a normalised Vector3.DOWN. Tutorial material?
	var end_position: Vector3 = pivot_position + (Vector3.DOWN.rotated(pivot_axis, current_angle) * length)
	
	DebugDraw.draw_line_3d(pivot_position, end_position, Color.RED)
	DebugDraw.draw_cube(end_position, 0.1, Color.CYAN)
	
	player.global_transform.origin = end_position
	
	# TODO: Add model rotation that points towards the pivot position.
	player.face_towards(pivot_position - pivot_axis)

	if player.input_direction.y < -0.5:
		length = clamp(length - 1 * delta, 0.1, 5) 

	if player.input_direction.y > 0.5:
		length = clamp(length + 1 * delta, 0.1, 5) 
	
	# TODO: Make this not a magic number.
	var jump_off_movement = pivot_axis.cross(Vector3.UP).normalized() * (-angle_velocity) * 120
	
	DebugDraw.draw_line_3d(end_position, end_position + jump_off_movement, Color.CYAN)
	
	if Input.is_action_pressed(player.get_action_name("jump")):
		return state_machine.transition_to("Jump", {
			"movement": jump_off_movement,
			"face_towards": end_position + jump_off_movement
		})
		
func physics_update(_delta: float) -> void:
#	var _collision = player.move_and_slide()
	pass
