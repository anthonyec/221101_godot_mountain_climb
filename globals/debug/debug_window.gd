extends Control

@export var target: Node3D

@onready var window: Window = %Window
@onready var tree: Tree = %Tree
@onready var hover_panel: HoverPanel = $Window/HoverPanel

var current_selected_item: TreeItem = null

func _ready() -> void:
	window.connect("close_requested", _on_window_close_requested)
	
func _process(delta: float) -> void:
	var mouse_position = window.get_mouse_position() - tree.position
	var item = tree.get_item_at_position(mouse_position)

	if not item:
		hover_panel.hide()
		return 
	
	var title = item.get_text(0)
	var metadata = item.get_metadata(1)
	
	if metadata == null:
		hover_panel.hide()
		return
		
	if typeof(metadata) == TYPE_VECTOR3:
		metadata = metadata as Vector3
		hover_panel.show()
		hover_panel.position = mouse_position - Vector2(20, 30)
		hover_panel.vector = metadata
		
		if title.contains("position"):
			DebugDraw.draw_cube(metadata, 0.1, Color.WHITE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_show_frames"):
		window.show()
	
func _on_window_close_requested() -> void:
	window.hide()
