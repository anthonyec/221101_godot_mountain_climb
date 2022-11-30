extends Node3D

@onready var player_1: Node3D = $Player1
@onready var player_2: Node3D = $Player2

func _ready():
	var anim_1: AnimationPlayer = player_1.get_node("AnimationPlayer") as AnimationPlayer
	var anim_2: AnimationPlayer = player_2.get_node("AnimationPlayer") as AnimationPlayer
	
	anim_1.stop()
	anim_2.stop()
