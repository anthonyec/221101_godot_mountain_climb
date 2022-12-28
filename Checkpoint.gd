class_name Checkpoint
extends Node

var respawn_position: Vector3 = Vector3(-25, 2, 2)

func set_respawn_position(new_respawn_position: Vector3):
	respawn_position = new_respawn_position

func respawn():
	print("respawn")
	get_parent().get_node("Player1").global_transform.origin = respawn_position
	get_parent().get_node("Player2").global_transform.origin = respawn_position + Vector3.RIGHT * 0.5

func _input(event):
	if event.is_action_pressed("respawn_1") or event.is_action_pressed("respawn_2"):
		respawn()
