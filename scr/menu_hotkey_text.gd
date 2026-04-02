extends Label
	
func _ready():
	var hotkey_text = RegEx.create_from_string("^([^ ]*)").search(Globals.toggle_menu_hotkey_text).get_string(1)
	self.text = hotkey_text

func _process(_delta: float) -> void:
	var hotkey_text = RegEx.create_from_string("^([^ ]*)").search(Globals.toggle_menu_hotkey_text).get_string(1)
	self.text = hotkey_text
