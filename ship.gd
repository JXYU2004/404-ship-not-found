extends Node2D

signal ship_clicked(ship_node: Node2D)

@onready var ship_button = $"Ship Button"


var ship_name: String
var length: int
var positions: Array[Vector2i] = []
var is_vertical: bool
var ship_type: String
var hit_point : int
var is_player_ship := true
var sinked := false

func _ready() -> void:
	ship_name = "Destroyer"
	length = 3
	hit_point = length
		

func set_is_vertical(vert: bool) -> void:
	is_vertical = vert

func _is_vertical() -> bool:
	return is_vertical

func set_ship_pos(input: Array[Vector2i]) -> void:
	positions.clear()
	for pos in input:
		positions.append(pos)
	
func get_ship_pos() -> Array[Vector2i]:
	return positions

func move(dir: int) -> void:
	var add
	if (dir == 0):
		add = Vector2i(-1, 0)
	elif (dir == 1):
		add = Vector2i(0, -1)
	elif (dir == 2):
		add = Vector2i(1, 0)
	else:
		add = Vector2i(0, 1)
	
	for i in range(positions.size()):
		positions[i] += add
		

	
func _on_ship_button_pressed() -> void:
	if is_player_ship:
		emit_signal("ship_clicked", self)

func _on_hit() -> void:
	if hit_point > 0:
		hit_point -= 1
	
	if hit_point == 0 and not sinked:
		sinked = true
		ship_button.disabled = true
