extends TextureRect
# For choosing an exe for the overlay to launch
var installed_apps: Dictionary = {}
var item_list: ItemList
var exe_path_input: LineEdit
var exe_select_btn: Button
var exe_id: String
var exe_list_window: Window

var dragging = false
var click_offset = Vector2i.ZERO
var click_start_pos = Vector2i.ZERO
var drag_threshold = 5.0
var menu: PopupPanel
var exe_launcher_btn: CheckButton
var exe_vbox: VBoxContainer
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
var flip_h_btn: CheckButton
var flip_v_btn: CheckButton

#var click_func
# var click_through_switch
var click_through_enabled: bool = true
var click_through_toggle: CheckButton
var make_desktop_icon_toggle: CheckButton

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
	tex_color.a *= COLOR.a;
	
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
	
	
	var vbox = menu.get_child(0) #vbox was made in element_menu.gd
	
	menu.transient = true
	menu.exclusive = false
	menu.unfocusable = false
	
	exe_launcher_btn = CheckButton.new()
	exe_launcher_btn.text = "Launch Application On Left Click"
	
	vbox.add_child(exe_launcher_btn)
	
	exe_vbox = VBoxContainer.new()
	vbox.add_child(exe_vbox)
	exe_vbox.hide()
	exe_launcher_btn.toggled.connect(func(is_pressed): exe_vbox.visible = is_pressed)
	
	var exe_man_btn: CheckButton = CheckButton.new()
	exe_man_btn.text = "Manually Choose Path?"
	exe_vbox.add_child(exe_man_btn)
	
	
	exe_path_input = LineEdit.new()
	exe_path_input.hide()
	exe_path_input.placeholder_text = "C:/PATH/TO/YOUR/APP"
	#exe_path_input.text_submitted.connect()
	#ADD FUNCTION
	exe_vbox.add_child(exe_path_input)
	exe_man_btn.toggled.connect(func(is_pressed): exe_path_input.visible = is_pressed)
	
	exe_select_btn = Button.new()
	exe_select_btn.text = "Select App To Launch"
	exe_select_btn.pressed.connect(load_windows_apps)
	exe_vbox.add_child(exe_select_btn)
	
	
	
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
	
	flip_h_btn = CheckButton.new()
	flip_h_btn.text = "Flip Horizontally"
	flip_h_btn.toggled.connect(_on_flip_h_btn_toggled)
	vbox.add_child(flip_h_btn)
	flip_v_btn = CheckButton.new()
	flip_v_btn.text = "Flip Vertically"
	flip_v_btn.toggled.connect(_on_flip_v_btn_toggled)
	vbox.add_child(flip_v_btn)
	
	
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
	
	click_through_toggle = CheckButton.new()
	click_through_toggle.text = "Passthrough Transparent Areas"
	click_through_toggle.button_pressed = click_through_enabled
	click_through_toggle.pressed.connect(func(): click_through_enabled = !click_through_enabled)
	vbox.add_child(click_through_toggle)
	
	make_desktop_icon_toggle = CheckButton.new()
	make_desktop_icon_toggle.text = "Make Interactive"
	#make_desktop_icon_toggle.button_pressed = desktop
	
	###ITEMLIST FOR EXES###
	
	exe_list_window = Window.new()
	exe_list_window.title = "Select Application"
	exe_list_window.size = Vector2i(450,350)
	exe_list_window.position = Vector2i(150, 150)
	#exe_list_window.translucent = true
	exe_list_window.close_requested.connect(func(): exe_list_window.hide())
	
	
	item_list = ItemList.new()
	item_list.name = "AppList"
	item_list.custom_minimum_size = Vector2(400, 300)
	item_list.position = Vector2(100, 100)
	item_list.select_mode = ItemList.SELECT_SINGLE
	item_list.item_selected.connect(_on_item_selected)
	#item_list.hide()
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	exe_list_window.add_child(item_list)
	add_child(exe_list_window)
	exe_list_window.hide()
	
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
	
	
	Globals.connect("overlay_loaded", _on_overlay_loaded)
	# self.material = my_material

	
	# my_material.set_shader_parameter("chroma_key", Color(0.0, 0.0, 0.0, 1.0))
	# my_material.set_shader_parameter("precision", 0.15)
	###
	#clickthrough_switch
	

func _on_item_selected(index: int):
	exe_id = installed_apps[item_list.get_item_text(index)]
	exe_list_window.hide()
	
func load_windows_apps():
	var output = []
	var arguments = [
		"-NoProfile", 
		"-Command", 
		"Get-StartApps | ForEach-Object { $_.Name + ',' + $_.AppID }"
	]
	
	OS.execute("powershell", arguments, output, true)
	
	if output.size() > 0:
		parse_apps(output[0])
		
func parse_apps(raw_output: String):
	item_list.clear()
	installed_apps.clear()
	
	var lines = raw_output.split("\n", false)
	
	for line in lines:
		line = line.strip_edges()
		if line.contains(","):
			var parts = line.split(",", true, 1)
			var app_name = parts[0]
			var app_id = parts[1]
			
			installed_apps[app_name] = app_id
			item_list.add_item(app_name)
	exe_list_window.show()


func launch_app(app_id: String) -> void:
	if app_id:
		var output = []
		
		var arguments = ["shell:AppsFolder\\" + app_id]
		OS.execute("explorer.exe", arguments, output, false)

func _on_flip_h_btn_toggled(is_on: bool):
	if is_on:
		self.flip_h = true
	else: self.flip_h = false

func _on_flip_v_btn_toggled(is_on: bool):
	if is_on:
		self.flip_v = true
	else: self.flip_v = false

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
		if not is_instance_valid(speed_slider_label):
			speed_slider_label = Label.new()
			speed_slider_label.text = "Speed: %s" %self.texture.speed_scale
			vbox.add_child(speed_slider_label)
			vbox.move_child(speed_slider_label, 3)
	
		if not is_instance_valid(speed_slider):
			speed_slider = HSlider.new()
			speed_slider.custom_minimum_size = Vector2(250, 0)
			speed_slider.min_value = .1
			speed_slider.max_value = 10
			speed_slider.step = .1
			speed_slider.value = self.texture.speed_scale
			vbox.add_child(speed_slider)
			vbox.move_child(speed_slider, 4)
			speed_slider.value_changed.connect(_on_speed_slider_changed)
		speed_slider_label.text = "Speed: %s" % self.texture.speed_scale
		speed_slider.value = self.texture.speed_scale
		speed_slider_label.show()
		speed_slider.show()
	else:
		# If the new texture is NOT animated, hide the speed controls if they exist
		if is_instance_valid(speed_slider_label):
			speed_slider_label.queue_free()
			speed_slider_label = null
		if is_instance_valid(speed_slider):
			speed_slider.queue_free()
			speed_slider = null

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

func _input(event: InputEvent) -> void:
	if dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if OverlayFunctions.ActiveDraggingWindowID == get_window().get_window_id():
			if not event.pressed:
				#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				dragging = false
				OverlayFunctions.ActiveDraggingWindowID = -1 # Release the global lock
				
				if DisplayServer.mouse_get_position().distance_to(click_start_pos) < drag_threshold:
					_on_click()
					get_viewport().set_input_as_handled()
	if dragging and event is InputEventMouseMotion:
		get_window().position = DisplayServer.mouse_get_position() + click_offset
		get_viewport().set_input_as_handled()

	if dragging and OverlayFunctions.ActiveDraggingWindowID == get_window().get_window_id():
		if event is InputEventMouseMotion:
			get_window().position = DisplayServer.mouse_get_position() + click_offset
		#OverlayFunctions.ForceWindowToTop(get_window().get_window_id())

func _gui_input(event):
	if (menu and menu.visible) or _menu_just_closed:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if OverlayFunctions.ActiveDraggingWindowID == -1:
					OverlayFunctions.ActiveDraggingWindowID = get_window().get_window_id()
					OverlayFunctions.ForceWindowToTop(get_window().get_window_id())
					#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
					
					dragging = true
					click_start_pos = DisplayServer.mouse_get_position()
					var mouse_screen_pos = DisplayServer.mouse_get_position()
					click_offset = get_window().position - mouse_screen_pos
					accept_event()
			else:
					pass
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
	if exe_id:
		launch_app(exe_id)


func _on_overlay_loaded():
	my_material.set_shader_parameter("chroma_key", color_picker.color)

func _process(_delta):
	# Never go click-through while dragging or menu is open
	if dragging or (menu and menu.visible): 
		OverlayFunctions.SetClickThrough(false, get_window().get_window_id())
		return

	var is_solid = false
	var mouse_pos = get_viewport().get_mouse_position()
	var window_size = get_viewport().get_visible_rect().size

	if mouse_pos.x >= 0 and mouse_pos.y >= 0 and mouse_pos.x <= window_size.x and mouse_pos.y <= window_size.y:
		var img = texture.get_image()
		var tex_size = texture.get_size()

		var ratio_x = mouse_pos.x / (size.x * scale.x)
		var ratio_y = mouse_pos.y / (size.y * scale.y)
		var tex_x = int(ratio_x * tex_size.x)
		var tex_y = int(ratio_y * tex_size.y)
		#print(tex_x, " ", tex_y)
		
		# 3. Double-check bounds before calling get_pixel
		if tex_x >= 0 and tex_x < img.get_width() and tex_y >= 0 and tex_y < img.get_height():
			var pixel = img.get_pixel(tex_x, tex_y)
			
			# 2. Replicate Shader Logic: Check Alpha and Chromakey
			if pixel.a > 0.1:
				if chromakey_switch.button_pressed:
					var key_color = color_picker.color
					var dist = Vector3(pixel.r, pixel.g, pixel.b).distance_to(Vector3(key_color.r, key_color.g, key_color.b))
					var shader_precision = my_material.get_shader_parameter("precision")
					if shader_precision == null:
						shader_precision = 0.1 # Fallback value

					if dist > shader_precision:
						is_solid = true
				else:
					is_solid = true

	# 3. If not over a solid pixel, make window click-through
	if click_through_enabled:
		OverlayFunctions.SetClickThrough(!is_solid, get_window().get_window_id())

	alpha_slider.value = self.modulate.a
	scale_slider.value = self.scale.x
	# my_material.set_shader_parameter("chroma_key", color_picker.color)
	if is_instance_valid(speed_slider) and self.texture == AnimatedTexture:
		speed_slider.value = self.texture.speed_scale
	else: return
	flip_h_btn.button_pressed = self.flip_h
	flip_v_btn.button_pressed = self.flip_v
