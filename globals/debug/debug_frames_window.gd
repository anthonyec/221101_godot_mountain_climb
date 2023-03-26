extends Window

@onready var tree: Tree = %Tree
@onready var frame_slider: HSlider = %FrameSlider
@onready var frame_spin_box: SpinBox = %FrameSpinBox
@onready var record_button: Button = %RecordButton
@onready var reset_button: Button = %ResetButton
@onready var play_button: Button = %PlayButton

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
	
	DebugFrames.connect("resized", frames_resized)
	DebugFrames.connect("added", frames_added)
	
	frames_resized(min_frame, max_frame)
	
func _process(_delta: float) -> void:
	for callable in current_frame_callables:
		callable.call()
		
	if is_playing:
		frame_slider.value += 1

func render_sub_tree(target_tree: Tree, target_parent: TreeItem, dictionary: Dictionary) -> void:
	for key in dictionary:
		if key == "title":
			continue
			
		var value = dictionary[key]
		
		if typeof(value) == TYPE_DICTIONARY:
			var sub_item = target_tree.create_item(target_parent)
			
			sub_item.set_text(0, str(key))
			render_sub_tree(target_tree, sub_item, value)
			continue
		
		if typeof(value) == TYPE_VECTOR3:
			var sub_item = target_tree.create_item(target_parent)
			
			sub_item.set_text(0, str(key))
			sub_item.set_text(1, str(value))
			sub_item.set_metadata(1, value)
			continue
			
		if typeof(value) == TYPE_CALLABLE:
			current_frame_callables.append(value)
			continue
		
		var sub_item = target_tree.create_item(target_parent)
		sub_item.set_text(0, str(key))
		sub_item.set_text(1, str(value))
		sub_item.set_metadata(1, value)

func render() -> void:
	play_button.disabled = DebugFrames.is_recording
	reset_button.disabled = is_playing
	record_button.disabled = is_playing
	
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
		
		item.set_text(0, frame.get("title", "<untitled>"))
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
	DebugFrames.frames = {}
	DebugFrames.frame_count = 0
	render()
	
func _on_play_button_up() -> void:
	is_playing = !is_playing
	render()

func _on_search_text_changed(new_text: String) -> void:
	print(new_text)
