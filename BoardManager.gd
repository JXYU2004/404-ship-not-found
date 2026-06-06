extends Node

var currTurn = 3

var maxEnergy = 4

var currEnergy = 3:
	set(value):
		currEnergy = clamp(value, 0, maxEnergy)
		if currEnergy <= 0:
			next_turn()

func next_turn() -> void:
	currTurn += 1
	print("currTurn: ", currTurn)
	currEnergy = maxEnergy

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
