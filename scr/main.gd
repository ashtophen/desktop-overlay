extends Control

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("closing and saving")
		Globals.save_all_subwindows()
		get_tree().quit() # Now close the application
		
