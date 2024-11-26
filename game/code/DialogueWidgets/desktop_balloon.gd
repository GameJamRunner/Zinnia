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

## The base balloon anchor
@onready var balloon: Control = $Balloon

@onready var narrator_label: DialogueLabel = $NarratorLabel

## The container for message history
@onready var message_history: VBoxContainer = %MessageHistory

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

## The current line
var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		is_waiting_for_input = false
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()

		# The dialogue has finished, so close the balloon
		if not next_dialogue_line:
			queue_free()
			return

		# If the node isn't ready yet, then none of the labels will be ready yet either
		if not is_node_ready():
			await ready

		dialogue_line = next_dialogue_line

		# Hide the narrator_label (we'll show it later if needed)
		narrator_label.hide()
		narrator_label.text = ""  # Optionally clear the text

		# Determine if the character is the narrator
		var is_narrator = dialogue_line.character == "narrator"

		%ResponsesMenu.hide()
		%ResponsesMenu.set_responses(dialogue_line.responses)

		# Show our balloon
		balloon.show()
		will_hide_balloon = false

		if is_narrator:
			# Use narrator_label as before
			await display_narrator_line(dialogue_line)
		else:
			# Create a new Message instance for non-narrator lines
			var message = preload("res://game/code/Desktop/message.tscn").instantiate()
			# Add the message to MessageHistory
			%MessageHistory.add_child(message)
			# Set up the message
			await display_dialogue_line(dialogue_line, message)

		# Wait for input
		if dialogue_line.responses.size() > 0:
			balloon.focus_mode = Control.FOCUS_NONE
			%ResponsesMenu.show()
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
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if %ResponsesMenu.next_action.is_empty():
		%ResponsesMenu.next_action = next_action

func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()

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
			var current_message = %MessageHistory.get_child(%MessageHistory.get_child_count() - 1)
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
	# Wrap the text with center tags
	narrator_label.dialogue_line.text = "[center]" + dialogue_line.text + "[/center]"
	narrator_label.show()
	if not dialogue_line.text.is_empty():
		narrator_label.type_out()
		await narrator_label.finished_typing

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
	# Handle skipping typing effect
	var current_label

	if narrator_label.visible:
		current_label = narrator_label
	else:
		var current_message = %MessageHistory.get_child(%MessageHistory.get_child_count() - 1) as Message
		current_label = current_message.dialogue_label

	if current_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			current_label.skip_typing()
			return

	if not is_waiting_for_input:
		return
	if dialogue_line.responses.size() > 0:
		return

	# When there are no response options, the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)

func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)

#endregion
