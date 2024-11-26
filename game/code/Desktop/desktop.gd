extends Node2D

const Balloon = preload("res://game/code/DialogueWidgets/desktop_balloon.tscn")

func _ready():
	var balloon: Node = Balloon.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(load("res://game/dialogues/test.dialogue"), "start")
