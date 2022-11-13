extends Node3D

@onready var rope: Node3D = $Rope

@export var increment_size: float = 0.01

var current_distance: float = 7.49
var direction: int = 1

func _ready():
	print("length: ", rope.total_length)

func _process(delta):
	var position_on_rope = rope.get_position_on_rope(current_distance)
	
	DebugDraw.draw_cube(position_on_rope, 0.1, Color.RED)
	
	current_distance += increment_size * direction
	
	if current_distance > rope.total_length or current_distance < 0:
		direction *= -1

func _input(event):
	if event.is_action("move_forward_1"):
		current_distance -= increment_size
	
	if event.is_action("move_backward_1"):
		current_distance += increment_size
