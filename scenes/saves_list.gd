extends VBoxContainer

# Path where your saves are located
const SAVE_DIR = "user://"

func _ready():
	refresh_save_list()

func refresh_save_list():
	# Clear existing buttons first
	for child in get_children():
		child.queue_free()
	
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Look for our config files
			if file_name.ends_with(".cfg"):
				var slot_name = file_name.get_basename()
				create_save_slot_ui(slot_name)
			file_name = dir.get_next()

func create_save_slot_ui(slot_name: String):
	# 1. Create a Button that acts as the container
	var btn = Button.new()
	btn.set_script(load("res://scr/hover_expand.gd"))
	btn.custom_minimum_size = Vector2(0, 80) # Height for the preview
	
	# 2. Add an HBox inside the button to layout Preview + Label
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE # Let clicks pass to the button
	btn.add_child(hbox)
	
	# 3. Add the Preview Image
	var preview_rect = TextureRect.new()
	preview_rect.custom_minimum_size = Vector2(100, 0)
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Load the preview PNG if it exists
	var img_path = SAVE_DIR + slot_name + "_preview.png"
	if FileAccess.file_exists(img_path):
		var img = Image.load_from_file(img_path)
		preview_rect.texture = ImageTexture.create_from_image(img)
	
	hbox.add_child(preview_rect)
	
	# 4. Add the Label
	var label = Label.new()
	label.text = slot_name
	hbox.add_child(label)
	
	# 5. Connect the button signal using a lambda
	btn.pressed.connect(func(): _on_slot_selected(slot_name))
	
	add_child(btn)

func _on_slot_selected(slot_name: String):
	print("Loading slot: ", slot_name)
	Globals.load_subwindows(SAVE_DIR + slot_name + ".cfg")
	# Call your global loading function here!
	# globals.load_subwindows(slot_name) 
