extends PlayerState

@onready var abseil_rope_scene: PackedScene = preload("res://entities/abseil_rope/abseil_rope.tscn")

var abseil_rope: AbseilRope

func enter(params: Dictionary) -> void:
	player.animation.speed_scale = 5
	player.animation.play("Emote2")
	
	await player.animation.animation_finished
	
	abseil_rope = abseil_rope_scene.instantiate() as AbseilRope
	
	abseil_rope.host = player
	abseil_rope.global_transform.origin = player.global_transform.origin
	
	player.get_parent().add_child(abseil_rope)
	
	player.inventory.use_item("abseil_rope")
	state_machine.transition_to("Move")

func exit() -> void:
	player.animation.speed_scale = 1
