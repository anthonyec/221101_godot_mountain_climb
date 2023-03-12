extends Node3D

func _input(event):
	if Input.is_key_pressed(KEY_0):
		if Engine.time_scale == 0.05:
			Engine.time_scale = 1
		else:
			Engine.time_scale = 0.05
	if Input.is_key_pressed(KEY_1):
		$Player1.global_transform.origin = $DebugPosition.global_transform.origin
		$Player2.global_transform.origin = $DebugPosition.global_transform.origin + (Vector3.UP * 2)
