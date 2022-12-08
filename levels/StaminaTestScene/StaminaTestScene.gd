extends Node3D

@onready var stamina: Stamina = $Stamina as Stamina

func _process(delta: float) -> void:
	if Input.is_action_pressed("grab_1"):
		stamina.use(5.0 * delta)

func _on_stamina_depleted() -> void:
	print("Depleted")
	
func _on_stamina_full() -> void:
	print("Full")
