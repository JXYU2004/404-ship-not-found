extends "res://board.gd"

class_name EnemyBoard

static var opp_layout = null

var attacking := false

var attack_mode := "normal"

var attack_coord : Array[Vector2i] = []
var preview_tiles = []
var current_preview_coords : Array[Vector2i] = []

var hit_count := 0

@onready var cover = $Cover


@onready var submarine: Node2D = $Submarine
@onready var destroyer: Node2D = $Destroyer
@onready var cruiser: Node2D = $Cruiser

@export var player_board: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	if opp_layout != null:
		$Submarine.set_ship_pos(opp_layout["Submarine"]["positions"])
		$Submarine.set_is_vertical(opp_layout ["Submarine"]["is_vertical"])
		
	
		$"Cruiser".set_ship_pos(opp_layout ["Cruiser"]["positions"])
		$"Cruiser".set_is_vertical(opp_layout ["Cruiser"]["is_vertical"])
		
	
		$Destroyer.set_ship_pos(opp_layout ["Destroyer"]["positions"])
		$Destroyer.set_is_vertical(opp_layout ["Destroyer"]["is_vertical"])
	submarine.is_player_ship = false
	cruiser.is_player_ship = false
	destroyer.is_player_ship = false
	prepare_ship(submarine)
	prepare_ship(cruiser)
	prepare_ship(destroyer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)
	
	var attack_cost
	
	if attack_mode == "normal":
		attack_cost = 1
	else:
		attack_cost = 2
	

	if (not attacking) or (GameManager.currEnergy < attack_cost):
		clear_preview()
		return

	var mouse_pos = get_global_mouse_position()

	var local_pos = to_local(mouse_pos)

	var cell = tilemap.local_to_map(local_pos)

	var preview_coords : Array[Vector2i] = []

	if attack_mode == "normal":

		preview_coords.append(cell)

	elif attack_mode == "special":

		for x in range(2):
			for y in range(2):

				preview_coords.append(
					cell + Vector2i(-x, -y)
				)

	elif attack_mode == "special horizontal":

		for x in range(4):

			preview_coords.append(
				cell + Vector2i(-x, 0)
			)

	elif attack_mode == "special vertical":

		for y in range(4):

			preview_coords.append(
				cell + Vector2i(0, -y)
			)

	show_preview(preview_coords)

func prepare_ship(ship: Node2D) -> void:

	var half_tile_offset: Vector2
	
	if ship._is_vertical():
		ship.rotation_degrees = 0
		half_tile_offset = Vector2(0, 13) 
	else:
		ship.rotation_degrees = -90 
		half_tile_offset = Vector2(13, 0) 
		
	var anchor_cell = ship.get_ship_pos()[0]
	var local_pixel_pos = tilemap.map_to_local(anchor_cell)
	
	ship.global_position = tilemap.to_global(local_pixel_pos + half_tile_offset)
	ship.visible = true
	
func _on_texture_button_pressed() -> void:
	if player_board:
		player_board.visible = true  
		self.visible = false
		if attacking:
			attacking = false

func _on_attack_button_pressed() -> void:
	attacking = true
	attack_mode = "normal"
	print("attacking")

func _on_special_attack_pressed() -> void:
	attacking = true
	attack_mode = "special"
	print ("special attacking")	

func _on_special_attack_vertical_pressed() -> void:
	attacking = true
	attack_mode = "special vertical"
	print ("special vertical attacking")


func _on_special_attack_horizontal_pressed() -> void:
	attacking = true
	attack_mode = "special horizontal"
	print ("special horizontal attacking")



func attack_at_pos(pos: Vector2i) -> void:
	var inside_board = _inside_board(pos)
	if attacking and inside_board and GameManager.consume_energy(1):
		cover.set_cell(pos, 0, Vector2i(0,1))
		attacking = false
		
		if not attack_coord.has(pos):
			attack_coord.append(pos)

func special_attack_at_pos(pos: Vector2i) -> void:
	var inside_board = _inside_board(pos)
	if attacking and inside_board and GameManager.consume_energy(2):
		var tiles = area_covered(pos)
		for cell in tiles:
			if _inside_board(cell):
				cover.set_cell(cell, 0, Vector2i(0,1))
				if not attack_coord.has(cell):
					attack_coord.append(cell)
		attacking = false

func special_attack_at_pos_horiorvet(pos: Vector2i) -> void:
	var inside_board = _inside_board(pos)
	if attacking and inside_board and GameManager.consume_energy(2):
		var tiles = area_covered_vertical(pos)
		if (attack_mode == "special horizontal"):
			tiles = area_covered_horizontal(pos)
		for cell in tiles:
			if _inside_board(cell):
				cover.set_cell(cell, 0, Vector2i(0,1))
				if not attack_coord.has(cell):
					attack_coord.append(cell)
		attacking = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and attacking:
		var cell = _get_cell_loc()
		if attack_mode == "normal":

			attack_at_pos(cell)

			clear_preview()
		elif attack_mode == "special":


			special_attack_at_pos(cell)

			clear_preview()
		else:
			

			special_attack_at_pos_horiorvet(cell)

			clear_preview()
			

func area_covered(pos: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	tiles.append(pos)
	tiles.append(pos + Vector2i(-1, 0))
	tiles.append(pos + Vector2i(0, -1))
	tiles.append(pos + Vector2i(-1, -1))
	return tiles

func area_covered_vertical(pos: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	tiles.append(pos)
	tiles.append(pos + Vector2i(0, -1))
	tiles.append(pos + Vector2i(0, -2))
	tiles.append(pos + Vector2i(0, -3))
	return tiles
	
	
func area_covered_horizontal(pos: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	tiles.append(pos)
	tiles.append(pos + Vector2i(1, 0))
	tiles.append(pos + Vector2i(2, 0))
	tiles.append(pos + Vector2i(3, 0))
	return tiles
	
func clear_preview():

	for tile in preview_tiles:
		tile.queue_free()

	preview_tiles.clear()
	
func show_preview(coords: Array[Vector2i]):

	clear_preview()

	current_preview_coords = coords

	for coord in coords:

		var rect = ColorRect.new()

		rect.color = Color(1, 0, 0, 0.35)

		rect.z_index = 100

		var tile_size = tilemap.tile_set.tile_size

		rect.size = Vector2(tile_size)

		rect.position = (
			tilemap.map_to_local(coord)
			- Vector2(tile_size) / 2
		)

		add_child(rect)

		preview_tiles.append(rect)


@rpc("any_peer", "call_remote")
func receive_final_pos(final_position: Dictionary) -> void:
	for ship_name in final_position:
		var ship = get_node(str(ship_name))
		var final_coords = final_position[ship_name]
		ship.set_ship_pos(final_coords as Array)
		prepare_ship(ship)

func check_hit_miss() -> void:
	for cell in attack_coord:
		
		cover.set_cell(cell, -1) ## erase the cell
		
		if cell in destroyer.get_ship_pos():
			player_board.rpc("receive_attack", "destroyer")
		elif cell in submarine.get_ship_pos():
			player_board.rpc("receive_attack", "submarine")
		elif cell in cruiser.get_ship_pos():
			player_board.rpc("receive_attack", "cruiser")
		else:
			player_board.rpc("receive_miss", cell)
	
	attack_coord.clear() ## clear attack coordinates
	
	player_board.rpc("check_lose") ## check win/lose
