class_name PlayerState
extends State

var player: PlayerFSM

func awake() -> void:
	player = owner as PlayerFSM
	assert(player != null)
