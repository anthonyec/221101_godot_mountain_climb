extends Area3D

@export var gameplay_camera: Node3D
@export var distance: float = 10
@export var pitch: float = 45
@export var yaw: float = -90

var original_distance: float = 0
var original_pitch: float = 0
var original_yaw: float = 0

func _ready():
	pass

func _process(delta):
	pass

func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	original_distance = gameplay_camera.distance
	original_pitch = gameplay_camera.pitch
	original_yaw = gameplay_camera.yaw
	
	gameplay_camera.distance = distance
	gameplay_camera.pitch = pitch
	gameplay_camera.yaw = yaw

func _on_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	gameplay_camera.distance = original_distance
	gameplay_camera.pitch = original_pitch
	gameplay_camera.yaw = original_yaw
