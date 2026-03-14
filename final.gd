extends Node2D

@onready var Final: AudioStreamPlayer = $Final

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	Final.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
