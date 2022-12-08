extends Control

@export var player_path: NodePath

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var player: Player = get_node(player_path)

func _ready() -> void:
	player.stamina.connect("full", on_stamina_full)

func _process(delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	
	if !camera or !player:
		return
		
	var screen_position = camera.unproject_position(player.global_transform.origin + player.global_transform.basis.y)
	
	progress_bar.position = screen_position - (progress_bar.size / 2)
	progress_bar.value = player.stamina.amount

func on_stamina_full() -> void:
	print("on_stamina_full")
