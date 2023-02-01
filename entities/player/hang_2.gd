extends PlayerState

var position_on_ledge: float = 0

func awake() -> void:
	super.awake()

func enter(params: Dictionary) -> void:
	Raycast.debug = true
	player.animation.play("Hang-loop_RobotArmature")
	player.collision.disabled = true
	
	# TODO: Find out why this sometimes fails.
	player.ledge.find_path()
	assert(player.ledge.path)

func exit() -> void:
	Raycast.debug = false
	player.collision.disabled = false

func physics_update(delta: float) -> void:
	position_on_ledge += player.input_direction.x * delta
	position_on_ledge = clamp(position_on_ledge, 0, player.ledge.total_length)
	
	var hang_position = player.ledge.get_position_on_ledge(position_on_ledge)
	var hang_normal = player.ledge.get_normal_on_ledge(position_on_ledge)
	
	player.global_transform.origin = hang_position + (hang_normal * 0.3) + (Vector3.DOWN * 0.15)
	player.face_towards(hang_position)
	
	DebugDraw.draw_cube(hang_position, 0.1, Color.RED)
	
