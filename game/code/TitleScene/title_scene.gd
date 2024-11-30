extends Node2D


func _on_button_pressed():
	$Button.disabled = true
	$AudioStreamPlayer.play()
	$AnimationPlayer.play("start_game")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://game/code/Desktop/desktop.tscn")
