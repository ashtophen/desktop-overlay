extends Button

@onready var save_name_input = $LineEdit

func _on_pressed():
	save_name_input.show()

func _on_line_edit_text_submitted(new_text: String) -> void:
	save_name_input.text = ""
	save_name_input.hide()
	Globals.save_all_subwindows(new_text)
