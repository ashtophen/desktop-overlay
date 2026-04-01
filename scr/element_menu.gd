extends PopupPanel

var vbox = VBoxContainer.new()

func _ready():
	
	add_child(vbox)
	var handle = ColorRect.new()
	handle.custom_minimum_size = Vector2i(250, 30)
	handle.color = Color(0.2, 0.2, 0.2)
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.set_script(load("res://scr/drag.gd"))
	vbox.add_child(handle)
	
	var handle_label = Label.new()
	handle_label.text = "Use This To Drag"
	handle_label
	handle.add_child(handle_label)
	
