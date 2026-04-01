extends Node

var toggle_menu_hotkey_text = InputMap.action_get_events("Toggle Menu")[0].as_text()
var screen_size = DisplayServer.screen_get_size()


var menu: CenterContainer

func _ready():
	# 1. Get the screen size
	var screen_size = DisplayServer.screen_get_size()
	
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
	

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Toggle Menu"):
		toggle_menu()

func set_img(file, tex_rect: TextureRect = TextureRect.new()) -> TextureRect:
	var image = Image.new()
	var image_texture = ImageTexture.new()
	var gif
	if file.get_extension().to_lower() == "gif":
		gif = GifManager.animated_texture_from_file(file)
	else:
		
		image.load(file)
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
	
func create_window(file):
	
	var window = Window.new()
	
	window.title = "New Window"
	window.borderless = true
	window.unfocusable = true
	window.always_on_top = true
	window.transparent_bg = true
	window.transparent = true
	#window.is_drag
	window.size = Vector2i(400, 300)
	window.position = Vector2i(400, 400)
	# Add your UI elements to the window
	var tex_rect = set_img(file)
	window.size = tex_rect.size

	if tex_rect.is_inside_tree():
		tex_rect._ready() 
		tex_rect.set_process(true) # If using _process
	
	window.add_child(tex_rect)
	
	get_tree().root.add_child(window)
