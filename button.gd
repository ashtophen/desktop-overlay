extends Button
var is_editing = false

func _ready():
	var events = InputMap.action_get_events("Toggle Menu")
	self.text = events.reduce(join, "")
	self.pressed.connect(on_press)

func join(acc, event):
	if acc == "":
		acc += event.as_text().replace(" - Physical", "")
	else:
		acc += ", " + event.as_text().replace(" - Physical", "")

	return acc
	
func _input(event):
	if is_editing:
		if event is InputEventKey:
			set_event(event)
		elif event.is_pressed():
			set_event(null)

func on_press():
	is_editing = true
	self.text = "[Recording New Hotkey]"

func set_event(event):
	is_editing = false
	
	if event !=null:
		var mappings = InputMap.action_get_events("Toggle Menu")
		if mappings.size() > 2:
			InputMap.action_erase_event("Toggle Menu", mappings[1])
		
		InputMap.action_add_event("Toggle Menu", event)
	self.text = InputMap.action_get_events("Toggle Menu").reduce(join, "")
