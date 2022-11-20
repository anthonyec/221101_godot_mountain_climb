extends CharacterBody3D

@export var player_index: int = 0
@export var gravity: float = 20
@export var jump_strength: float = 8
@export var rotation_speed: float = 20
@export var walk_speed: float = 5
@export var climb_speed: float = 2
@export var state: String = "move"
@export var auto_grab_ledge: bool = false
@export var max_ledge_floor_angle: float = 40
@export var ledge_hang_distance_from_wall: float = 0.45
@export var ledge_grab_height: float = 1.2
@export var ledge_search_distance: float = 1

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var model: Node3D = $Model
@onready var animation: AnimationPlayer = $Model/GodotRobot/AnimationPlayer

var previous_state: String = state
var time_in_current_state: int = 0
var movement: Vector3 = Vector3.ZERO
var snap_vector: Vector3 = Vector3.ZERO
var input_direction: Vector2 = Vector2.ZERO
var objects_in_possession = []

func _process(delta: float) -> void:
	DebugDraw.set_text("player " + str(player_index) + " state", state)
	
	time_in_current_state += int(delta * 1000)

	input_direction = Input.get_vector(
		"move_left_" + str(player_index),
		"move_right_" + str(player_index),
		"move_forward_" + str(player_index),
		"move_backward_" + str(player_index)
	)
	
	match state:
		"debug": debug_state(delta)
		"abseil_host": abseil_host_state(delta)
		"abseil_climb": abseil_climb_state(delta)
		"abseil_move": abseil_move_state(delta)
		"move": move_state(delta)
		"falling": falling_state(delta)
		"jumping": jumping_state(delta)
		"grab": grab_state(delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_" + str(player_index)):
		if state == "debug":
			transition_to_state("move")
		else:
			transition_to_state("debug")
		
	if event.is_action_pressed("start_hosting_abseil_" + str(player_index)):
		print("start")
		start_hosting_abseil()
		
	if event.is_action_pressed("shout_" + str(player_index)):
		var _sfx = SFX.play_attached_to_node("voice/woman_shout_{%n}", self, {
			"volume_db": 12
		})

func transition_to_state(new_state: String):
	time_in_current_state = 0
	previous_state = state
	state = new_state

func debug_state(delta: float):
	var input = Vector3(input_direction.x, 0, input_direction.y)
	
	if Input.is_action_pressed("jump_" + str(player_index)):
		input.y = -input.z
		input.z = 0
		input.x = 0
		
	var direction: Vector3 = transform_direction_to_camera_angle(input)
	
	movement = Vector3.ZERO
	translate(direction / 10)
	
	var debug_raycasting = (time_in_current_state / 1000) % 2 != 0
	DebugDraw.set_text("Raycast debugging (wait 1 sec to change)", debug_raycasting)
	Raycast.debug = debug_raycasting
	
func abseil_host_state(delta: float):
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement.x = direction.x * walk_speed
	movement.z = direction.z * walk_speed
	movement.y -= gravity * delta
	
	if direction.length():
		animation.play_backwards("Run")
	else:
		animation.play("Idle")
	
	set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap_vector`
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	var _move_and_slide = move_and_slide()
	movement = velocity
	
	var segment: RigidBody3D = objects_in_possession[0].get_middle_segment()
	var position_on_rope = objects_in_possession[0].get_position_on_rope(2)
	
	if Raycast.debug:
		DebugDraw.draw_box(position_on_rope, Vector3(0.1, 0.1, 0.1), Color.RED)
		
	face_towards(segment.global_transform.origin)

var distance_on_rope: float = 0	

func abseil_climb_state(_delta: float):
	animation.play_backwards("Jump")
	
	if not Input.is_action_pressed("grab_" + str(player_index)):
		objects_in_possession.clear()
		transition_to_state("move")
		return
	
	if input_direction.y < 0:
		distance_on_rope = distance_on_rope - 0.01
	if input_direction.y > 0:
		distance_on_rope = distance_on_rope + 0.01

	var head_position = objects_in_possession[0].get_position_on_rope(distance_on_rope - 1)
	var distance_to_head_position = head_position.distance_to(global_transform.origin)
	
	if Raycast.debug:
		DebugDraw.draw_box(head_position, Vector3(0.1, 0.1, 0.1), Color.RED)
	
	global_transform.origin = objects_in_possession[0].get_position_on_rope(distance_on_rope)
	
	var _move_and_slide = move_and_slide()
	
	if is_on_floor() and distance_to_head_position < 1:
#		transition_to_state(abseil_move")
		pass

func abseil_move_state(delta):
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))

	movement.x = direction.x * walk_speed
	movement.z = direction.z * walk_speed
	movement.y -= gravity * delta
	
	set_velocity(movement)
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	
	var _move_and_slide = move_and_slide()
	
	if input_direction.y < 0:
		distance_on_rope = distance_on_rope - 0.01
	if input_direction.y > 0:
		distance_on_rope = distance_on_rope + 0.01
	
	var head_position = objects_in_possession[0].get_position_on_rope(distance_on_rope - 1)
	var distance_to_head_position = head_position.distance_to(global_transform.origin)
	var segment: RigidBody3D = objects_in_possession[0].get_closest_segment(global_transform.origin)
	
	if distance_to_head_position > 1.5:
		transition_to_state("abseil_climb")
	
	if Raycast.debug:
		DebugDraw.draw_box(segment.global_transform.origin, Vector3(0.1, 0.1, 0.1), Color.RED)

func grab_state(_delta):
	animation.play("WallSlide")
	
	print(time_in_current_state)
	
	var direction = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))

	set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap_vector`
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	var _move_and_slide = move_and_slide()
	movement = velocity
	
	var ledge_info = find_ledge_info()
	
#	assert(!ledge_info.is_empty(), "Cannot find ledge info") # TODO: Handle this.
	if ledge_info.is_empty():
		print("Failed to find ledge info in grab state")
		transition_to_state("move")
		return
	
	var ledge_check_left = Raycast.cast_in_direction(
		ledge_info.floor.position + (Vector3.UP * 0.5) - (global_transform.basis.x * 0.25), # TODO: Replace with player width / 2 var.
		-global_transform.basis.y,
		1.2
	)
	
	var ledge_check_right = Raycast.cast_in_direction(
		ledge_info.floor.position + (Vector3.UP * 0.5) + (global_transform.basis.x * 0.25), # TODO: Replace with player width / 2 var.
		-global_transform.basis.y,
		1.2
	)
	
	var shimmy_direction = ledge_info.wall.normal.cross(ledge_info.floor.normal)
	var shimmy_strength = -global_transform.basis.x.dot(direction)
	var shimmy_strength_clamped = clamp(
		shimmy_strength,
		-1 if ledge_check_right else 0,
		1 if ledge_check_left else 0
	)
	var climb_up_strength = -global_transform.basis.z.dot(direction)
	
	movement = shimmy_direction * shimmy_strength_clamped
	
	global_transform.origin = ledge_info.hang_position
	face_towards(ledge_info.wall.position)
	
	var start_climb_up_position: Vector3 = ledge_info.floor.position + (global_transform.basis.y * 1.25) + (ledge_info.wall.normal * 0.6)
	var end_climb_up_position: Vector3 = ledge_info.floor.position + (global_transform.basis.y * 1.25) + (-ledge_info.wall.normal * 0.5)
	
	# TODO: Turn iterations stuff into a Raycast helper. Not sure what the name would be?
	var hit: Array = []
	var iterations: int = 5
	
	for index in range(0, iterations):
		var percent = float(index) / float(iterations)
		var check_position = start_climb_up_position.lerp(end_climb_up_position, percent)
		var shape_hit = Raycast.intersect_cylinder(check_position, 1.5, 0.25)
		
		if shape_hit:
			hit = shape_hit
			break
	
	var climb_up_position = ledge_info.floor.position + (global_transform.basis.y) + (-ledge_info.wall.normal * 0.5)
	
	if hit.is_empty() and Raycast.debug:
		DebugDraw.draw_line_3d(global_transform.origin, climb_up_position, Color.GREEN)
		DebugDraw.draw_cube(climb_up_position, 0.5, Color.GREEN)
		
	if Raycast.debug:
		DebugDraw.draw_ray_3d(global_transform.origin, direction, 2, Color.GREEN)
	
	if climb_up_strength > 0.8 and hit.is_empty() and time_in_current_state > 200:
		global_transform.origin = climb_up_position
		transition_to_state("move")
		
	if Input.is_action_just_pressed("jump_" + str(player_index)) and climb_up_strength < -0.5:
		model.transform.origin.z = 0
		model.transform.origin.y = 0
		transition_to_state("move")
		
	if !auto_grab_ledge and !Input.is_action_pressed("grab_" + str(player_index)):
		global_transform.origin = model.global_transform.origin
		model.transform.origin.z = 0
		model.transform.origin.y = 0
		transition_to_state("falling")

var into_jump_movement: Vector3 = Vector3.ZERO
var time_in_jump_state: float = 0

func jumping_state(delta: float):
	animation.play("Jump")
	
	if into_jump_movement == Vector3.ZERO:
		into_jump_movement = movement * 1.2
	
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	time_in_jump_state += delta
	
	if time_in_jump_state < 0.2 and Input.is_action_pressed("jump_" + str(player_index)):
		movement.y += 0.35
	
	movement.x = into_jump_movement.x + direction.x
	movement.z = into_jump_movement.z + direction.z
	movement.y -= gravity * delta
	set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap_vector`
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	var _move_and_slide = move_and_slide()
	movement = velocity
		
	if movement.y < 0:
		time_in_jump_state = 0
		transition_to_state("falling")

func find_ledge_info() -> Dictionary:
	var wall_hit = Raycast.fan_out(
		global_transform.origin + (global_transform.basis.y * 0.5),
		-global_transform.basis.z, 
		ledge_search_distance,
	)
	
	if wall_hit:
		var direction_to_player = global_transform.origin.direction_to(Vector3(wall_hit.position.x, 0, wall_hit.position.z))
		var floor_hit = Raycast.cast_in_direction(wall_hit.position + (direction_to_player * 0.1) + (Vector3.UP * ledge_grab_height), Vector3.DOWN, ledge_grab_height)
		
		if floor_hit.is_empty():
			return {}
			
		var floor_normal: Vector3 = floor_hit.normal
		var floor_angle = abs(floor_normal.angle_to(Vector3.UP))
		
		if (floor_angle > deg_to_rad(max_ledge_floor_angle)):
			return {}
		
		var suggested_hang_position = floor_hit.position + (wall_hit.normal * ledge_hang_distance_from_wall) + (Vector3.DOWN * 0.75) # TODO: Tidy up 0.75 with var name for player_height / 2
		
		# TODO: Implement exlcuding self. The last argument does not work hehe.
		var hang_position_hit = Raycast.intersect_cylinder(suggested_hang_position, 1.5, 0.25, [self])

		var is_hang_position_blocked = false
		
		for collision in hang_position_hit:
			if collision.collider != self:
				is_hang_position_blocked = true

		if not is_hang_position_blocked:
			return {
				"hang_position": suggested_hang_position,
				"floor": floor_hit,
				"wall": wall_hit
			}
			
	return {}

var time_last_on_ground: int = 0
var coytee_enabled: bool = true

func falling_state(delta):
	animation.play("Fall")
	
	if into_jump_movement == Vector3.ZERO:
		into_jump_movement = movement
	
	if coytee_enabled and (Time.get_ticks_msec() - time_last_on_ground) < 150 and Input.is_action_pressed("jump_" + str(player_index)):
		coytee_enabled = false
		movement.y = jump_strength / 2
		snap_vector = Vector3.ZERO
		time_in_jump_state = 0
		transition_to_state("jumping")
		
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement.x = into_jump_movement.x + direction.x
	movement.z = into_jump_movement.z + direction.z
	movement.y -= (gravity * 2) * delta
	set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap_vector`
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	var _move_and_slide = move_and_slide()
	movement = velocity
	
	if is_on_floor() and snap_vector == Vector3.ZERO:
		into_jump_movement = Vector3.ZERO
		transition_to_state("move")
		
	var ledge_info = find_ledge_info()
	
	if !ledge_info.is_empty() and ledge_info.hang_position != null and (Input.is_action_pressed("grab_" + str(player_index)) || auto_grab_ledge):
		global_transform.origin = ledge_info.hang_position
		into_jump_movement = Vector3.ZERO
		movement = Vector3.ZERO
		input_direction = Vector2.ZERO
		face_towards(ledge_info.wall.position)
		transition_to_state("grab")

func move_state(delta: float):
	find_ledge_info()
	
	time_last_on_ground = 0
	coytee_enabled = true
	
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement.x = direction.x * walk_speed
	movement.z = direction.z * walk_speed
	movement.y -= gravity * delta
	
	var current_facing_direction = global_transform.basis.z
	var _angle_difference = current_facing_direction.signed_angle_to((direction * -1), Vector3.UP)
	
	if direction.length():
		animation.play("Run")
	else:
		animation.play("Idle")
		
	if Input.is_action_just_pressed("grab_" + str(player_index)):
		var rope = get_parent().get_node_or_null("Rope")
		
		if rope == null:
			return
			
		var segment = rope.get_closest_segment(global_transform.origin)
		var segment_index = rope.get_closest_segment_index(global_transform.origin)
		
		if segment.global_transform.origin.distance_to(global_transform.origin) < 2:
			var distance = rope.get_distance_on_rope_from_segment(segment_index)
			
			distance_on_rope = distance
			objects_in_possession.append(rope)
			transition_to_state("abseil_climb"	)
	
	if is_on_floor() and Input.is_action_just_pressed("jump_" + str(player_index)):
		movement.y = jump_strength / 2
		snap_vector = Vector3.ZERO
		time_in_jump_state = 0
		transition_to_state("jumping")
		
	if not is_on_floor():
		time_last_on_ground = Time.get_ticks_msec()
		transition_to_state("falling")
	
	face_towards(global_transform.origin + direction)
	set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap_vector`
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	var _move_and_slide = move_and_slide()
	movement = velocity

func end_abseil(end_position: Vector3) -> void:
	if state == "abseil_climb":
		global_transform.origin = end_position
		transition_to_state("move")
		
func start_abseil(start_position: Vector3, rope_rotation: Vector3) -> void:
	if state == "move":
		movement = Vector3.ZERO
		global_rotation = rope_rotation
		global_transform.origin = start_position
		transition_to_state("abseil_climb")
		
func start_hosting_abseil() -> void:
	if state == "abseil_host":
		transition_to_state("move")
		remove_objects_in_posession()
		return
	
	if state != "move" or !is_on_floor():
		return
	
	
	var abseil = load("res://entities/Rope/Rope.tscn")
	var abseil_instance: Node3D = abseil.instantiate()
	
	abseil_instance.name = "Rope"
	abseil_instance.global_rotation = global_rotation
	abseil_instance.root_attachment = get_path()
	get_parent().add_child(abseil_instance)
	
	abseil_instance.global_transform.origin = global_transform.origin
	
	objects_in_possession.append(abseil_instance)
	transition_to_state("abseil_host")
	
func remove_objects_in_posession() -> void:
	for index in objects_in_possession.size():
		var object = objects_in_possession[index]
		
		object.queue_free()
		objects_in_possession.remove_at(index)

# Get the active cameras global Y axis rotation and use that to rotate the
# direction vector.
func transform_direction_to_camera_angle(direction: Vector3) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var camera_angle_y = camera.global_transform.basis.get_euler().y

	return direction.rotated(Vector3.UP, camera_angle_y)

func face_towards(target: Vector3) -> void:
	if global_transform.origin == target:
		return
		
	look_at(target, Vector3.UP)
	global_rotation.x = 0
	global_rotation.z = 0
