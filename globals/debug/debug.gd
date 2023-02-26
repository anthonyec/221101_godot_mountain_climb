extends CanvasLayer

const FONT = preload("res://addons/zylann.debug_draw/Hack-Regular.ttf")

var canvas_item: CanvasItem = Node2D.new()

var current_message: String = ""
var notification: String = ""

func round_to_dec(mumber: float, digit: int):
	return round(mumber * pow(10.0, digit)) / pow(10.0, digit)
	
func _ready() -> void:
	canvas_item.draw.connect(_on_canvas_item_draw)
	add_child(canvas_item)

func _process(_delta: float) -> void:
	var memory = float(OS.get_static_memory_usage()) / 1000000
	var fps = Engine.get_frames_per_second()
	
	DebugDraw.set_text("memory (mb)", round_to_dec(memory, 2))
	DebugDraw.set_text("fps", fps)
	
	canvas_item.queue_redraw()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	var key_event = event as InputEventKey
	
	if not key_event.pressed:
		return
	
	if key_event.keycode == KEY_1:
		Raycast.debug = !Raycast.debug
		notify("Show raycasts: " + str(Raycast.debug))
		
	if key_event.keycode == KEY_2:
		var players = get_tree().get_nodes_in_group("player")
		
		if players.is_empty():
			return
		
		var toggled: bool
		
		for player in players:
			player = player as Player
			player.ledge.debug = !player.ledge.debug 
			toggled = player.ledge.debug
			
		notify("Show ledge: " + str(toggled))
		
		
	if key_event.keycode == KEY_3:
		var players = get_tree().get_nodes_in_group("player")
		
		if players.is_empty():
			return
		
		for player in players:
			player = player as Player
			player.stamina.reset()
			
		notify("Stamina refilled")
		
	if key_event.keycode == KEY_4:
		var players = get_tree().get_nodes_in_group("player")
		
		if players.is_empty():
			return
		
		for player in players:
			player = player as Player
			
			if player.input_type == Player.InputType.CONTROLLER:
				player.global_transform.origin = Vector3(7.365429, 5.890122, 15.62682)
				player.global_rotation = Vector3(0, 0.236252, 0)
			
		notify("Set player postion and rotation")
		pass
	
	if key_event.keycode == KEY_8:
		Engine.max_fps = 30 if Engine.max_fps == 60 else 60
		notify("Set FPS: " + str(Engine.max_fps))
		
	if key_event.keycode == KEY_9:
		Engine.max_fps = 10 if Engine.max_fps == 60 else 60
		notify("Set FPS: " + str(Engine.max_fps))
	
	if key_event.keycode == KEY_0:
		Engine.time_scale = 0.1 if Engine.time_scale == 1 else 1
		notify("Set time scale: " + str(Engine.time_scale))

func notify(message: String) -> void:
	notification = message
	
	await get_tree().create_timer(2).timeout
	
	notification = ""
	
func show_message(message: String) -> void:
	current_message = message

func _on_canvas_item_draw() -> void:
	if current_message != "":
		var messages = current_message.split("\n")
		var start_position = Vector2(500, 300)
		
		for index in messages.size():
			var message = messages[index]
			var line_position = Vector2(start_position.x, start_position.y + (18 * index))
			
			canvas_item.draw_string(FONT, line_position + Vector2(1, 1), message, 0, -1, 13, Color(0, 0, 0, 0.75))
			canvas_item.draw_string(FONT, line_position, message, 0, -1, 13, Color.WHITE)
		
	if notification != "":
		canvas_item.draw_string(FONT, Vector2(501, 52), notification, 0, -1, 24, Color(0, 0, 0, 0.75))
		canvas_item.draw_string(FONT, Vector2(500, 50), notification, 0, -1, 24, Color.WHITE)
