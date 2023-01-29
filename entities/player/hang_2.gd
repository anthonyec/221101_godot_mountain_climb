extends PlayerState

var search_direction: Vector3 = Vector3.ZERO

func awake() -> void:
	super.awake()

func enter(params: Dictionary) -> void:
	Raycast.debug = true
	player.animation.play("T-pose")
	search_direction = params.get("direction", Vector3.RIGHT)
	player.model.global_scale(Vector3(0.5, 0.5, 0.5))
	player.collision.disabled = true

func exit() -> void:
	Raycast.debug = false
	player.collision.disabled = false

func physics_update(delta: float) -> void:
	var ledge = player.get_ledge(search_direction)
	
	if ledge.has("error"):
		print("ledge error: ", ledge.get("error"))
		return
	
	search_direction = -ledge.normal
	player.global_transform.origin = ledge.position + (ledge.normal * 0.5) + (Vector3.DOWN * 0.1)
	
	player.face_towards(ledge.position)
	
	player.global_translate(ledge.direction * player.input_direction.x * delta)
	
	print(ledge.direction * player.input_direction.x * delta)
#	print(ledge.normal.length())
	
	
	DebugDraw.draw_cube(ledge.position, 0.1, Color.RED)
	DebugDraw.draw_ray_3d(ledge.position, ledge.direction, 1, Color.GREEN)
	
