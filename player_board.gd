extends "res://board.gd"

class_name PlayerBoard
static var curr_layout = null

@export var enemy_board: Node

@onready var submarine: Node2D = $Submarine
@onready var destroyer: Node2D = $Destroyer
@onready var cruiser: Node2D = $Cruiser

@onready var submarine_life = $"Submarine life"
@onready var destroyer_life = $"Destroyer life"
@onready var cruiser_life = $"cruiser life"

var active_ship = null
var moving = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	if curr_layout != null:
		$Submarine.set_ship_pos(curr_layout["Submarine"]["positions"])
		$Submarine.set_is_vertical(curr_layout["Submarine"]["is_vertical"])
		
	
		$"Cruiser".set_ship_pos(curr_layout["Cruiser"]["positions"])
		$"Cruiser".set_is_vertical(curr_layout["Cruiser"]["is_vertical"])
		
	
		$Destroyer.set_ship_pos(curr_layout["Destroyer"]["positions"])
		$Destroyer.set_is_vertical(curr_layout["Destroyer"]["is_vertical"])
	prepare_ship(submarine)
	prepare_ship(cruiser)
	prepare_ship(destroyer)
	submarine_life.set_up(submarine.hit_point)
	destroyer_life.set_up(destroyer.hit_point)
	cruiser_life.set_up(cruiser.hit_point)
	


func prepare_ship(ship: Node2D) -> void:
	
	
	
	var ship_button = ship.get_node_or_null("Ship Button")
	ship_button.pressed.connect(func(): _on_ship_button_pressed(ship))
	
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)


func _on_texture_button_pressed() -> void:
	if enemy_board:
		enemy_board.visible = true
		self.visible = false

func _check_ship_in_board(dir: int) -> bool:
		var add
		if (dir == 0):
			add = Vector2i(-1, 0)
		elif (dir == 1):
			add = Vector2i(0, -1)
		elif (dir == 2):
			add = Vector2i(1, 0)
		else:
			add = Vector2i(0, 1)
			
		for cell in active_ship.positions:
			var new_cell = cell + add
			if !_inside_board(new_cell):
				return false
			
			var all_ships = [submarine, destroyer, cruiser]
			
			for other_ship in all_ships:
				if other_ship == active_ship:
					continue
				if new_cell in other_ship.get_ship_pos():
					return false
		return true


func _on_move_left_pressed() -> void:
	if moving and _check_ship_in_board(0):
		active_ship.global_position.x -= 26
		active_ship.move(0)
		GameManager.consume_energy(1)

func _on_move_up_pressed() -> void:
	if moving and _check_ship_in_board(1):
		active_ship.global_position.y -= 26
		active_ship.move(1)
		GameManager.consume_energy(1)

func _on_move_right_pressed() -> void:
	if moving and _check_ship_in_board(2):
		active_ship.global_position.x += 26
		active_ship.move(2)
		GameManager.consume_energy(1)

func _on_move_down_pressed() -> void:
	if moving and _check_ship_in_board(3):
		active_ship.global_position.y += 26
		active_ship.move(3)
		GameManager.consume_energy(1)

func _on_ship_button_pressed(ship: Node2D) -> void:
	active_ship = ship
	moving = true

func declare_final_pos() -> void:
	var final_position = {
		"Cruiser" = cruiser.get_ship_pos(),
		"Destroyer" = destroyer.get_ship_pos(),
		"Submarine" = submarine.get_ship_pos()
	}
	enemy_board.rpc("receive_final_pos", final_position)

@rpc("any_peer", "call_remote")
func receive_attack(ship_name: String) -> void:
	if ship_name == "destroyer":
		destroyer._on_hit()
		print("destroyer remaining health: ", destroyer.hit_point)
	elif ship_name == "submarine":
		submarine._on_hit()
		print("submarine remaining health: ", submarine.hit_point)
	elif ship_name == "cruiser":
		cruiser._on_hit()
		print("cruiser remaining health: ", cruiser.hit_point)

@rpc("any_peer", "call_remote")
func receive_miss(cell: Vector2i) -> void:
	tilemap.set_cell(cell, 0, Vector2i(1, 0)) ## set cell as exclamation mark

@rpc("any_peer", "call_remote")
func check_lose() -> void:
	if cruiser.sinked and submarine.sinked and destroyer.sinked:
		GameManager.rpc("declare_winner", multiplayer.get_unique_id()) ## declare winner

func update_health() -> void:
	submarine_life.update_health(submarine.hit_point)
	cruiser_life.update_health(cruiser.hit_point)
	destroyer_life.update_health(destroyer.hit_point)
