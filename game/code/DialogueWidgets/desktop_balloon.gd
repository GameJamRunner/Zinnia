extends CanvasLayer

## A basic dialogue balloon for use with Dialogue Manager.

## The action to use for advancing the dialogue
@export var next_action: StringName = "ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = "ui_cancel"

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

var _locale: String = TranslationServer.get_locale()

var current_quote: String

## The base balloon anchor
@onready var balloon: Control = %Balloon

@onready var narrator_label: DialogueLabel = %NarratorLabel

## The container for message history
@onready var message_history: VBoxContainer = %MessageHistory

## The scroll container
@onready var message_scroll_container: ScrollContainer = %MessageScrollContainer

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

signal reply_button_pressed(dialogue_line_text: String)

signal day_completed()

## The current line
var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		is_waiting_for_input = false
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()

		# The dialogue has finished, so close the balloon
		if not next_dialogue_line:
			PlayerStats.current_day += 1
			emit_signal("day_completed")
			queue_free()
			return

		# If the node isn't ready yet, then none of the labels will be ready yet either
		if not is_node_ready():
			await ready

		dialogue_line = next_dialogue_line

		# Hide the narrator_label (we'll show it later if needed)
		narrator_label.hide()
		narrator_label.text = ""  # Optionally clear the text

		# Determine the type of line, treating "tutorial" as "narrator"
		var is_narrator = dialogue_line.character == "narrator" or dialogue_line.character == "tutorial"
		var is_timestamp = dialogue_line.character == "time"
		
		if dialogue_line.character == "narrator":
			%IrinaPortrait.show()
		else:
			%IrinaPortrait.hide()

		responses_menu.hide()
		responses_menu.set_responses(dialogue_line.responses)

		# Show our balloon
		balloon.show()
		will_hide_balloon = false

		if is_narrator:
			# Use narrator_label as before
			await display_narrator_line(dialogue_line)
		elif is_timestamp:
			# Create a new TimeStamp instance
			var timestamp = preload("res://game/code/Desktop/timestamp.tscn").instantiate()
			# Add the timestamp to MessageHistory
			message_history.add_child(timestamp)
			# Set the time
			timestamp.set_time(dialogue_line.text)
		else:
			# Create a new Message instance for non-narrator lines
			var message = preload("res://game/code/Desktop/message.tscn").instantiate()
			message.connect("reply_button_pressed", Callable(self, "_on_message_reply_button_pressed"))
			# Add the message to MessageHistory
			message_history.add_child(message)
			# Set up the message
			await display_dialogue_line(dialogue_line, message)

		# Wait for input
		if dialogue_line.responses.size() > 0:
			balloon.focus_mode = Control.FOCUS_NONE
			responses_menu.show()
		elif dialogue_line.time != "":
			var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next(dialogue_line.next_id)
		else:
			is_waiting_for_input = true
			balloon.focus_mode = Control.FOCUS_ALL
			balloon.grab_focus()
	get:
		return dialogue_line

func _ready() -> void:
	balloon.hide()
	%Background.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

func _unhandled_input(event: InputEvent) -> void:
	# Only handle specific input events
	if is_waiting_for_input and balloon.visible:
		if event.is_action_pressed(next_action) or event.is_action_pressed(skip_action):
			# Handle the input event
			get_viewport().set_input_as_handled()
			_on_balloon_gui_input(event)

func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_line):
		_locale = TranslationServer.get_locale()
		if narrator_label.visible:
			var visible_ratio = narrator_label.visible_ratio
			self.dialogue_line = await resource.get_next_dialogue_line(dialogue_line.id)
			if visible_ratio < 1:
				narrator_label.skip_typing()
		else:
			var current_message = message_history.get_child(message_history.get_child_count() - 1)
			var visible_ratio = current_message.dialogue_label.visible_ratio
			self.dialogue_line = await resource.get_next_dialogue_line(dialogue_line.id)
			if visible_ratio < 1:
				current_message.dialogue_label.skip_typing()

## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)

## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)

# Helper function to display the dialogue line for non-narrator characters
func display_dialogue_line(dialogue_line: DialogueLine, message: Message) -> void:
	# Set the character name
	var character_name = tr(dialogue_line.character, "dialogue")
	message.set_character_name(character_name)
	# Set the dialogue line
	await message.set_dialogue_line(dialogue_line)

# Helper function to display the dialogue line for the narrator
func display_narrator_line(dialogue_line: DialogueLine) -> void:
	narrator_label.bbcode_enabled = true
	narrator_label.dialogue_line = dialogue_line
	if dialogue_line.character == "tutorial":
		dialogue_line.text = "[color=purple]TUTORIAL: " + dialogue_line.text + "[/color]"
	# Wrap the text with center tags
	narrator_label.dialogue_line.text = "[center]" + dialogue_line.text + "[/center]"
	narrator_label.show()
	if not dialogue_line.text.is_empty():
		narrator_label.type_out()
		await narrator_label.finished_typing
		
func recall_message() -> void:
	if message_history.get_child_count() > 0:
		var last_child = message_history.get_child(message_history.get_child_count() - 1)
		message_history.remove_child(last_child)
		last_child.queue_free()

func toggle_all_reply_buttons():
	for message in message_history.get_children():
		if message.has_method("toggle_reply_button"):
			message.toggle_reply_button()

func set_current_puzzle(puzzle: String):
	PlayerStats.set_current_puzzle(puzzle)

func add_answer_to_puzzle(puzzle: String):
	if message_history.get_child_count() > 0:
		var last_child = message_history.get_child(message_history.get_child_count() - 1)
		var answer = last_child.dialogue_label.text
		PlayerStats.add_answer(puzzle, answer)

func add_quote():
	var message = preload("res://game/code/Desktop/message.tscn").instantiate()
	message.set_up_quote(current_quote)
	message_history.add_child(message)

func set_var(_var: bool, state:bool):
	_var = state

#region Signals

func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	get_tree().create_timer(0.1).timeout.connect(func():
		if will_hide_balloon:
			will_hide_balloon = false
			balloon.hide()
	)

func _on_balloon_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and (event.button_index == MOUSE_BUTTON_WHEEL_UP || event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		message_scroll_container._gui_input(event)
		return
	# Handle skipping typing effect
	var current_label

	if narrator_label.visible:
		current_label = narrator_label
	else:
		var last_child = message_history.get_child(message_history.get_child_count() - 1)
		if last_child is Message:
			var current_message = last_child as Message
			current_label = current_message.dialogue_label
		else:
			current_label = null  # No label to handle

	if current_label and current_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			current_label.skip_typing()
			return

	# Handle advancing dialogue when waiting for input
	if is_waiting_for_input and dialogue_line.responses.size() == 0:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var next_button_was_pressed: bool = event.is_action_pressed(next_action)
		if mouse_was_clicked or next_button_was_pressed:
			get_viewport().set_input_as_handled()
			next(dialogue_line.next_id)
			return

func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)

func _on_message_reply_button_pressed(dialogue_text: String) -> void:
	print("Reply button pressed with dialogue:", dialogue_text)
	emit_signal("reply_button_pressed",dialogue_text)

func wait_for_reply() -> bool:
	var dialogue_line_text = await self.reply_button_pressed
	current_quote = dialogue_line_text
	print("current_quote:", current_quote)
	return PlayerStats.is_correct_answer(dialogue_line_text)
	
#endregion
