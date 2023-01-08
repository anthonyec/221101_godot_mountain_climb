class_name GameplayCamera
extends Node3D

@export var debug: bool = false
@export var exclude_players: Array[int]

@export var distance: float = 10
@export var pitch: float = 0
@export var yaw: float = 0
@export var speed: float = 5

@onready var rig: Node3D = $"%Rig"
@onready var camera: Camera3D = $"%Camera3D"

var targets = []

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	
	for index in players.size():
		var player = players[index] as Player
		
		if exclude_players.has(player.player_number):
			continue
			
		targets.append(player)

func _process(delta: float) -> void:
	# Get the average position of all targets.
	var average_target_position: Vector3 = Vector3.ZERO
	
	for target in targets:
		average_target_position = average_target_position + target.global_transform.origin
		
	average_target_position = average_target_position / targets.size()
		
	# Moving.
	global_transform.origin = global_transform.origin.lerp(
		average_target_position, 
		delta * 10
	)
	
	# Zooming.
	camera.transform.origin.z = lerp(camera.transform.origin.z, clamp(distance, 1.0, 100.0), delta * speed)
	
	# Roation.
	global_rotation.y = lerp_angle(global_rotation.y, deg_to_rad(yaw), delta * speed)
	rig.global_rotation.x = lerp_angle(rig.global_rotation.x, deg_to_rad(-pitch), delta * speed)
	
	if debug:
		DebugDraw.set_text("distance", distance)
		DebugDraw.set_text("yaw", yaw)
		DebugDraw.set_text("pitch", pitch)

func _input(event: InputEvent) -> void:
	if event.is_action("rotate_camera_left"):
		yaw = yaw + 5
	
	if event.is_action("rotate_camera_right"):
		yaw = yaw - 5
		
	if event.is_action("rotate_camera_down"):
		pitch = pitch + 5
	
	if event.is_action("rotate_camera_up"):
		pitch = pitch - 5
		
	if event.is_action("zoom_out") and distance != 0:
		distance = distance - 1
	
	if event.is_action("zoom_in")  and distance != 100:
		distance = distance + 1
