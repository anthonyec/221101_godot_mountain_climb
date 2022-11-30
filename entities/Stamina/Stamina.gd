extends Node

signal stamina_depleted
signal stamina_full

@export var loss_per_second: float = 2.0
@export var gain_per_second: float = 5.0
@export var max_stamina: float = 100.0

var current_amount: float = 100.0

func _process(_delta):
	DebugDraw.set_text("stamina_" + str(get_parent().get_instance_id()), current_amount)

func use(amount: float = 1.0):
	current_amount = clamp(current_amount - amount, 0, max_stamina)
	
func regain(amount: float = 1.0):
	current_amount = clamp(current_amount + amount, 0, max_stamina)

