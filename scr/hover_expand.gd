extends Button

@onready var source_img = get_child(0).get_child(0)
var popup: PanelContainer = null
var popup_layer: CanvasLayer = null # Store the layer reference

func _ready():
	mouse_entered.connect(_on_button_hovered)
	mouse_exited.connect(_on_button_unhovered)

func _on_button_hovered():
	_on_button_unhovered()
	await get_tree().process_frame
	if source_img:
		show_popup(source_img)

func _on_button_unhovered():
	# Clean up both the layer and the popup
	if is_instance_valid(popup_layer):
		popup_layer.queue_free()
	popup_layer = null
	popup = null

func show_popup(img_to_copy: TextureRect, popup_size: Vector2i = Vector2i(500, 300)):
	# 1. CREATE THE LAYER
	# This keeps the popup on a high "drawing plane" above everything else
	popup_layer = CanvasLayer.new()
	popup_layer.layer = 100 # High number = stays on top
	get_tree().root.add_child(popup_layer)

	# 2. SETUP THE PANEL
	popup = PanelContainer.new()
	popup.custom_minimum_size = popup_size
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE # Clicks pass through
	popup.focus_mode = Control.FOCUS_NONE           # Won't steal keyboard focus
	
	# 3. SETUP THE IMAGE
	var img_copy = img_to_copy.duplicate()
	img_copy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_copy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 4. ASSEMBLY
	popup.add_child(img_copy)
	popup_layer.add_child(popup)
	
	# 5. POSITIONING
	# Since it's in a CanvasLayer, we use the local canvas position
	popup.global_position = get_global_mouse_position() + Vector2(15, 15)
