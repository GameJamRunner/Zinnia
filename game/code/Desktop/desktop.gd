extends Node2D

const Balloon = preload("res://game/code/DialogueWidgets/desktop_balloon.tscn")
const DIALOGUES = {
	1: "res://game/dialogues/day_01.dialogue",
	2: "res://game/dialogues/day_02.dialogue",
	3: "res://game/dialogues/day_03.dialogue"
}

var balloon: Node

func _ready():
	_setup_balloon()
	if PlayerStats.current_day in DIALOGUES:
		_start_dialogue(PlayerStats.current_day)

func _setup_balloon():
	balloon = Balloon.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.day_completed.connect(on_day_completed)

func _start_dialogue(day: int):
	%DayLabel.text = "Day " + str(PlayerStats.current_day)
	var dialogue_path = DIALOGUES.get(day)
	if dialogue_path:
		balloon.start(load(dialogue_path), "day_%02d" % day)
	else:
		print("Dialogue not found for day: " + str(day))

func on_day_completed():
	%NextDayButton.text = "Day %d\n-> Continue" % (PlayerStats.current_day)
	await _play_animation("fade_to_transition")

func _on_next_day_button_pressed():
	if PlayerStats.current_day in DIALOGUES:
		_setup_balloon()
		_start_dialogue(PlayerStats.current_day)
	else:
		print("Invalid current day: " + str(PlayerStats.current_day))
		return
	await _play_animation("fade_out_transition")

func _play_animation(animation_name: String) -> void:
	%AnimationPlayer.play(animation_name)
	await %AnimationPlayer.animation_finished
