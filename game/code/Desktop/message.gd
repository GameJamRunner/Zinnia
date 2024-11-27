class_name Message
extends HBoxContainer

@onready var character_label = %CharacterLabel
@onready var dialogue_label = %DialogueLabel

@onready var avatar = %Avatar
@onready var nine_patch_rect = %NinePatchRect

# Dictionary mapping character names to avatar textures
@export var avatar_textures: Dictionary = {
	"Aria": preload("res://game/assets/avatar_aria.png"),
	"Irina": preload("res://game/assets/avatar_irina.png"),
}

# Dictionary mapping character names to nine-patch rect textures
@export var nine_patch_textures: Dictionary = {
	"Aria": preload("res://game/assets/dialogue_box_aria.png"),
	"Irina": preload("res://game/assets/dialogue_box_irina.png"),
}

# Default textures for unknown characters
@export var default_avatar_texture = preload("res://game/assets/avatar_aria.png")
@export var default_nine_patch_texture = preload("res://game/assets/dialogue_box_aria.png")

# Setter for the character name
func set_character_name(name: String) -> void:
	%CharacterLabel.text = name
	%CharacterLabel.visible = not name.is_empty()
	
	# Update the avatar texture
	var avatar_texture = avatar_textures.get(name, default_avatar_texture)
	%Avatar.texture = avatar_texture
	
	# Update the nine-patch rect texture
	var nine_patch_texture = nine_patch_textures.get(name, default_nine_patch_texture)
	%NinePatchRect.texture = nine_patch_texture

# Setter for the dialogue line
func set_dialogue_line(dialogue_line: DialogueLine) -> void:
	%DialogueLabel.dialogue_line = dialogue_line
	%DialogueLabel.show()
	if not dialogue_line.text.is_empty():
		%DialogueLabel.type_out()
		await %DialogueLabel.finished_typing
