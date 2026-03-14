extends Area2D

@export var next_scene_path: String = "res://level2.tscn"

var player_inside := false
var player_ref = null

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		player_ref = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		player_ref = null

func _process(delta):
	if player_inside and Input.is_action_just_pressed("Enter"):
		if player_ref != null and player_ref.has_key:
			player_ref.has_key = false 
			get_tree().change_scene_to_file(next_scene_path)
		else:
			print("Door is locked! You need a key.")
