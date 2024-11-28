extends Node2D

const Balloon = preload("res://game/code/DialogueWidgets/desktop_balloon.tscn")

var balloon: Node

func _ready():
	balloon = Balloon.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.day_completed.connect(on_day_completed)
	if PlayerStats.current_day == 1:
		balloon.start(load("res://game/dialogues/day_01.dialogue"), "day_01")

func on_day_completed():
	%DayLabel.text = "Day " + str(PlayerStats.current_day)
	%AnimationPlayer.play("fade_to_transition")
	await %AnimationPlayer.animation_finished
	%AnimationPlayer.play("fade_out_transition")
	await %AnimationPlayer.animation_finished
	
	if PlayerStats.current_day == 2:
		balloon = Balloon.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(load("res://game/dialogues/day_02.dialogue"), "day_02")
	elif PlayerStats.current_day == 3:
		balloon = Balloon.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(load("res://game/dialogues/day_03.dialogue"), "day_03")
	else:
		print("Invalid current day: " + str(PlayerStats.current_day))
		
