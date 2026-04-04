extends Popup

func _ready() -> void:
	Globals.display_msg.connect(_msg_display)

func _msg_display(msg: String):
	var sys_msg = get_child(2)
	sys_msg.text = msg
	self.show()
