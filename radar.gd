extends TileMapLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func detected(cell: Vector2i) -> void:
	var minions: Array[Vector2i] = [
		Vector2i(0, 1),
		Vector2i(1, 0),
		Vector2i(1, 1)
	]
	
	var chosen_minion = minions.pick_random()
	
	set_cell(cell, 0, chosen_minion)
