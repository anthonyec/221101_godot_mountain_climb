extends Node3D

@onready var player_1: Player = $Player1 as Player
@onready var player_2: Player = $Player2 as Player

func _ready():
	player_1.state_machine.transition_to("Debug", { "disabled": true })
	player_2.state_machine.transition_to("Debug", { "disabled": true })
	
	player_1.animation.playback_speed = 0 
	player_2.animation.playback_speed = 0 

	player_1.animation.play("Fall2")
	player_2.animation.play("Dive")

	player_1.animation.seek(0.4)


