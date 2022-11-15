extends Node3D

func _process(delta):
	DebugDraw.set_text("Rope", "R1")
	DebugDraw.set_text("Grab", "R2")
	DebugDraw.set_text("Jump", "X")

func _input(event):
	if Input.is_key_pressed(KEY_1):
		$Player1.global_transform.origin = $DebugPosition.global_transform.origin
		$Player2.global_transform.origin = $DebugPosition.global_transform.origin + (Vector3.UP * 2)
