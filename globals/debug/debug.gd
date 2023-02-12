extends CanvasLayer

const FONT = preload("res://addons/zylann.debug_draw/Hack-Regular.ttf")

var canvas_item: CanvasItem = Node2D.new()

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

func _on_canvas_item_draw() -> void:
	if notification != "":
		canvas_item.draw_string(FONT, Vector2(501, 52), notification, 0, -1, 24, Color(0, 0, 0, 0.75))
		canvas_item.draw_string(FONT, Vector2(500, 50), notification, 0, -1, 24, Color.WHITE)
