extends Node2D

signal added(graph_name: String)

@export var is_recording: bool = true
@export var max_graph_size: int = 256

var graphs: Dictionary = {}

func plot(name: String, value: float) -> void:
	if not is_recording:
		return
		
	if not graphs.has(name):
		graphs[name] = []
		added.emit(name)
	
	var graph = graphs[name] as Array
	graph.append(value)
	
	if graph.size() > max_graph_size:
		graphs[name] = graph.slice(graph.size() - max_graph_size, graph.size())
