extends AnimatedSprite2D

@onready var GameManager = $"../../GameManager"

func _ready():
	# Set the initial visual state
	update_bar()

func _process(_delta):
	# This ensures the bar updates instantly when the value changes
	update_bar()

func update_bar():
	frame = GameManager.currEnergy
