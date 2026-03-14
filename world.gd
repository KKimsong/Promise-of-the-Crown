extends Node2D

@onready var L1sound: AudioStreamPlayer = $L1sound

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	L1sound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
