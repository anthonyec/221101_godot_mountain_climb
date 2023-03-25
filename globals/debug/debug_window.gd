extends Control

@export var target: Node3D

@onready var window: Window = %Window
@onready var tree: Tree = %Tree

var current_selected_item: TreeItem = null

func _ready() -> void:
	window.connect("close_requested", _on_window_close_requested)
	tree.connect("item_selected", _on_tree_item_selected)
	
func _process(delta: float) -> void:
	if not current_selected_item or not target:
		return
		
	var item = tree.get_selected()
	var metadata = item.get_metadata(1)
	
	print(metadata)
	
	if typeof(metadata) == TYPE_VECTOR3:
		DebugDraw.draw_ray_3d(target.global_transform.origin, metadata.normalized(), 1, Color.RED)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_show_frames"):
		window.show()
	
func _on_window_close_requested() -> void:
	window.hide()

func _on_tree_item_selected() -> void:
	current_selected_item = tree.get_selected()
