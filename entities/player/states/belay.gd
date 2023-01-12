extends PlayerState

@onready var abseil_rope_scene: PackedScene = preload("res://entities/abseil_rope/abseil_rope.tscn")

var abseil_rope: AbseilRope

func enter(_params: Dictionary) -> void:
	player.animation.play("Idle")
	
	abseil_rope = abseil_rope_scene.instantiate() as AbseilRope
	
	abseil_rope.host = player
	abseil_rope.global_transform.origin = player.global_transform.origin
	
	player.get_parent().add_child(abseil_rope)
	
	abseil_rope.throw()
	
func exit() -> void:
	player.get_parent().remove_child(abseil_rope)

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(player.get_action_name("start_hosting_abseil")):
		state_machine.transition_to("Move")
		return
