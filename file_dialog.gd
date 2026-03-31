extends FileDialog

func _on_file_selected(path: String):
	Globals.create_window(path)
