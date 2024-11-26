class_name Message
extends HBoxContainer

@onready var character_label = %CharacterLabel
@onready var dialogue_label = %DialogueLabel
	
# Setter for the character name
func set_character_name(name: String) -> void:
	%CharacterLabel.text = name
	%CharacterLabel.visible = not name.is_empty()

# Setter for the dialogue line
func set_dialogue_line(dialogue_line: DialogueLine) -> void:
	%DialogueLabel.dialogue_line = dialogue_line
	%DialogueLabel.show()
	if not dialogue_line.text.is_empty():
		%DialogueLabel.type_out()
		await %DialogueLabel.finished_typing
