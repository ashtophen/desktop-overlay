extends CheckBox

# _on_pressed():

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings/system_settings.cfg") != OK: return
	self.button_pressed = config.get_value("Settings", "on_startup", false)
	if not DirAccess.dir_exists_absolute("user://settings/"):
		DirAccess.make_dir_recursive_absolute("user://settings/")

func _on_toggled(toggled_on: bool) -> void:
	var  config = ConfigFile.new()

	if toggled_on:
		enable_startup_windows()
		config.set_value("Settings", "on_startup", toggled_on)
		config.save("user://settings/system_settings.cfg")
	else:
		config.set_value("Settings", "on_startup", toggled_on)
		config.save("user://settings/system_settings.cfg")
		disable_startup_windows()


func enable_startup_windows():
	var app_path = OS.get_executable_path().replace("/", "\\")
	var key_path = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
	var app_name = get_window().name
	
	var command = "reg"
	var args = ["add", key_path, "/v", app_name, "/t", "REG_SZ", "/d", app_path, "/f"]
	
	OS.execute(command, args, [], false)
	print("Startup entry added.")
	
func disable_startup_windows():
	var key_path = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
	var app_name = get_window().name
	
	var args = ["delete", key_path, "/v", app_name, "/f"]
	OS.execute("reg", args, [], false)
	
