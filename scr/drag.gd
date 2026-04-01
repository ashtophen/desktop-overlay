extends Control

var dragging = false
var offset = Vector2.ZERO

# If this script is inside a PopupPanel/Window, get_window() is more reliable
@onready var window = get_window() 

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				# Use global mouse position relative to the screen/window
				offset = get_global_mouse_position()
			else:
				dragging = false
	
	elif event is InputEventMouseMotion and dragging:
		# Calculate the movement delta and apply it to the window position
		var delta = get_global_mouse_position() - offset
		window.position += Vector2i(delta)
