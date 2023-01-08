extends PlayerState

func enter(params: Dictionary) -> void:
	player.animation.playback_speed = 5
	player.animation.play("Emote2")
	
	await player.animation.animation_finished
	
	if params.has("item"):
		var item = params.get("item")
		
		if not item.has_method("pick_up"):
			return push_warning("Item pick does not have `pick_up` method")

		item.pick_up()
		player.inventory.add_item("wood")
		
	return state_machine.transition_to("Move")

func exit() -> void:
	player.animation.playback_speed = 1
