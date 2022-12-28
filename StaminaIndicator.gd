extends Control

@onready @export var player: PlayerFSM

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var stamina: Stamina = player.get_node("Stamina")

var is_progress_visible: bool = false
var is_warning_visible: bool = false

func _ready() -> void:
	stamina.connect("full", on_stamina_full)
	
	if stamina.is_full():
		hide_progress(true)

func _process(_delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	
	if !camera or !player:
		return
		
	if !is_progress_visible and !stamina.is_full():
		show_progress()

	var screen_position = camera.unproject_position(player.global_transform.origin + player.global_transform.basis.y)	
	progress_bar.position = screen_position - (size / 2)
	progress_bar.value = player.stamina.amount

func show_progress() -> void:
	var tween = get_tree().create_tween()

	tween.set_parallel(true)
	tween.tween_property(progress_bar, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK)
	tween.tween_property(progress_bar, "modulate", Color(0, 1, 0, 1), 0.25).set_trans(Tween.TRANS_SINE)
	
	is_progress_visible = true
	
func hide_progress(instant: bool = false) -> void:
	if instant:
		progress_bar.modulate = Color(0, 1, 0, 0)
		progress_bar.scale = Vector2(0, 0)
		return

	var tween = get_tree().create_tween()

	tween.set_parallel(true)
	tween.tween_property(progress_bar, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_BACK)
	tween.tween_property(progress_bar, "modulate", Color(0, 1, 0, 0), 0.45).set_trans(Tween.TRANS_SINE)
	
	is_progress_visible = false

func on_stamina_full() -> void:
	hide_progress()
