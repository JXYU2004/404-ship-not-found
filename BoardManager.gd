extends Node

var currEnergy = 4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func consume_energy(amount: int) -> bool:
	if currEnergy >= amount:
		currEnergy -= amount
		print("Energy remained:", currEnergy)
		return true
	else:
		print("Not enough")
		return false
