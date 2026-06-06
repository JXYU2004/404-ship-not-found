extends Label

@onready var GameManager = $"../../GameManager"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_turn_text()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	current_turn_text()

func current_turn_text() -> void:
	text = "TURN " + str(GameManager.currTurn)
