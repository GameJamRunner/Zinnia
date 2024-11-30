extends Node2D

@onready var lies_exposed_label = %LiesExposedLabel
@onready var lies_told_label = %LiesToldLabel
@onready var attachment_label = %AttachmentLabel


func _ready():
	# todo: update all 3 labels
	lies_exposed_label.text = "Lies Exposed : %d/%d" % [PlayerStats.get_total_score(), 3]
	lies_told_label.text = "Lies Told : %d" % PlayerStats.lies_told
	attachment_label.text = "Attachment: %s" % PlayerStats.get_attachment_name()

	$BlackPanel.show()
	$AnimationPlayer.play("black_to_trans")


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://game/code/TitleScene/title_scene.tscn")
