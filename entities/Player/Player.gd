extends CharacterBody3D

@export var player_index: int = 0
@export var gravity: float = 20
@export var jump_strength: float = 8
@export var rotation_speed: float = 20
@export var walk_speed: float = 5
@export var climb_speed: float = 2
@export var state: String = "move"
@export var auto_grab_ledge: bool = false

@onready var model: Node3D = $Model
@onready var animation: AnimationPlayer = $Model/GodotRobot/AnimationPlayer

var movement: Vector3 = Vector3.ZERO
var snap_vector: Vector3 = Vector3.ZERO
var input_direction: Vector2 = Vector2.ZERO
var objects_in_possession = []

func _process(delta: float) -> void:
	DebugDraw.set_text("player " + str(player_index) + " state", state)	

	input_direction = Input.get_vector(
		"move_left_" + str(player_index),
		"move_right_" + str(player_index),
		"move_forward_" + str(player_index),
		"move_backward_" + str(player_index)
	)
	
	match state:
		"abseil_host": abseil_host_state(delta)
		"abseil_climb": abseil_climb_state(delta)
		"abseil_move": abseil_move_state(delta)
		"move": move_state(delta)
		"falling": falling_state(delta)
		"jumping": jumping_state(delta)
		"grab": grab_state(delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start_hosting_abseil_" + str(player_index)):
		print("start")
		start_hosting_abseil()
		
	if event.is_action_pressed("shout_" + str(player_index)):
		var _sfx = SFX.play_attached_to_node("voice/woman_shout_{%n}", self, {
			"volume_db": 12
		})

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
	
	DebugDraw.draw_box(position_on_rope, Vector3(0.1, 0.1, 0.1), Color.RED)
	face_towards(segment.global_transform.origin)

var distance_on_rope: float = 0	

func abseil_climb_state(_delta: float):
	animation.play_backwards("Jump")
	
	if not Input.is_action_pressed("grab_" + str(player_index)):
		objects_in_possession.clear()
		state = "move"
		return
	
	if input_direction.y < 0:
		distance_on_rope = distance_on_rope - 0.01
	if input_direction.y > 0:
		distance_on_rope = distance_on_rope + 0.01

	var head_position = objects_in_possession[0].get_position_on_rope(distance_on_rope - 1)
	var distance_to_head_position = head_position.distance_to(global_transform.origin)
	
	DebugDraw.draw_box(head_position, Vector3(0.1, 0.1, 0.1), Color.RED)
	
	global_transform.origin = objects_in_possession[0].get_position_on_rope(distance_on_rope)
	
	var _move_and_slide = move_and_slide()
	
	if is_on_floor() and distance_to_head_position < 1:
#		state = "abseil_move"
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
		state = "abseil_climb"
	
	DebugDraw.draw_box(segment.global_transform.origin, Vector3(0.1, 0.1, 0.1), Color.RED)

func grab_state(_delta):
	animation.play("WallSlide")
	
	var direction = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))

	set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap_vector`
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	var _move_and_slide = move_and_slide()
	movement = velocity
	
	var downwards_ledge_check = Raycast.cast_in_direction(
		# Position is in front and at head height of the player.
		global_transform.origin + (-global_transform.basis.z * 0.5) + (global_transform.basis.y), 
		# Cast downwards relative to the player.
		-global_transform.basis.y
	)
	
	var downwards_ledge_check_left = Raycast.cast_in_direction(
		global_transform.origin + (-global_transform.basis.z * 0.5) + (global_transform.basis.y) - (global_transform.basis.x * 0.25), 
		-global_transform.basis.y
	)
	
	var downwards_ledge_check_right = Raycast.cast_in_direction(
		global_transform.origin + (-global_transform.basis.z * 0.5) + (global_transform.basis.y) + (global_transform.basis.x * 0.25), 
		-global_transform.basis.y
	)
	
	if downwards_ledge_check:
		var forwards_wall_check = Raycast.cast_in_direction(
			# Relative to the hit position, slightly towards the player shooting into the wall and slightly below the hit position.
			downwards_ledge_check.position + (global_transform.basis.z * 0.5) + (-global_transform.basis.y * 0.3), 
			# Cast forwards relative to the player.
			-global_transform.basis.z
		)
		
		if forwards_wall_check:
			var shimmy_direction = forwards_wall_check.normal.cross(downwards_ledge_check.normal)
			var shimmy_strength = -global_transform.basis.x.dot(direction)
			var shimmy_strength_clamped = clamp(
				shimmy_strength,
				-1 if downwards_ledge_check_right else 0,
				1 if downwards_ledge_check_left else 0
			)
			var climb_up_strength = -global_transform.basis.z.dot(direction)
			
			movement = shimmy_direction * shimmy_strength_clamped
			
			global_transform.origin = forwards_wall_check.position + (forwards_wall_check.normal * 0.45)
			face_towards(forwards_wall_check.position)
			
			if climb_up_strength > 0.8:
				global_transform.origin = downwards_ledge_check.position + global_transform.basis.y
				state = "move"
			
			DebugDraw.set_text("shimmy_strength", shimmy_strength)
			DebugDraw.set_text("climb_up_strength", climb_up_strength)
			
			DebugDraw.draw_cube(downwards_ledge_check.position, 0.1, Color.RED)
			DebugDraw.draw_cube(forwards_wall_check.position, 0.1, Color.BLUE)
			DebugDraw.draw_ray_3d(forwards_wall_check.position, direction, 2, Color.GREEN)
			DebugDraw.draw_ray_3d(forwards_wall_check.position, shimmy_direction, 3, Color.BLUE)

	if Input.is_action_just_pressed("jump_" + str(player_index)):
		model.transform.origin.z = 0
		model.transform.origin.y = 0
		state = "move"
		
	if !auto_grab_ledge and !Input.is_action_pressed("grab_" + str(player_index)):
		global_transform.origin = model.global_transform.origin
		model.transform.origin.z = 0
		model.transform.origin.y = 0
		state = "falling"

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
		state = "falling"

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
		state = "jumping"
		
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
	
	Raycast.debug = true
	
	var result_down = Raycast.intersect_ray(
		global_transform.origin - global_transform.basis.z + (Vector3.UP),
		global_transform.origin - global_transform.basis.z
	)
	var result_down_2 = Raycast.intersect_ray(
		global_transform.origin - (global_transform.basis.z * 1.5) + Vector3.UP, 
		global_transform.origin - (global_transform.basis.z * 1.5)
	)
	var result_front = Raycast.intersect_ray(
		global_transform.origin + (Vector3.UP * 0.5),
		global_transform.origin + (Vector3.UP * 0.5) - global_transform.basis.z * 2
	)
	
	if (!result_down.is_empty() or !result_down_2.is_empty()) and !result_front.is_empty() and (Input.is_action_pressed("grab_" + str(player_index)) || auto_grab_ledge):
		var final_result_down = result_down if not result_down.is_empty() else result_down_2
		global_transform.origin = final_result_down.position + Vector3.UP
		look_at(global_transform.origin - result_front.normal, Vector3.UP)
		global_rotation.x = 0
		global_rotation.z = 0
		global_transform.origin = global_transform.origin + global_transform.basis.z
		global_transform.origin = global_transform.origin - (global_transform.basis.y * 1.5)
		into_jump_movement = Vector3.ZERO
		movement = Vector3.ZERO
		state = "grab"
	
	if is_on_floor() and snap_vector == Vector3.ZERO:
		into_jump_movement = Vector3.ZERO
		state = "move"

func move_state(delta: float):
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
			state = "abseil_climb"	
	
	if is_on_floor() and Input.is_action_just_pressed("jump_" + str(player_index)):
		movement.y = jump_strength / 2
		snap_vector = Vector3.ZERO
		time_in_jump_state = 0
		state = "jumping"
		
	if not is_on_floor():
		time_last_on_ground = Time.get_ticks_msec()
		state = "falling"
	
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
		state = "move"
		
func start_abseil(start_position: Vector3, rope_rotation: Vector3) -> void:
	if state == "move":
		movement = Vector3.ZERO
		global_rotation = rope_rotation
		global_transform.origin = start_position
		state = "abseil_climb"
		
func start_hosting_abseil() -> void:
	if state == "abseil_host":
		state = "move"
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
	state = "abseil_host"
	
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
