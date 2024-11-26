extends Node2D

func _ready():
	DialogueManager.show_example_dialogue_balloon(load("res://game/dialogues/test.dialogue"))
