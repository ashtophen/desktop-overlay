extends ColorRect



func _on_color_picker_button_color_changed(color: Color) -> void:
	self.color = color

func _ready():
	await get_tree().process_frame
	get_viewport().size_changed.connect(update_passthrough)
	get_viewport().size_changed.connect(_on_window_resize)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().always_on_top = true
	update_passthrough()

func _on_window_resize():
	update_passthrough()

func update_passthrough():
	# 1. Get the global position and size of the ColorRect

	var rect = get_global_rect()
	print(rect)
	
	var xform = get_viewport().get_screen_transform() * get_canvas_transform()
	
	# 3. Transform each point into actual window pixels
	var p1 = xform * rect.position
	var p2 = xform * Vector2(rect.end.x, rect.position.y)
	var p3 = xform * rect.end
	var p4 = xform * Vector2(rect.position.x, rect.end.y)
	
	var points = PackedVector2Array([p1, p2, p3, p4])
	print(points)
	get_window().mouse_passthrough_polygon = points
	
