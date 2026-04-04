extends Node
signal overlay_saved
signal display_msg(msg: String)
var toggle_menu_hotkey_text = InputMap.action_get_events("Toggle Menu")[0].as_text()
var screen_size: Vector2i
var saved_overlays: PackedStringArray
var been_warned = false # TEMP PLEASE GET RID OF

var menu: CenterContainer

#func _init() -> void:
	#print("init")
	#if not OS.has_feature("editor"):
	#	print("not in the editor boyyyyyyyyy")
		#var exe_dir = OS.get_executable_path().get_base_dir()
	
		#ProjectSettings.set_setting("application/run/current_directory", exe_dir)
	
	#Print("You IN MA HOUSE!", exe_dir)



func _ready():
	
	screen_size = DisplayServer.screen_get_size()
	
	# 2. Subtract 1 pixel from both dimensions
	var new_size = screen_size - Vector2i(1, 1)
	
	# 3. Set the window size
	DisplayServer.window_set_size(new_size)
	
	# 4. Optional: Center the window
	var screen_center = DisplayServer.screen_get_size() / 2
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position(screen_center - window_size / 2)
	
func toggle_menu():
	menu.visible = not menu.visible
	return
	

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Toggle Menu"):
		toggle_menu()

func set_img(file, tex_rect: TextureRect = TextureRect.new()) -> TextureRect:
	var image = Image.new()
	var image_texture = ImageTexture.new()
	var gif
	if file.get_extension().to_lower() == "gif":
		gif = GifManager.animated_texture_from_file(file)
	else:
		var error = image.load(file)
		if error != OK:
			push_error("Failed to load image! Error code: %d" % error)
			image.load("res://icon.svg")
		image.convert(Image.FORMAT_RGBA8)
		image_texture = ImageTexture.create_from_image(image)
		gif = image_texture
	tex_rect.texture = (gif)
	print(gif.get_size())
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex_size = gif.get_size()
	tex_rect.custom_minimum_size = tex_size
	tex_rect.size = tex_size
	# tex_rect.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	tex_rect.set_script(load("res://scr/overlay_element.gd"))
	tex_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	return tex_rect
	
func create_window(file, saved_pos: Vector2i = Vector2i(400, 400), saved_size: Vector2i = Vector2i(400,300)) -> Window:
	
	var window = Window.new()
	window.add_to_group("save_when_close")
	window.title = "New Window"
	window.borderless = true
	window.unfocusable = true
	window.always_on_top = true
	window.transparent_bg = true
	window.transparent = true
	#window.is_drag
	window.size = saved_size
	window.position = saved_pos
	# Add your UI elements to the window
	var tex_rect = set_img(file)
	window.size = tex_rect.size

	if tex_rect.is_inside_tree():
		tex_rect._ready() 
		tex_rect.set_process(true) # If using _process
	
	window.add_child(tex_rect)
	
	get_tree().root.add_child(window)
	window.set_meta("file_path", file) 
	return window

func load_subwindows(save: String = "user://subwindows.cfg"):
	var config = ConfigFile.new()
	if config.load(save) != OK: return

	for section in config.get_sections():
		var file = config.get_value(section, "file")
		var pos = config.get_value(section, "pos")
		var size = config.get_value(section, "size")
		
		# Create the window using your existing function
		var win = create_window(file, pos, size)
		var tex_rect = win.get_child(0)
		
		# Restore the modifications
		tex_rect.modulate = config.get_value(section, "modulate", Color.WHITE)
		tex_rect.flip_h = config.get_value(section, "flip_h", false)
		tex_rect.flip_v = config.get_value(section, "flip_v", false)
		tex_rect.stretch_mode = config.get_value(section, "stretch_mode", TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		tex_rect.scale = config.get_value(section, "scale", 1)
		if config.has_section_key(section, "material"):
			var mat_path = config.get_value(section, "material", null)
			if mat_path != null:
				tex_rect.material = mat_path
		else:
			tex_rect.material = null
		tex_rect.color_picker.color = config.get_value(section, "picker_color", Color(1, 1, 1, 1))
		tex_rect.chromakey_switch.button_pressed = config.get_value(section, "chromakey_switch_toggle", false)
		if tex_rect.texture is AnimatedTexture:
			tex_rect.texture.speed_scale = config.get_value(section, "speed_scale", 1)

func get_all_save_slots():
	var saves = []
	var dir = DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".cfg"):
				saves.append(file_name.get_basename())
			file_name = dir.get_next()
	return saves
	
func save_all_subwindows(overlay_name: String = "base"):
	var config = ConfigFile.new()
	var windows = get_tree().get_nodes_in_group("save_when_close")
	
	for i in range(windows.size()):
		var win = windows[i]
		var tex_rect = win.get_child(0) # Assumes TextureRect is the first child
		if tex_rect == null:
			continue
		var section = "Window_" + str(i)
		
		# Save Window geometry
		config.set_value(section, "file", win.get_meta("file_path"))
		config.set_value(section, "pos", win.position)
		config.set_value(section, "size", win.size)
		
		# Save TextureRect modifications
		config.set_value(section, "modulate", tex_rect.modulate)
		config.set_value(section, "flip_h", tex_rect.flip_h)
		config.set_value(section, "flip_v", tex_rect.flip_v)
		config.set_value(section, "stretch_mode", tex_rect.stretch_mode)
		config.set_value(section, "scale", tex_rect.scale)
		if tex_rect.material != null:
			config.set_value(section, "material", tex_rect.material)
			config.set_value(section, "picker_color", tex_rect.color_picker.color)
			config.set_value(section, "chromakey_switch_toggle", tex_rect.chromakey_switch.button_pressed)
		config.set_value(section, "stretch_mode", tex_rect.stretch_mode)
		if tex_rect.texture is AnimatedTexture:
			config.set_value(section, "speed_scale", tex_rect.texture.speed_scale)
		# Add any other properties you change (e.g., self_modulate, scale)
		
	config.save("user://" + overlay_name + ".cfg")
	take_preview_screenshot(overlay_name)
	await RenderingServer.frame_post_draw #wait for this to be done drawing so the screenshot is saved
	await get_tree().process_frame # wait for the next frame to give time for the screenshot to be saved
	await get_tree().process_frame # cause I'm paranoid
	overlay_saved.emit(overlay_name) # NOW emit the signal so if a function needs that screenshot I KNOW it is there.

func take_preview_screenshot(overlay_name: String):
	await RenderingServer.frame_post_draw
	
	# 1. Create a large transparent base image (e.g., matching main screen size)
	var base_size = DisplayServer.screen_get_size()
	var final_img = Image.create(base_size.x, base_size.y, false, Image.FORMAT_RGBA8)
	final_img.fill(Color(0, 0, 0, 0)) # Start transparent

	# 2. Add the Main Window first
	#var main_img = get_viewport().get_texture().get_image()
	# final_img.blit_rect(main_img, Rect2i(Vector2i.ZERO, main_img.get_size()), get_window().position)

	# 3. Loop through subwindows and layer them on top
	var windows = get_tree().get_nodes_in_group("save_when_close")
	for win in windows:
		if win is Window:
			var win_img = win.get_viewport().get_texture().get_image()
			# Copy this window's pixels onto our base image at its desktop position
			final_img.blit_rect(win_img, Rect2i(Vector2i.ZERO, win_img.get_size()), win.position)

	# 4. Save the result
	final_img.save_png("user://" + overlay_name + "_preview.png")
	
func remove_all_subwindows():
	var windows = get_tree().get_nodes_in_group("save_when_close")
	for i in range(windows.size()):
		var win = windows[i]
		win.queue_free()
