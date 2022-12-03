class_name StateMachine
extends Node

var previous_state: State
var current_state: State

func _ready() -> void:
	await owner.ready
	
	assert(get_child_count(), "No states provided as children")
		
	for child in get_children():
		if not (child is State):
			continue
			
		child.state_machine = self
			
		if child.has_method("awake"):
			child.awake()
	
	var initial_state: State = get_child(0)
	transition_to(initial_state.name)

func _input(event: InputEvent) -> void:
	current_state.handle_input(event)

func _process(delta: float) -> void:
	current_state.update(delta)

func _physics_process(delta: float) -> void:
	current_state.physics_update(delta)

func transition_to(state_name: String, params: Dictionary = {}) -> void:
	var next_state = get_node_or_null(state_name)
	
	assert(next_state, "No state found with the name '" + state_name + "'")
	
	previous_state = current_state
	
	if current_state:
		current_state.exit()
	
	current_state = next_state
	current_state.enter(params)

func transition_to_previous_state() -> void:
	transition_to(previous_state.name)
