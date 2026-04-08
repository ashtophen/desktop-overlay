extends PopupPanel

var vbox = VBoxContainer.new()

func _ready():
	var scale_factor = 1.6
	var element_menu_theme = Theme.new()
	element_menu_theme.default_font_size = 16 * scale_factor
	element_menu_theme.set_constant("h_separation", "CheckButton", 10)
	element_menu_theme.set_constant("check_v_offset", "CheckButton", 0)
	element_menu_theme.set_constant("icon_max_width", "CheckButton", 32 * scale_factor)
	
	theme = element_menu_theme
	#add_theme_font_size_override("font_size", 32)
	reset_size()
	add_child(vbox)
	#vbox.add_theme_font_size_override("font_size", 32)
	var handle = ColorRect.new()
	handle.custom_minimum_size = Vector2i(400, 60)
	handle.color = Color(0.2, 0.2, 0.2)
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.set_script(load("res://scr/drag.gd"))
	vbox.add_child(handle)
	
	var handle_label = Label.new()
	handle_label.text = "Use This To Drag"
	# handle_label
	handle.add_child(handle_label)
	
