extends Window

@export var target: Node3D

@onready var tree: Tree = %Tree
@onready var frame_slider: HSlider = %FrameSlider
@onready var frame_spin_box: SpinBox = %FrameSpinBox
@onready var recording_toggle: CheckButton = %RecordingToggle
@onready var reset_button: Button = %ResetButton

var current_frame: int = 0
var current_frame_callables: Array[Callable] = []
var min_frame: int = 0
var max_frame: int = 1024

func _ready() -> void:
	frame_slider.connect("value_changed", slider_changed)
	frame_spin_box.connect("value_changed", spin_box_changed)
	DebugFrames.connect("resized", frames_resized)
	DebugFrames.connect("added", frames_added)
	frames_resized(min_frame, max_frame)
	
func _process(_delta: float) -> void:
	for callable in current_frame_callables:
		callable.call()
	
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

func render() -> void:
	recording_toggle.button_pressed = DebugFrames.is_recording
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

func _on_reset_button_button_up() -> void:
	DebugFrames.frames = {}
	DebugFrames.frame_count = 0

func _on_tree_item_selected() -> void:
	var item = tree.get_selected()
	var metadata = item.get_metadata(0)

	if typeof(metadata) == TYPE_VECTOR3:
		print("WOW")
		DebugDraw
##		DebugDraw.draw_ray_3d(target.global_transform.origin, metadata, Color.RED)
#		DebugDraw.draw_cube(Vector3.ZERO, 2, Color.RED)
#		print(DebugDraw)
