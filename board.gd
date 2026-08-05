extends Node2D

@onready var tilemap = $TileMapLayer
@onready var GameManager = $"../GameManager"

var min_x := 0
var max_x := 14
var min_y := 0
var max_y := 14

# Called when the node enters the scene tree for the first time. 
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _get_cell_loc() -> Vector2i:
		var mouse_pos = get_global_mouse_position()
		
		var local_pos = tilemap.to_local(mouse_pos)
		
		var cell = tilemap.local_to_map(local_pos)
		
		return cell
		
func _inside_board(pos: Vector2i) -> bool:
	return pos.x >= min_x and pos.x <= max_x and pos.y >= min_y and pos.y <= max_y

func _decrease_map_size(side: int) -> void:
	if (max_x - min_x) <= 5 or (max_y - min_y) <=5:
		return
	if side == 0:
		for i in range(min_x, max_x + 1):
			tilemap.set_cell(Vector2i(i, min_y), 1, Vector2i(1, 1))
		min_y += 1
	elif side == 1:
		for i in range(min_x, max_x + 1):
			tilemap.set_cell(Vector2i(i, max_y), 1, Vector2i(1, 1))
		max_y -= 1
	elif side == 2:
		for i in range(min_y, max_y + 1):
			tilemap.set_cell(Vector2i(min_x, i), 1, Vector2i(1, 1))
		min_x += 1
	else:
		for i in range(min_y, max_y + 1):
			tilemap.set_cell(Vector2i(max_x, i), 1, Vector2i(1, 1))
		max_x -= 1
