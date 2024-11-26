extends ScrollContainer

var max_scroll_length = 0
@onready var scrollbar = get_v_scroll_bar()

func _ready() -> void:
	scrollbar.changed.connect(_on_scrollbar_changed)
	max_scroll_length = scrollbar.max_value

func _on_scrollbar_changed() -> void:
	if max_scroll_length != scrollbar.max_value:
		max_scroll_length = scrollbar.max_value
		self.scroll_vertical = max_scroll_length

func _gui_input(event: InputEvent) -> void:
	# Handle scroll events
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			self.scroll_vertical -= 32  # Adjust scroll speed as needed
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			self.scroll_vertical += 32  # Adjust scroll speed as needed
			return
