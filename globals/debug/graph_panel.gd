class_name GraphPanel
extends Panel

@export var graph_name: String = ""  
@export var color: Color = Color.WHITE
@export var range: float = 6

@onready var name_label: Label = %NameLabel
@onready var value_label: Label = %ValueLabel

var plots: Array = [] 

func _process(_delta: float) -> void:
	plots = DebugGraph.graphs.get(graph_name, [])
	name_label.text = graph_name
	
	if not plots.is_empty():
		value_label.text = str(plots[plots.size() - 1])
	
	queue_redraw()

func _draw() -> void:
	for plot_index in range(plots.size()):
		if plot_index < 1:
			continue
		
		var plot = plots[plot_index]
		var previous_plot = plots[plot_index - 1]

		var previous_percent = Vector2(
			float(plot_index - 1) / float(DebugGraph.max_graph_size),
			1 - (previous_plot / range)
		)
		var percent = Vector2(
			float(plot_index) / float(DebugGraph.max_graph_size),
			1 - (plot / range)
		)
		
		draw_line(
			Vector2(size.x * previous_percent.x, size.y * previous_percent.y),
			Vector2(size.x * percent.x, size.y * percent.y),
			color,
			1.5
		)
