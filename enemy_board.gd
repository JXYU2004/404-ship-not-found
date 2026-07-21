extends "res://board.gd"

class_name EnemyBoard

static var opp_layout = null

var attacking := false

var attack_mode := "normal"

var attack_coord : Array[Vector2i] = []
var preview_tiles = []
var current_preview_coords : Array[Vector2i] = []



var hit_count := 0

@onready var undo = $"../UNDO BUTTON"

@onready var cover = $Cover
@onready var history = MatchHistoryManager

@onready var submarine: Node2D = $Submarine
@onready var destroyer: Node2D = $Destroyer
@onready var cruiser: Node2D = $Cruiser

@export var player_board: Node

@onready var submarine_life = $"Submarine life"
@onready var destroyer_life = $"Destroyer life"
@onready var cruiser_life = $"cruiser life"

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
		submarine_life.set_up(submarine.hit_point)
		destroyer_life.set_up(destroyer.hit_point)
		cruiser_life.set_up(cruiser.hit_point)
		


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
				cell + Vector2i(x, 0)
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
		history.normal_attacks += 1
		history.add_entry(
			"Turn %d: Normal Attack used"
			% GameManager.currTurn
		)
		
		var positions = []
		
		var attacked_before_list = {pos: (cover.get_cell_source_id(pos) == -1)}
		
		cover.set_cell(pos, 0, Vector2i(0,1))
		attacking = false
		
		if not attack_coord.has(pos):
			attack_coord.append(pos)
			positions.append(pos)
		
		var data = {
			"type": "attack",
			
			"positions": positions,
			
			"attacked_before_list": attacked_before_list,
			
			"old_energy": GameManager.currEnergy + 1
				
		}
		
		undo.store_action(data)

func special_attack_at_pos(pos: Vector2i) -> void:
	var inside_board = _inside_board(pos)
	if attacking and inside_board and GameManager.consume_energy(2):
		history.special_attacks += 1
		history.add_entry(
			"Turn %d: Cluster Strike used"
			% GameManager.currTurn
		)
		var tiles = area_covered(pos)
		
		var positions = []
		
		var attacked_before_list = {}
		
		for cell in tiles:
			if _inside_board(cell):
				var attacked_before = (cover.get_cell_source_id(cell) == -1)
				attacked_before_list[cell] = attacked_before
				cover.set_cell(cell, 0, Vector2i(0,1))
				if not attack_coord.has(cell):
					attack_coord.append(cell)
					positions.append(cell)
					
		var data = {
			"type": "attack",
			
			"positions": positions,
			
			"attacked_before_list": attacked_before_list,
			
			"old_energy": GameManager.currEnergy + 2
				
		}
		
		undo.store_action(data)
		attacking = false

func special_attack_at_pos_horiorvet(pos: Vector2i) -> void:
	var inside_board = _inside_board(pos)
	if attacking and inside_board and GameManager.consume_energy(2):
		
		history.special_attacks += 1
		
		if attack_mode == "special horizontal":
			history.add_entry(
				"Turn %d: Horizontal Strike used"
				% GameManager.currTurn
			)

		elif attack_mode == "special vertical":
			history.add_entry(
				"Turn %d: Vertical Strike used"
				% GameManager.currTurn
			)
			
		var tiles = area_covered_vertical(pos)
		if (attack_mode == "special horizontal"):
			tiles = area_covered_horizontal(pos)
		
		var positions = []
		
		var attacked_before_list = {}
		
		for cell in tiles:
			if _inside_board(cell):
				var attacked_before = (cover.get_cell_source_id(cell) == -1)
				attacked_before_list[cell] = attacked_before
				cover.set_cell(cell, 0, Vector2i(0,1))
				if not attack_coord.has(cell):
					attack_coord.append(cell)
					positions.append(cell)
					
		var data = {
			"type": "attack",
			
			"positions": positions,
			
			"attacked_before_list": attacked_before_list,
			
			"old_energy": GameManager.currEnergy + 2
				
		}
		
		undo.store_action(data)
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
			history.hits += 1
			history.add_entry(
				"Turn %d: Hit Destroyer at %s"
				% [GameManager.currTurn, str(cell)]
			)
			player_board.rpc_id(NetworkManager.opponent_id, "receive_attack", "destroyer", cell)
		elif cell in submarine.get_ship_pos():
			history.hits += 1
			history.add_entry(
				"Turn %d: Hit Submarine at %s"
				% [GameManager.currTurn, str(cell)]
			)
			player_board.rpc_id(NetworkManager.opponent_id, "receive_attack", "submarine", cell)
		elif cell in cruiser.get_ship_pos():
			history.hits += 1
			history.add_entry(
				"Turn %d: Hit Cruiser at %s"
				% [GameManager.currTurn, str(cell)]
			)
			player_board.rpc_id(NetworkManager.opponent_id, "receive_attack", "cruiser", cell)
		else:
			history.misses += 1
			history.add_entry(
				"Turn %d: Miss at %s"
				% [GameManager.currTurn, str(cell)]
			)
			player_board.rpc_id(NetworkManager.opponent_id, "receive_miss", cell)
	
	attack_coord.clear() ## clear attack coordinates
	

func reset_cover(pos: Vector2i, attacked_before: bool) -> void:
	if attacked_before:
		cover.set_cell(pos, -1)
	else:
		cover.set_cell(pos, 0, Vector2i(1, 0))

func remove_attack(pos: Vector2i) -> void:
	attack_coord.erase(pos)

@rpc("any_peer", "call_remote")
func update_enemy_health(data: Dictionary):
	submarine_life.update_health(data["submarine"])
	cruiser_life.update_health(data["cruiser"])
	destroyer_life.update_health(data["destroyer"])

func disable_special_attacks():
	$Special_Attack.disabled = true
	$"Special_attack(Vertical)".disabled = true
	$"Special_attack(Horizontal)".disabled = true
	

func dis_able_buttons(ending: bool) -> void:
	if player_board.destroyer.sinked == false:
		$Special_Attack.disabled = ending
		$"Special_attack(Vertical)".disabled = ending
		$"Special_attack(Horizontal)".disabled = ending
	$"Attack button".disabled = ending

func get_enemy_state() -> Dictionary:
	return {
		"min_x": min_x,
		"max_x": max_x,
		"min_y": min_y,
		"max_y": max_y,
		
		"submarine": {
			"positions": submarine.get_ship_pos(),
			"vertical": submarine._is_vertical(),
			"hp": submarine.hit_point,
			"sinked": submarine.sinked
			},
		
		"destroyer": {
			"positions": destroyer.get_ship_pos(),
			"vertical": destroyer._is_vertical(),
			"hp": destroyer.hit_point,
			"sinked": destroyer.sinked
			},
		
		"cruiser": {
			"positions": cruiser.get_ship_pos(),
			"vertical": cruiser._is_vertical(),
			"hp": cruiser.hit_point,
			"sinked": cruiser.sinked
			},
		
		"cells": get_enemy_board_cells(),
		
		}

func load_enemy_state(state: Dictionary) -> void:
	min_x = state["min_x"]
	max_x = state["max_x"]
	min_y = state["min_y"]
	max_y = state["max_y"]
	
	restore_ship(submarine, state["submarine"])
	restore_ship(destroyer, state["destroyer"])
	restore_ship(cruiser, state["cruiser"])
	
	submarine_life.update_health(submarine.hit_point)
	destroyer_life.update_health(destroyer.hit_point)
	cruiser_life.update_health(cruiser.hit_point)
	
	redraw_enemy_board(state["cells"])
	

func restore_ship(ship, data):
	ship.set_ship_pos(data["positions"])
	ship.set_is_vertical(data["vertical"])
	
	ship.hit_point = data["hp"]
	ship.sinked = data["sinked"]
	prepare_ship(ship)

func redraw_enemy_board(player_cells: Array) -> void:
	for cell in player_cells:
		if cell["atlas"] == Vector2i(1,0):
			cover.set_cell(cell["pos"], -1)
		elif cell["atlas"] == Vector2i(1,1):
			tilemap.set_cell(cell["pos"], 1, Vector2i(1, 1))
	
	
	
func get_enemy_board_cells() -> Dictionary:
		var cells = []
		for x in range(15):
			for y in range(15):
				var pos = Vector2i(x, y)
				
				cells.append({
					"pos": pos,
					"source": tilemap.get_cell_source_id(pos),
					"atlas": tilemap.get_cell_atlas_coords(pos),
				}) 
		
		var cover_cells = []
		for x in range(15):
			for y in range(15):
				var pos = Vector2i(x, y)
				
				cover_cells.append({
					"pos": pos,
					"source": cover.get_cell_source_id(pos),
				}) 
		return {"cells": cells, "cover_cells": cover_cells}
