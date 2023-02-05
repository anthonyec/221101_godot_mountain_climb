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
	DebugDraw.set_text("min_length", player.ledge.min_length)
	DebugDraw.set_text("max_length", player.ledge.max_length)
	DebugDraw.set_text("position_on_ledge", position_on_ledge)
	DebugDraw.set_text("length_from_min_max", player.ledge.max_length - player.ledge.min_length)
	DebugDraw.set_text("length_from_calc", Utils.get_path_length(player.ledge.path))
	
	position_on_ledge += player.input_direction.x * delta
	position_on_ledge = clamp(position_on_ledge, player.ledge.min_length, player.ledge.max_length)
	
	var hang_position = player.ledge.get_position_on_ledge(position_on_ledge)
	var _hang_normal = player.ledge.get_normal_on_ledge(position_on_ledge)
	
	# TODO: Get normal from path rather than finding a ledge each frame :).
	var ledge_info = player.ledge.get_ledge_info(player.global_transform.origin, -player.global_transform.basis.z)
	
	if ledge_info.has("error"):
		ledge_info.normal = Vector3.RIGHT
	
	player.global_transform.origin = hang_position + (ledge_info.normal * 0.3) + (Vector3.DOWN * 0.15)
	player.face_towards(hang_position)
	
	DebugDraw.draw_cube(hang_position, 0.1, Color.RED)
	
func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == 78 and event.pressed:
		player.ledge.find_path(-1)
		
	if event is InputEventKey and event.keycode == 77 and event.pressed:
		player.ledge.find_path(1)
