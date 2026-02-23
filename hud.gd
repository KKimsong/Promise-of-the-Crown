extends CanvasLayer

@onready var heart_label := $Heart/Label

func _ready():
	# Wait one frame to ensure player exists
	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		# Force update at start
		_on_health_changed(player.health, player.max_health)
	else:
		print("❌ HUD: Player not found")

func _on_health_changed(current: int, max: int):
	heart_label.text = str(current) + "/" + str(max)
	print("HUD updated:", current, "/", max)
