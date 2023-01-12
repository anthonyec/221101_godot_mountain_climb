extends PlayerState

@onready var rope_end_scene: PackedScene = preload("res://entities/raycast_rope/rope_end.tscn")
@onready var raycast_rope_scene: PackedScene = preload("res://entities/raycast_rope/raycast_rope.tscn")

var rope_end: RopeEnd
var raycast_rope: RaycastRope

func enter(_params: Dictionary) -> void:
	player.animation.play("Idle")
	
	rope_end = rope_end_scene.instantiate() as RopeEnd
	rope_end.global_transform.origin = player.global_transform.origin
	
	raycast_rope = raycast_rope_scene.instantiate() as RaycastRope
	raycast_rope.global_transform.origin = player.global_transform.origin
	raycast_rope.target = rope_end
	
	rope_end.rope = raycast_rope
	player.rope = raycast_rope

	player.get_parent().add_child(rope_end)
	player.get_parent().add_child(raycast_rope)
	
	var force_forward = -player.global_transform.basis.z * 7
	var force_up = player.global_transform.basis.y * 2
	
	rope_end.apply_central_impulse(force_forward + force_up)

func exit() -> void:
	player.get_parent().remove_child(rope_end)
	player.get_parent().remove_child(raycast_rope)
	
	player.rope = null

func update(_delta: float) -> void:
	player.face_towards(rope_end.global_transform.origin)

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(player.get_action_name("start_hosting_abseil")):
		state_machine.transition_to("Move")
		return
