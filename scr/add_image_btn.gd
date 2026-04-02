extends Button

@onready var file_dialog = $"../../../../FileDialog"

func _on_pressed() -> void:
	file_dialog.popup()
	#create_window("res://icon.svg")
	pass # Replace with function body.
