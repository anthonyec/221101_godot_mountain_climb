class_name PlayerState
extends State

var player: Player

func awake() -> void:
	player = owner as Player
	assert(player != null)
