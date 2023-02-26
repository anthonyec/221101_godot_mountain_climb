extends Node

var enabled: bool = false
var current_step: int = 0
var steps: Array[Dictionary] = []
var group_opened: bool = false

func startGroup() -> void:
	if not enabled:
		return
		
	group_opened = true
		
	steps.append({
		"type": "group_start",
		"steps": []
	})
	
func endGroup() -> void:
	if not enabled:
		return
	
	group_opened = false
	
func step(category: String, type: String, props: Dictionary) -> void:
	if not enabled:
		return
	
	var last_step = null if steps.is_empty() else steps.back()
	var step_data = {
		"category": category,
		"type": type,
		"props": props
	}
	
	if group_opened and last_step.has("type") and last_step.type == "group_start":
		last_step.steps.append(step_data)
	else:
		steps.append(step_data)
		
func log(title: String, metadata: Dictionary) -> void:
	step(title, "log", metadata)
	
func point(title: String, point_position: Vector3, color: Color = Color.RED) -> void:
	step(title, "point", {
		"position": point_position,
		"color": color
	})

func render_step(step) -> void:
	if step.type == "point":
		DebugDraw.draw_cube(step.props.position, 0.1, step.props.color)
		
	if step.type == "cast":
		DebugDraw.draw_cube(step.props.position, 0.02, step.props.color)
		DebugDraw.draw_ray_3d(step.props.position, step.props.direction, step.props.length, step.props.color)
		
	if step.type == "log":
		var message = ""
		
		message += "#" + str(current_step) + " " + step.category + "\n"
		
		for key in step.props.keys():
			var value = step.props[key]
			
			if not value is Dictionary:
				message += key + ": " + str(value)
				message += "\n"
				
			if value is Dictionary:
				message += key + ": "
				message += "\n"
				
				for dictionary_key in value.keys():
					var dictionary_value = value[dictionary_key]
					
					message += "  " + dictionary_key + ": " + str(dictionary_value)
					message += "\n"
				message += "\n"
		
		Debug.show_message(message)

func _process(_delta: float) -> void:
	if enabled:
		var step_category: String
		
		if steps.size() != 0 and steps[current_step].has("category"):
			step_category = steps[current_step].category
			
		var step_count = str(current_step) + "/" + str(steps.size())
		
		DebugDraw.set_text("trace", step_category + " " + step_count)
	
	if steps.size() == 0:
		return
		
	var step = steps[current_step]
	
	if step.type == "group_start":
		for sub_step in step.steps:
			render_step(sub_step)
	else:
		render_step(step)

	
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_toggle_trace"):
		enabled = !enabled
		
		Debug.notify("Recording trace: " + str(enabled))
		
		if not enabled:
			current_step = 0
			steps.clear()
		
	if Input.is_action_just_pressed("debug_left"):
		current_step = clamp(current_step - 1, -1, steps.size() - 1)
		
	if Input.is_action_just_pressed("debug_right"):
		current_step = clamp(current_step + 1, 0, steps.size() - 1)
