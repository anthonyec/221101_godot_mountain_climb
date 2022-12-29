extends PlayerState

var main_camera: Camera3D
var camp_camera: Camera3D
var checkpoint: Checkpoint

func awake() -> void:
	super.awake()
	
	main_camera = player.get_parent().get_node_or_null("GameplayCamera/Rig/Camera3D") as Camera3D
	camp_camera = player.get_parent().get_node_or_null("CampingScene/Camera3D") as Camera3D
	checkpoint = player.get_parent().get_node_or_null("Checkpoint") as Checkpoint

func enter(_params: Dictionary) -> void:
	assert(main_camera)
	assert(camp_camera)
	assert(checkpoint)
	
	# TODO: Change this to either the position between both players or nearest 
	# checkpoint marker (would need to make this feature).
	checkpoint.set_respawn_position(player.global_transform.origin)
	camp_camera.make_current()
	
	player.companion.inventory.clear_item("wood")
	player.inventory.clear_item("wood")

func exit() -> void:
	main_camera.make_current()
	
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(player.get_action_name("camp")):
		if state_machine.time_in_current_state < 1000:
			return
			
		state_machine.transition_to("Move")
		
		# TODO: Probably should change to event based instead of forcing the 
		# state but oh well.
		player.companion.state_machine.transition_to("Move")
