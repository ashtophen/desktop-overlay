extends TextureRect

var dragging = false
var click_offset = Vector2i.ZERO
var click_start_pos = Vector2i.ZERO
var drag_threshold = 5.0
var menu: PopupPanel
var scale_slider_label: Label
var speed_slider_label: Label
var alpha_slider_label: Label
var _menu_just_closed = false
var scale_slider: HSlider
var speed_slider: HSlider
var file_dialog: FileDialog
var chromakey_switch: CheckButton
var chroma_vbox: VBoxContainer
var color_picker: ColorPicker
var alpha_slider: HSlider
# var click_through_switch

### Shader Variables ###
var shader_code = """
shader_type canvas_item;

uniform vec4 chroma_key : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float precision : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float dist = distance(tex_color.rgb, chroma_key.rgb);
	if (dist < precision) {
		tex_color.a = 0.0;
	}
	COLOR = tex_color;
}
"""
var my_shader: Shader
var my_material: ShaderMaterial

func _ready():
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.png","*.jpg","*.jpeg","*.svg","*.gif", "Image Files"]) # Image Files on the end there mayyyyy be causing some issues
	file_dialog.size = Vector2(780,560)
	file_dialog.position = Vector2i(200, 200)
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)
	
	item_rect_changed.connect(_on_item_rect_changed)
	_on_item_rect_changed()
	menu = PopupPanel.new()
	menu.set_script(load("res://scr/element_menu.gd"))
	menu.popup_hide.connect(_on_menu_hidden)
	add_child(menu)
	
	
	var vbox = menu.get_child(0) #vbox was made in overlay_element_menu.gd
	
	menu.transient = true
	menu.exclusive = false
	menu.unfocusable = false
	
	scale_slider_label = Label.new()
	scale_slider_label.text = "Scale: %s" %self.scale.x
	vbox.add_child(scale_slider_label)
	
	scale_slider = HSlider.new()
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
	
		speed_slider = HSlider.new()
		speed_slider.custom_minimum_size = Vector2(250, 0)
		speed_slider.min_value = .1
		speed_slider.max_value = 10
		speed_slider.step = .1
		speed_slider.value = self.texture.speed_scale
		vbox.add_child(speed_slider)
		speed_slider.value_changed.connect(_on_speed_slider_changed)
	alpha_slider_label = Label.new()
	alpha_slider_label.text = "Opacity %.1f%%" %(self.modulate.a * 100)
	vbox.add_child(alpha_slider_label)
	alpha_slider = HSlider.new()
	alpha_slider.custom_minimum_size = Vector2(250, 0)
	alpha_slider.value = self.modulate.a
	alpha_slider.min_value = 0.05
	alpha_slider.step = 0.01
	alpha_slider.max_value = 1
	vbox.add_child(alpha_slider)
	alpha_slider.value_changed.connect(_on_alpha_slider_changed)
	
	var reset_btn = Button.new()
	vbox.add_child(reset_btn)
	reset_btn.pressed.connect(_on_reset_btn_pressed)
	reset_btn.text = "Reset"
		
		
	var change_texture_btn = Button.new()
	vbox.add_child(change_texture_btn)
	change_texture_btn.pressed.connect(_on_change_texture_btn_pressed)
	change_texture_btn.text = "Change Texture"
		
	var delete_element_btn = Button.new()
	var delete_stylebox_normal = delete_element_btn.get_theme_stylebox("normal").duplicate()
	#delete_stylebox_normal.border_width_top = 3
	delete_stylebox_normal.bg_color = Color(0.159, 0.029, 0.015, 0.851)
	delete_element_btn.add_theme_stylebox_override("normal", delete_stylebox_normal)
	# delete_element_btn.remove_theme_stylebox_override("normal")
	delete_element_btn.text = "Remove From Overlay"
	vbox.add_child(delete_element_btn)
	delete_element_btn.pressed.connect(_on_delete_element_btn_pressed)
	
	
	### Shader Code For Chromakeying ###
	
	chromakey_switch = CheckButton.new()
	chromakey_switch.text = "Enable Chromakeying"
	chromakey_switch.toggled.connect(_on_chromakey_switch_toggled)
	vbox.add_child(chromakey_switch)
	
	chroma_vbox = VBoxContainer.new()
	chroma_vbox.hide()
	var color_picker_label = Label.new()
	color_picker_label.text = "Color For Chromakeying"
	color_picker = ColorPicker.new()
	color_picker.color_changed.connect(_on_color_picker_color_changed)
	chroma_vbox.add_child(color_picker_label)
	chroma_vbox.add_child(color_picker)
	
	vbox.add_child(chroma_vbox)
	
	
	my_shader = Shader.new()
	my_shader.code = shader_code

	my_material = ShaderMaterial.new()
	my_material.shader = my_shader
	
	
	# self.material = my_material

	
	# my_material.set_shader_parameter("chroma_key", Color(0.0, 0.0, 0.0, 1.0))
	# my_material.set_shader_parameter("precision", 0.15)
	
	
func _on_alpha_slider_changed(value):
	self.modulate.a = alpha_slider.value
	alpha_slider_label.text = "Opacity %.1f%%" %(self.modulate.a * 100)
	
func _on_color_picker_color_changed(color: Color):
	my_material.set_shader_parameter("chroma_key", color)
	
func _on_chromakey_switch_toggled(is_on: bool):
	if is_on:
		chroma_vbox.show()
		self.material = my_material
	else:
		chroma_vbox.hide()
		self.material = null

func _on_delete_element_btn_pressed():
	get_window().queue_free()
		
func _on_file_selected(path):
	Globals.set_img(path, self as TextureRect)
	var vbox = menu.get_child(0)
	get_window().set_meta("file_path", path)
	if self.texture is AnimatedTexture:
		speed_slider_label = Label.new()
		speed_slider_label.text = "Speed: %s" %self.texture.speed_scale
		vbox.add_child(speed_slider_label)
		vbox.move_child(speed_slider_label, 3)
	
		speed_slider = HSlider.new()
		speed_slider.custom_minimum_size = Vector2(250, 0)
		speed_slider.min_value = .1
		speed_slider.max_value = 10
		speed_slider.step = .1
		speed_slider.value = self.texture.speed_scale
		vbox.add_child(speed_slider)
		vbox.move_child(speed_slider, 4)
		speed_slider.value_changed.connect(_on_speed_slider_changed)

func _on_change_texture_btn_pressed():
	#if speed_slider == HSlider.new():
	#	speed_slider.value = 1
	scale_slider.value = 1
	file_dialog.popup()
	

func _on_reset_btn_pressed():
	scale_slider.value = 1 
func _on_menu_hidden():
	_menu_just_closed = true
	await get_tree().process_frame
	await get_tree().process_frame
	_menu_just_closed = false
	

func _on_scale_slider_changed(value):
	#print(menu.visible)
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
			#print("Left Click!")
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

func _process(_delta: float) -> void:
	alpha_slider.value = self.modulate.a
	scale_slider.value = self.scale.x
	my_material.set_shader_parameter("chroma_key", color_picker.color)
	if is_instance_valid(speed_slider) and self.texture == AnimatedTexture:
		speed_slider.value = self.texture.speed_scale
	else: return
