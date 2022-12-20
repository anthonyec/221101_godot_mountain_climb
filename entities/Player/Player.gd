class_name Player
extends CharacterBody3D

# TODO: Find out if I need @onready annotation. Seems to work without but maybe 
# it's safer. I originally saw it in this video: https://youtu.be/8BgAeN4RRR4?t=150
@onready @export var other_player: Node

@export var player_index: int = 0
@export var gravity: float = 20
@export var jump_strength: float = 8
@export var rotation_speed: float = 20
@export var balance_speed: float = 3
@export var walk_speed: float = 5
@export var sprint_speed: float = 8
@export var climb_speed: float = 2
@export var state: String = "move"
@export var auto_grab_ledge: bool = false
@export var max_ledge_floor_angle: float = 40
@export var ledge_hang_distance_from_wall: float = 0.42
@export var ledge_grab_height: float = 1.2
@export var ledge_search_distance: float = 1
@export var sticks_collected: int = 0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var model: Node3D = $Model
@onready var animation: AnimationPlayer = $Model/GodotRobot/AnimationPlayer
@onready var pickup_collision: Area3D = $PickupArea
@onready var stamina: Stamina = $Stamina
@onready var balance: Balance = $Balance

var previous_state: String = state
var time_in_current_state: int = 0
var movement: Vector3 = Vector3.ZERO
var snap_vector: Vector3 = Vector3.ZERO
var input_direction: Vector2 = Vector2.ZERO
var objects_in_possession = []

func _process(delta: float) -> void:
	DebugDraw.set_text("player " + str(player_index) + " state", state)
	DebugDraw.set_text("player sticks " + str(player_index), sticks_collected)
	
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
		"abseil_climb_air": abseil_climb_air(delta)
		"move": move_state(delta)
		"sprint": sprint_state(delta)
		"falling": falling_state(delta)
		"jumping": jumping_state(delta)
		"grab": grab_state(delta)
		"pickup": pickup_state(delta)
		"camp": camp_state(delta)
		"holding_player": holding_player_state(delta)
		"being_held": being_held_state(delta)
		"balancing": balancing_state(delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_" + str(player_index)):
		if state == "debug":
			transition_to_state("move")
		else:
			transition_to_state("debug")
		
	if event.is_action_pressed("start_hosting_abseil_" + str(player_index)):
		start_hosting_abseil()
		
	if event.is_action_pressed("shout_" + str(player_index)):
		pass
		# Removed because I keep scaring Mao and myself
#		var _sfx = SFX.play_attached_to_node("voice/woman_shout_{%n}", self, {
#			"volume_db": 12
#		})

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
	translate(direction * 0.1)
	
	var debug_raycasting = (time_in_current_state / 1000) % 2 != 0
	DebugDraw.set_text("Raycast debugging (wait 1 sec to change)", debug_raycasting)
	Raycast.debug = debug_raycasting
	collision_shape.disabled = false
	
func holding_player_state(delta: float):
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement.x = direction.x * walk_speed / 2
	movement.z = direction.z * walk_speed / 2
	movement.y -= gravity * delta
	
	var current_facing_direction = global_transform.basis.z
	var _angle_difference = current_facing_direction.signed_angle_to((direction * -1), Vector3.UP)
	
	animation.playback_speed = 0.5
	
	if direction.length():
		animation.play("Run")
	else:
		animation.play("Idle")
		
	face_towards(global_transform.origin + direction)
	set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap_vector`
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	var _move_and_slide = move_and_slide()
	movement = velocity
	
	if !Input.is_action_pressed("grab_" + str(player_index)):
		other_player.collision_shape.disabled = false
		other_player.global_transform.origin = global_transform.origin - (global_transform.basis.z * 0.1)
		other_player.transition_to_state("move")
		transition_to_state("move")

func being_held_state(_delta: float):
	collision_shape.disabled = true
	global_transform.origin = other_player.global_transform.origin + (Vector3.UP * 1.5)
	global_rotation = other_player.global_rotation
	
	# TODO: This should use input flushing
	if time_in_current_state > 500 and Input.is_action_just_pressed("jump_" + str(player_index)):
		# TODO: This should send an event, not force the other player into a state
		other_player.transition_to_state("move")
		collision_shape.disabled = false
		movement.y = jump_strength / 2
		snap_vector = Vector3.ZERO
		time_in_jump_state = 0
		transition_to_state("jumping")
	
func camp_state(_delta: float):
	var main_camera = get_parent().get_node("GameplayCamera/Rig/Camera3D") as Camera3D
	var camp_camera = get_parent().get_node("CampingScene/Camera3D") as Camera3D
	
	if time_in_current_state < 1000:
		get_parent().get_node("Checkpoint").set_respawn_position(global_transform.origin)
		camp_camera.make_current()
	
	if time_in_current_state > 1000 and Input.is_action_just_pressed("camp_" + str(player_index)):
		get_parent().get_node("Player1").transition_to_state("move")
		get_parent().get_node("Player2").transition_to_state("move")
		
		main_camera.make_current()
		transition_to_state("move")
		return
	
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

var grabbed_rope = null
var distance_on_rope = -1

func abseil_climb_air(delta: float):
	animation.play_backwards("Jump")
#	collision_shape.disabled = true
	stamina.use(2.0 * delta)

	if !Input.is_action_pressed("grab_" + str(player_index)):
		distance_on_rope = -1
		transition_to_state("move")
		return
	
	if grabbed_rope == null:
		distance_on_rope = -1
		transition_to_state("move")
		push_warning("Failed to find rope")
		return
		
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	var position_on_rope = grabbed_rope.get_position_on_rope(distance_on_rope)
	
	var segment = grabbed_rope.get_closest_segment(position_on_rope)
	var blob: CollisionShape3D = segment.get_node("Blob")
	var sphere: SphereShape3D = blob.shape
	
#	sphere.radius = 0.8
	
	DebugDraw.draw_ray_3d(global_transform.origin, direction, 2, Color.GREEN)
	
	face_towards(grabbed_rope.global_transform.origin)
	
	# Go up the rope.
	if input_direction.y < 0:
		distance_on_rope -= 0.02
		stamina.use(10.0 * delta)
	
	# Go down the rope.
	if input_direction.y > 0:
		distance_on_rope += 0.02
		stamina.use(10.0 * delta)
		
	Raycast.cast_in_direction(global_transform.origin, -global_transform.basis.z, 1)
	
	# TODO: Ignore the rope collision itself by adding tags to each segment.
	var ground_hit = Raycast.cast_in_direction(global_transform.origin, Vector3.DOWN, 2)
	
	if ground_hit and time_in_current_state > 300 and input_direction.y > 0:
		pass
#		collision_shape.disabled = false
#		distance_on_rope = -1
#		transition_to_state("move")
	
	find_ledge_info()
	
	global_transform.origin = position_on_rope
	var _move_and_slide = move_and_slide()

func grab_state(delta):
	animation.play("WallSlide")
	collision_shape.disabled = true
	
	var direction = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	stamina.use(2.0 * delta)
	
	if stamina.is_depleted():
		collision_shape.disabled = false
		transition_to_state("falling")
		return

	set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap_vector`
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	var _move_and_slide = move_and_slide()
	movement = velocity
	
	var ledge_info = find_ledge_info()
	
#	assert(!ledge_info.is_empty(), "Cannot find ledge info") # TODO: Handle this.
	if ledge_info.is_empty():
		push_warning("Failed to find ledge info in grab state")
		collision_shape.disabled = false
		transition_to_state("move")
		return
	
	var shimmy_direction = ledge_info.edge_direction
	var shimmy_strength = -global_transform.basis.x.dot(direction)
	var shimmy_strength_clamped = clamp(
		shimmy_strength,
		## TODO: Any way to fix this so it isn't flipped round in a very unintutive way?
		-1 if !ledge_info.has_reached_right_bound else 0,
		1 if !ledge_info.has_reached_left_bound else 0,
	)
	
	stamina.use(15.0 * abs(shimmy_strength) * delta)
	
	var climb_up_strength = -global_transform.basis.z.dot(direction)
	
	movement = shimmy_direction * shimmy_strength_clamped
	
	global_transform.origin = ledge_info.hang_position
	face_towards(ledge_info.wall.position)
	
	var start_climb_up_position: Vector3 = ledge_info.floor.position + (global_transform.basis.y * 1.25) + (ledge_info.wall.normal * 0.6)
	var end_climb_up_position: Vector3 = ledge_info.floor.position + (global_transform.basis.y * 1.25) + (-ledge_info.wall.normal * 0.5)
	
	var debug_prev = Raycast.debug
	Raycast.debug = false
	# TODO: Turn iterations stuff into a Raycast helper. I think the name would be sweep. Might alreayd be build in, search ShapeSweep3D.
	var hit: Array = []
	var iterations: int = 5
	
	for index in range(0, iterations):
		var percent = float(index) / float(iterations)
		var check_position = start_climb_up_position.lerp(end_climb_up_position, percent)
		var shape_hit = Raycast.intersect_cylinder(check_position, 1.5, 0.25)
		
		if shape_hit:
			hit = shape_hit
			break
	Raycast.debug = debug_prev
	
	var climb_up_position = ledge_info.floor.position + (global_transform.basis.y)
	
	if hit.is_empty() and Raycast.debug:
		DebugDraw.draw_line_3d(global_transform.origin, climb_up_position, Color.GREEN)
		DebugDraw.draw_cube(climb_up_position, 0.5, Color.GREEN)
		
	if Raycast.debug:
		DebugDraw.draw_ray_3d(global_transform.origin, direction, 2, Color.GREEN)
	
	if climb_up_strength > 0.8 and hit.is_empty() and time_in_current_state > 200:
		global_transform.origin = climb_up_position
		collision_shape.disabled = false
		transition_to_state("move")
		
	if Input.is_action_just_pressed("jump_" + str(player_index)) and climb_up_strength < -0.4:
		model.transform.origin.z = 0
		model.transform.origin.y = 0
		collision_shape.disabled = false
		stamina.use(30.0)
		transition_to_state("move")
		
	if !auto_grab_ledge and !Input.is_action_pressed("grab_" + str(player_index)):
		global_transform.origin = model.global_transform.origin
		model.transform.origin.z = 0
		model.transform.origin.y = 0
		collision_shape.disabled = false
		transition_to_state("falling")

var into_jump_movement: Vector3 = Vector3.ZERO
var time_in_jump_state: float = 0

func jumping_state(delta: float):
	stamina.can_recover = false
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
	
	if time_in_current_state > 5000:
		push_warning("In JUMP state longer than expected")
		global_transform.origin += Vector3.UP * 2
		transition_to_state("move")
		
	if movement.y < 0:
		time_in_jump_state = 0
		transition_to_state("falling")

func find_nearest_rope():
	var ropes = get_tree().get_nodes_in_group("rope")
	var nearest_rope = null

	for rope in ropes:
		if rope.has_method("get_closest_segment"):
			var closest_segment: RigidBody3D = rope.get_closest_segment(global_transform.origin)
			var distance = closest_segment.global_transform.origin.distance_to(global_transform.origin)
			
			if distance < 2:
				nearest_rope = rope
				break
		
	return nearest_rope
	
func find_ledge_info() -> Dictionary:
	var wall_hit = Raycast.fan_out(
		global_transform.origin + (global_transform.basis.y * 0.5),
		-global_transform.basis.z, 
		ledge_search_distance,
	)
	
	if wall_hit.is_empty():
		return {}
		
	var wall_angle = wall_hit.normal.angle_to(Vector3.UP)
	
	# This is a naive check to see if walls are "wall like". It avoids glitches
	# with tilted platforms. Though ideally `intersect_cylinder` would correctly.
	# TODO: This has problems with walls that slope outwards at the bottom.
	# Might need to be a seperate kind of grab.
	if wall_angle < deg_to_rad(80) or wall_angle > deg_to_rad(120):
		return {}
		
	var direction_to_player = global_transform.origin.direction_to(Vector3(wall_hit.position.x, 0, wall_hit.position.z))
	var floor_hit = Raycast.cast_in_direction(wall_hit.position + (direction_to_player * 0.1) + (Vector3.UP * ledge_grab_height), Vector3.DOWN, ledge_grab_height)
	
	if floor_hit.is_empty():
		return {}
	
	var floor_normal: Vector3 = floor_hit.normal
	var floor_angle = abs(floor_normal.angle_to(Vector3.UP))
	
	if (floor_angle > deg_to_rad(max_ledge_floor_angle)):
		return {}

	var edge_hit = {}
	var edge_sweep_iterations = 15 # TODO: Move somewhere else
	var start_edge_sweep_position: Vector3 = floor_hit.position + floor_hit.normal
	var end_edge_sweep_position: Vector3 = floor_hit.position + floor_hit.normal + (wall_hit.normal * ledge_hang_distance_from_wall * 2)
	
	for index in edge_sweep_iterations:
		var sweep_position = start_edge_sweep_position.lerp(end_edge_sweep_position, float(index) / float(edge_sweep_iterations))
		var sweep_hit = Raycast.cast_in_direction(sweep_position, -floor_hit.normal, 1.2, [self])
		
		if sweep_hit and sweep_hit.collider != self:
			edge_hit = sweep_hit
		
		if sweep_hit.is_empty():
			break
	
	if edge_hit.is_empty():
		return {}
		
	var edge_direction = wall_hit.normal.cross(floor_hit.normal)
	
	var floor_left_bound = Raycast.cast_in_direction(
		edge_hit.position + (Vector3.UP * 0.5) + (edge_direction * 0.25), # TODO: Replace with player width / 2 var.
		Vector3.DOWN,
		ledge_search_distance
	)
	var floor_right_bound = Raycast.cast_in_direction(
		edge_hit.position + (Vector3.UP * 0.5) - (edge_direction * 0.25), # TODO: Replace with player width / 2 var.
		Vector3.DOWN,
		ledge_search_distance
	)
	
	if Raycast.debug:
		DebugDraw.draw_cube(edge_hit.position, 0.2, Color.BLUE)
		DebugDraw.draw_ray_3d(edge_hit.position - (edge_direction * 0.25), edge_direction, 0.5, Color.BLUE)
	
	var suggested_hang_position = edge_hit.position + (wall_hit.normal * ledge_hang_distance_from_wall) + (Vector3.DOWN * 0.6) # TODO: Tidy up with var name for player_height / 2
	
	# TODO: Implement exlcuding self. The last argument does not work hehe.
	# TODO: Find out why the cylinder sometimes in the same position of the ledge, which seems very wrong.
	var hang_position_hit = Raycast.intersect_cylinder(suggested_hang_position, 1.5, 0.25, [self])

	var is_hang_position_blocked = false
	
	for collision in hang_position_hit:
		if collision.collider != self:
			is_hang_position_blocked = true
			break
			
	DebugDraw.set_text("is_hang_position_blocked", is_hang_position_blocked)
	
	if is_hang_position_blocked:
		return {}
		
	var has_reached_left_bound = floor_left_bound.is_empty() or rad_to_deg(floor_left_bound.normal.angle_to(Vector3.UP)) > max_ledge_floor_angle
	var has_reached_right_bound = floor_right_bound.is_empty() or rad_to_deg(floor_right_bound.normal.angle_to(Vector3.UP)) > max_ledge_floor_angle
	
	DebugDraw.set_text("has_reached_left_bound", has_reached_left_bound)
	DebugDraw.set_text("has_reached_right_bound", has_reached_right_bound)
		
	return {
		"hang_position": suggested_hang_position,
		"floor": floor_hit,
		"wall": wall_hit,
		"edge": edge_hit,
		"edge_direction": edge_direction,
		"has_reached_left_bound": has_reached_left_bound,
		"has_reached_right_bound": has_reached_right_bound
	}

var time_last_on_ground: int = 0
var coytee_enabled: bool = true

func falling_state(delta):
	stamina.can_recover = false
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
	
	if !ledge_info.is_empty() and (Input.is_action_pressed("grab_" + str(player_index)) || auto_grab_ledge) and not stamina.is_depleted():
		global_transform.origin = ledge_info.hang_position
		into_jump_movement = Vector3.ZERO
		movement = Vector3.ZERO
		input_direction = Vector2.ZERO
		face_towards(ledge_info.wall.position)
		transition_to_state("grab")
		
	if time_in_current_state > 5000:
		push_warning("In FALLING state longer than expected")
		global_transform.origin += Vector3.UP * 2
		transition_to_state("move")

var pickup_object: Node3D = null

func pickup_state(_detla: float):
	animation.play("Emote2")
	animation.playback_speed = 5
		
	if pickup_object:
		face_towards(pickup_object.global_transform.origin)
	
	await animation.animation_finished

	if pickup_object and pickup_object.has_method("pick_up"):
		pickup_object.pick_up()
		pickup_object = null
		sticks_collected += 1
	
	transition_to_state("move")
	animation.playback_speed = 1
	# TODO: Find out why I can't do null here.
#	pickup_object = null

var sprint_let_go_from_last_use: bool = true

func sprint_state(delta: float):
	stamina.use(75.0 * delta)
	
	sprint_let_go_from_last_use = false
	time_last_on_ground = 0
	coytee_enabled = true
	
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement.x = direction.x * sprint_speed
	movement.z = direction.z * sprint_speed
	movement.y -= gravity * delta
	
	animation.play("Run")
	animation.playback_speed = 2
	
	face_towards(global_transform.origin + direction)
	set_velocity(movement)
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	
	var _move_and_slide = move_and_slide()
	movement = velocity
	
	if stamina.is_depleted():
		animation.playback_speed = 1
		transition_to_state("move")
		return
	
	if Input.is_action_just_pressed("jump_" + str(player_index)):
		movement.y = jump_strength / 2
		snap_vector = Vector3.ZERO
		time_in_jump_state = 0
		transition_to_state("jumping")
		return
	
	if !Input.is_action_pressed("sprint_" + str(player_index)):
		animation.playback_speed = 1
		sprint_let_go_from_last_use = true
		transition_to_state("move")
		return

var balance_direction: Vector3 = Vector3.RIGHT

func balancing_state(delta: float) -> void:
	animation.playback_speed = 0.2
	
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	var lean_direction = balance_direction.cross(-global_transform.basis.y)
	
	var movement_in_direction = direction.dot(balance_direction)
	var lean_in_direction = direction.dot(lean_direction)
	var general_direction = global_transform.basis.z.dot(balance_direction)
	
	movement = balance_direction * movement_in_direction * balance_speed * (1 - abs(balance.percent))
	movement.y -= gravity * delta
	
	balance.lean(-1 * lean_in_direction * 1.5)
	
	if direction.length():
		animation.play("Run")
	else:
		animation.play("Idle")

	face_towards(global_transform.origin + balance_direction * movement_in_direction)
	model.global_rotation.z = 0.5 * balance.percent * general_direction
	set_velocity(movement)
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	
	var _move_and_slide = move_and_slide()
	movement = velocity
	
	if abs(balance.percent) > 0.95:
		model.global_rotation.z = 0
		global_transform.origin += lean_direction * general_direction
		transition_to_state("move")
	
func move_state(delta: float):
	animation.playback_speed = 1
	stamina.can_recover = true
	
	# TODO: This is here just for debug purposes, to go around and look at ledges.
#	find_ledge_info()
	
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
		
	var nearest_rope = find_nearest_rope()
	
	if Raycast.debug and nearest_rope:
		DebugDraw.draw_cube(nearest_rope.global_transform.origin, 1, Color.PURPLE)
	
	if !Input.is_action_pressed("sprint_" + str(player_index)):
		sprint_let_go_from_last_use = true
		
	if Input.is_action_pressed("sprint_" + str(player_index)) and sprint_let_go_from_last_use:
		transition_to_state("sprint")
		return
	
	if nearest_rope and Input.is_action_just_pressed("grab_" + str(player_index)):
		grabbed_rope = nearest_rope
		var grabbed_segment_index = nearest_rope.get_closest_segment_index(global_transform.origin)
		distance_on_rope = nearest_rope.get_distance_on_rope_from_segment(grabbed_segment_index)
		transition_to_state("abseil_climb_air")
	
	if Input.is_action_just_pressed("jump_" + str(player_index)):
		movement.y = jump_strength / 2
		snap_vector = Vector3.ZERO
		time_in_jump_state = 0
		transition_to_state("jumping")
		
	if not is_on_floor():
		time_last_on_ground = Time.get_ticks_msec()
		transition_to_state("falling")
	
	if Input.is_action_just_pressed("grab_" + str(player_index)):
		for area in pickup_collision.get_overlapping_areas():
			if area.is_in_group("wood_pickup") and area.has_method("pick_up"):
				pickup_object = area
				transition_to_state("pickup")
				return
				
	if Input.is_action_pressed("grab_" + str(player_index)) and Input.is_action_pressed("grab_" + str(other_player.player_index)) and global_transform.origin.distance_to(other_player.global_transform.origin) < 1 and other_player.state == "move":
		DebugDraw.draw_line_3d(global_transform.origin, other_player.global_transform.origin, Color.CYAN)
		
		if Input.is_action_just_pressed("jump_" + str(player_index)):
			other_player.transition_to_state("holding_player")
			transition_to_state("being_held")
			return
				
	if Input.is_action_just_pressed("camp_" + str(player_index)):
		for area in pickup_collision.get_overlapping_areas():
			if area.get_parent().is_in_group("player"):
				var total_sticks = sticks_collected + other_player.sticks_collected
				
				if total_sticks >= 6:
					other_player.sticks_collected = 0
					sticks_collected = 0
					other_player.transition_to_state("camp")
					self.transition_to_state("camp")

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
	abseil_instance.root_node = self
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
