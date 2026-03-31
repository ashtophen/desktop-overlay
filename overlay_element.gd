extends Control

var dragging = false
var click_offset = Vector2i.ZERO
var click_start_pos = Vector2i.ZERO
var drag_threshold = 5.0
var menu: PopupPanel
var scale_slider_label: Label
var speed_slider_label: Label
var _menu_just_closed = false

func _ready():
	item_rect_changed.connect(_on_item_rect_changed)
	_on_item_rect_changed()
	menu = PopupPanel.new()
	menu.set_script(load("res://element_menu.gd"))
	menu.popup_hide.connect(_on_menu_hidden)
	add_child(menu)
	
	
	var vbox = menu.get_child(0) #vbox was made in overlay_element_menu.gd
	
	menu.transient = true
	menu.exclusive = false
	menu.unfocusable = false
	
	scale_slider_label = Label.new()
	scale_slider_label.text = "Scale: %s" %self.scale.x
	vbox.add_child(scale_slider_label)
	
	var scale_slider = HSlider.new()
	scale_slider.custom_minimum_size = Vector2(250, 0)
	scale_slider.min_value = 0.1
	scale_slider.max_value = 10
	scale_slider.step = .1
	scale_slider.value = self.scale.x
	vbox.add_child(scale_slider)
	scale_slider.value_changed.connect(_on_scale_slider_changed)
	
	if self.texture is AnimatedTexture:
		speed_slider_label = Label.new()
		speed_slider_label.text = "Speed: %s" %self.texture.speed_scale
		vbox.add_child(speed_slider_label)
	
		var speed_slider = HSlider.new()
		speed_slider.custom_minimum_size = Vector2(250, 0)
		speed_slider.min_value = .1
		speed_slider.max_value = 10
		speed_slider.step = 1
		speed_slider.value = self.texture.speed_scale
		vbox.add_child(speed_slider)
		speed_slider.value_changed.connect(_on_speed_slider_changed)
		
		var reset_element_btn = Button.new()
		
		var change_texture_btn = Button.new()
		
		var delete_element_btn = Button.new()
		
func _on_menu_hidden():
	_menu_just_closed = true
	await get_tree().process_frame
	await get_tree().process_frame
	_menu_just_closed = false
	

func _on_scale_slider_changed(value):
	print(menu.visible)
	scale_slider_label.text = "Scale: %s" %value
	self.scale.x = value
	self.scale.y = value

func _on_speed_slider_changed(value):
	speed_slider_label.text = "Speed: %s" %value
	self.texture.speed_scale = value

func _gui_input(event):
	if (menu and menu.visible) or _menu_just_closed:
		return
	if event is InputEventMouseButton:
		if menu.visible or _menu_just_closed:
			dragging = false
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Left Click!")
			if event.pressed:
				dragging = false
				click_start_pos = event.global_position
				
				# 1. Get current mouse pos in SCREEN pixels
				var mouse_screen_pos = DisplayServer.mouse_get_position()
				# 2. Calculate fixed distance from mouse to window top-left
				click_offset = get_window().position - mouse_screen_pos
				accept_event()
			else:
				if not dragging:
					_on_click()
					dragging = false
					accept_event()
				

	if event is InputEventMouseMotion:
		if menu.visible or _menu_just_closed or click_offset == Vector2i.ZERO:
			return
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			var move_dist = event.global_position.distance_to(click_start_pos)
			if move_dist > drag_threshold:
				dragging = true
			if dragging:
				var current_mouse_pos = DisplayServer.mouse_get_position()
				get_window().position = current_mouse_pos + click_offset
				# dragging = false
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		dragging = false
		_menu_just_closed = false # Reset this just in case
		click_offset = Vector2i.ZERO # Clear the old offset to prevent the snap
		var popup_pos = DisplayServer.mouse_get_position()
		menu.popup(Rect2i(popup_pos.x, popup_pos.y, 200, 600))
	accept_event()
func _set(property: StringName, value) -> bool:
	if property == "scale":
		# Let the actual scale change happen
		scale = value 
		# Manually trigger your window update logic
		_update_window_to_scaled_size()
		return true # We handled it
	return false

func _update_window_to_scaled_size():
	var scaled_size = size * scale
	get_window().size = Vector2i(scaled_size)
	
func _on_item_rect_changed():
	var scaled_size = size * scale
	get_window().size = Vector2i(scaled_size)
		
func _on_click():
	
	print("clicked")
