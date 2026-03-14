extends Area2D

var dialogue_started := false

@onready var dialogue_label = $CanvasLayer/Label

func _ready():
	body_entered.connect(_on_body_entered)
	dialogue_label.visible = false
	await get_tree().create_timer(10.0).timeout
	get_tree().change_scene_to_file("res://MAIN_MENU.tscn")

func _on_body_entered(body):
	if body.name == "player" and not dialogue_started:
		dialogue_started = true
		show_dialogue(body)

func show_dialogue(player):
	# Stop player movement
	player.set_process(false)
	player.set_physics_process(false)

	dialogue_label.visible = true
