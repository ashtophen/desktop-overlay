extends Button

@onready var settings_menu = $Settings_popup

func _on_pressed():
	settings_menu.visible = not settings_menu.visible
	print(settings_menu.visible)
