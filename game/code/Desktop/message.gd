class_name Message
extends HBoxContainer

@onready var character_label: RichTextLabel = $CharacterLabel
@onready var dialogue_label: DialogueLabel = $DialogueLabel

# Setter for the character name
func set_character_name(name: String) -> void:
	character_label.text = name
	character_label.visible = not name.is_empty()

# Setter for the dialogue line
func set_dialogue_line(dialogue_line: DialogueLine) -> void:
	dialogue_label.dialogue_line = dialogue_line
	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing
