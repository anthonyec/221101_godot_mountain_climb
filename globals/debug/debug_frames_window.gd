extends Window

@onready var tree: Tree = %Tree
@onready var frame_slider: HSlider = %FrameSlider
@onready var frame_spin_box: SpinBox = %FrameSpinBox
@onready var record_button: Button = %RecordButton
@onready var reset_button: Button = %ResetButton
@onready var play_button: Button = %PlayButton
@onready var graph_panels: VBoxContainer = %GraphPanels
@onready var graph_panel: Panel = %GraphPanel
@onready var window: Window = %Window
@onready var pause_graphs_button: Button = $MarginContainer/TabContainer/Graphs/MenuBar/PauseGraphsButton

var is_playing: bool = false
var current_frame: int = 0
var current_frame_callables: Array[Callable] = []
var min_frame: int = 0
var max_frame: int = DebugFrames.max_recording_size

func _ready() -> void:
	frame_slider.connect("value_changed", slider_changed)
	frame_spin_box.connect("value_changed", spin_box_changed)
	reset_button.connect("button_up", _on_reset_button_up)
	record_button.connect("toggled", _on_recording_toggle_toggled)
	play_button.connect("button_up", _on_play_button_up)
	pause_graphs_button.connect("button_up", _on_pause_graph_button_up)
	
	DebugFrames.connect("resized", frames_resized)
	DebugFrames.connect("added", frames_added)
	DebugGraph.connect("added", _on_graph_added)
	
	frames_resized(min_frame, max_frame)
	
func _process(_delta: float) -> void:
	for callable in current_frame_callables:
		callable.call()
		
	if is_playing:
		frame_slider.value += 1

func set_item_title_and_meta(item: TreeItem, key: String, value: Variant, path: String) -> void:
	item.set_text(0, str(key))
	
	if typeof(value) != TYPE_ARRAY and typeof(value) != TYPE_DICTIONARY:
		item.set_text(1, str(value))
	
	item.set_metadata(0, path)
	item.set_metadata(1, value)
	
	item.set_tooltip_text(0, path)

func render_sub_tree(target_tree: Tree, parent_item: TreeItem, data: Dictionary) -> void:
	for key in data:
		if key == DebugFrames.TITLE_KEY:
			continue
			
		assert(parent_item.get_metadata(0) != null, "Item path cannot be null")
		
		var path = str(parent_item.get_metadata(0)) + "." + key.to_snake_case()
		var value = data[key]
		
		if typeof(value) == TYPE_CALLABLE:
			current_frame_callables.append(value)
			continue
		
		if typeof(value) == TYPE_ARRAY:
			var sub_item = target_tree.create_item(parent_item)
			set_item_title_and_meta(sub_item, key, value, path)
			
			if value.is_empty():
				var empty_item = target_tree.create_item(sub_item)
				empty_item.set_text(0, "<empty>")
			else:
				var dictionary_from_array = {}
				
				for index in value.size():
					dictionary_from_array[str(index)] = value[index]
					
				render_sub_tree(target_tree, sub_item, dictionary_from_array)
				
			continue
		
		if typeof(value) == TYPE_DICTIONARY:
			var sub_item = target_tree.create_item(parent_item)
			set_item_title_and_meta(sub_item, key, value, path)
			
			if value.is_empty():
				var empty_item = target_tree.create_item(sub_item)
				empty_item.set_text(0, "<empty>")
			else:
				render_sub_tree(target_tree, sub_item, value)
				
			continue
		
		var sub_item = target_tree.create_item(parent_item)
		set_item_title_and_meta(sub_item, key, value, path)

func render() -> void:
	play_button.disabled = DebugFrames.is_recording
	reset_button.disabled = is_playing or DebugFrames.is_recording
	record_button.disabled = is_playing
	record_button.button_pressed = DebugFrames.is_recording
	
	play_button.text = "Stop" if is_playing else "Play"
	
	current_frame_callables = []
	tree.clear()
	
	var root: TreeItem = tree.create_item()
	tree.hide_root = true
	
	if not DebugFrames.frames.has(current_frame):
		return
	
	var frames = DebugFrames.frames.get(current_frame)
	
	for frame in frames:
		var item = tree.create_item(root)
		var key = frame.get(DebugFrames.TITLE_KEY, "<untitled>")
		var path = key.to_snake_case()
		
		set_item_title_and_meta(item, key, "", path)
		render_sub_tree(tree, item, frame)
		
	tree.scroll_to_item(root)

func slider_changed(value: int) -> void:
	frame_spin_box.value = value
	current_frame = value
	render()
	
func spin_box_changed(value: int) -> void:
	frame_slider.value = value
	current_frame = value
	render()
	
func frames_resized(min: int, max: int) -> void:
	frame_spin_box.min_value = min
	frame_spin_box.max_value = max
	frame_slider.min_value = min
	frame_slider.max_value = max
	min_frame = min
	max_frame = max
	render()
	
func frames_added() -> void:
	render()

func _on_recording_toggle_toggled(button_pressed: bool) -> void:
	DebugFrames.is_recording = button_pressed
	render()

func _on_reset_button_up() -> void:
	DebugFrames.reset()
	render()
	
func _on_play_button_up() -> void:
	is_playing = !is_playing
	render()

func _on_pause_graph_button_up() -> void:
	DebugGraph.is_recording = !DebugGraph.is_recording

func _on_graph_added(graph_name) -> void:
	var panel_resource = preload("res://globals/debug/graph_panel.tscn")
	var panel: GraphPanel = panel_resource.instantiate() as GraphPanel
	var color: Color = [Color.WHITE, Color.DEEP_PINK, Color.GREEN].pick_random()
	
	graph_panels.add_child(panel)
	panel.graph_name = graph_name
	panel.color = color
