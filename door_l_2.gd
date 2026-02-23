extends Area2D

@export var next_scene_path: String = "res://level3.tscn"

var player_inside := false

func _on_body_entered(body):
	if body.name == "player":  
		player_inside = true

func _on_body_exited(body):
	if body.name == "player":
		player_inside = false

func _process(delta):
	if player_inside and Input.is_action_just_pressed("Enter"):
		get_tree().change_scene_to_file(next_scene_path)
