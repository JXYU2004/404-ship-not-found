extends Node2D

class_name EndScene
static var host_won = false

@onready var label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if host_won:
		label.text = "VICTORY"
	else:
		label.text = "DEFEAT..."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
