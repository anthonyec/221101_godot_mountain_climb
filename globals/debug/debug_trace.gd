extends Node

var enabled: bool = false
var current_step: int = 0
var steps: Array[Dictionary] = []

func startGroup() -> void:
	if not enabled:
		return
		
	steps.append({
		"type": "group_start",
	})
	
func endGroup() -> void:
	if not enabled:
		return
		
	steps.append({
		"type": "group_end",
	})
	
func step(category: String, type: String, props: Dictionary) -> void:
	if not enabled:
		return
		
	steps.append({
		"category": category,
		"type": type,
		"props": props
	})
	
func _process(delta: float) -> void:
	if enabled:
		var step_category: String
		
		if steps.size() != 0 and steps[current_step].has("category"):
			step_category = steps[current_step].category
			
		var step_count = str(current_step) + "/" + str(steps.size())
		
		DebugDraw.set_text("trace", step_category + " " + step_count)
	
	if steps.size() == 0:
		return
		
	var step = steps[current_step]
	
	if step.type == "point":
		DebugDraw.draw_cube(step.props.position, 0.1, step.props.color)
		
	if step.type == "cast":
		DebugDraw.draw_cube(step.props.start_position, 0.02, step.props.color)
		DebugDraw.draw_ray_3d(step.props.start_position, step.props.direction, step.props.length, step.props.color)
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_toggle_trace"):
		enabled = !enabled
		
		if not enabled:
			current_step = 0
			steps.clear()
		
	if Input.is_action_just_pressed("debug_left"):
		current_step = clamp(current_step - 1, 0, steps.size() - 1)
		
	if Input.is_action_just_pressed("debug_right"):
		current_step = clamp(current_step + 1, 0, steps.size() - 1)
