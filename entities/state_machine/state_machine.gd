class_name StateMachine
extends Node

signal state_changed(previous_state: State, next_state: State, params: Dictionary)

var previous_state: State
var current_state: State
var current_parent_state: State
var time_in_current_state: int

func _ready() -> void:
	await owner.ready
	
	assert(get_child_count(), "No states provided as children")
	
	# Recursively setup child and sub-child state.
	setup_child_states(self)
	
	var initial_state: State = get_child(0)
	transition_to(initial_state.name)

func _input(event: InputEvent) -> void:
	if current_parent_state:
		current_parent_state.handle_input(event)
		
	current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_parent_state:
		current_parent_state.update(delta)
		
	current_state.update(delta)
	
	# TODO: Is the correct way to time stuff or should there be another unit
	# based on frames? What happens if there's a low frame-rate?
	time_in_current_state += int(delta * 1000)

func _physics_process(delta: float) -> void:
	if current_parent_state:
		current_parent_state.physics_update(delta)
		
	current_state.physics_update(delta)
	
func setup_child_states(node: Node, has_parent_state: bool = false, depth: int = 0) -> void:
	assert(depth <= 2, "Only 1 level of nested states is supported. Move '" + str(node.name) + "' up a level")
	
	for child in node.get_children():
		if not (child is State):
			continue
			
		child.state_machine = self
		child.parent_state = node if has_parent_state else null 
		child.awake()
		
		setup_child_states(child, true, depth + 1)

func transition_to(state_name: String, params: Dictionary = {}) -> void:
	var next_state: State = get_node_or_null(state_name) as State
	assert(next_state, "No state found with the name '" + state_name + "'")
	
	# If the next state is a parent of many states, transition to the first sub-state.
	if next_state.get_child_count() > 0:
		next_state = next_state.get_child(0)
	
	var is_different_parent_state = current_parent_state != next_state.parent_state
	
	previous_state = current_state
	
	if current_state:
		current_state.exit()
	
	if is_different_parent_state and current_parent_state:
		current_parent_state.exit()
		
	current_parent_state = next_state.parent_state
	current_state = next_state
	
	if is_different_parent_state and current_parent_state:
		current_parent_state.enter(params)
	
	current_state.enter(params)
	time_in_current_state = 0
	state_changed.emit(previous_state, current_state, params)

func transition_to_previous_state() -> void:
	transition_to(previous_state.name)
	
func get_current_state_path() -> String:
	var path: String = ""
	
	if current_parent_state:
		path += current_parent_state.name + "/"
		
	path += current_state.name
	
	return path
