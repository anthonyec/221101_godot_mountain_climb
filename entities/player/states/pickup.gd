extends PlayerState

func enter(params: Dictionary) -> void:
	player.animation.speed_scale = 5
	player.animation.play("Emote2")
	
	await player.animation.animation_finished
	
	if params.has("item"):
		var item = params.get("item")
		
		if not item.has_method("pick_up"):
			push_warning("Item pick does not have `pick_up` method")
			return

		item.pick_up()
		player.inventory.add_item("wood")
		
	state_machine.transition_to("Move")
	return

func exit() -> void:
	player.animation.speed_scale = 1
