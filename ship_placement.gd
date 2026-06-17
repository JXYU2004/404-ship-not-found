extends Node2D

const GRID_SIZE = 15
const CELL_SIZE = 32

const BOARD_OFFSET = Vector2i(-3, -3)

@onready var tile_map = $"../TileMapLayer"

@onready var ship_manager = $"../ShipManager"

var ownself_ready = false

var opponent_ready = false

@onready var ships = {
	"cruiser": $"../Ships/Cruiser",
	"submarine": $"../Ships/Submarine",
	"destroyer": $"../Ships/Destroyer"
}

var current_ship: Ship = null

var dragging := false

func _ready() -> void:

	for ship in ships.values():

		ship.visible = false

		ship.is_placed = false

func _process(_delta: float) -> void:

	if dragging and current_ship != null:

		var mouse_pos = get_global_mouse_position()

		var local_mouse = tile_map.to_local(mouse_pos)

		var grid_pos = (
			tile_map.local_to_map(local_mouse)
			- BOARD_OFFSET
		)

		grid_pos = clamp_to_grid_bounds(grid_pos)

		update_positions(grid_pos)

func _input(event: InputEvent) -> void:

	if current_ship == null:
		return

	if current_ship.is_placed:
		return


	if event is InputEventKey:

		if event.pressed:

			if event.keycode == KEY_SPACE:

				current_ship.is_vertical = !current_ship.is_vertical

				var mouse_pos = get_global_mouse_position()

				var local_mouse = tile_map.to_local(mouse_pos)

				var grid_pos = (
					tile_map.local_to_map(local_mouse)
					- BOARD_OFFSET
				)

				grid_pos = clamp_to_grid_bounds(grid_pos)

				update_positions(grid_pos)


	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):

		if dragging:

			confirm_placement()


func start_placing(ship_name: String) -> void:

	if ship_name not in ships:
		return

	current_ship = ships[ship_name]

	if current_ship.is_placed:
		return

	current_ship.visible = true

	dragging = true

func confirm_placement() -> void:

	if current_ship == null:
		return

	if is_current_position_valid() and ship_manager.place_ship(
		current_ship,
		current_ship.positions
	):

		current_ship.is_placed = true

		dragging = false

		print(current_ship.ship_name + " placed")
		
		print(current_ship.positions)

	else:

		print("Invalid placement")


func update_positions(head: Vector2i) -> void:

	var positions: Array[Vector2i] = []

	for i in range(current_ship.length):

		var offset = (
			Vector2i(0, i)
			if current_ship.is_vertical
			else Vector2i(i, 0)
		)

		positions.append(head + offset)

	current_ship.positions = positions

	update_visuals()

func is_current_position_valid() -> bool:

	if current_ship == null:
		return false

	return ship_manager.are_positions_valid(
		current_ship.positions,
		current_ship
	)

func update_visuals() -> void:

	var head = current_ship.positions[0]

	var pixel_pos = tile_map.map_to_local(
		head + BOARD_OFFSET
	)


	if current_ship.is_vertical:

		current_ship.rotation_degrees = 0

	else:

		current_ship.rotation_degrees = -90


	var offset = Vector2.ZERO

	if current_ship.is_vertical:

		offset.y = (
			(current_ship.length - 1)
			* CELL_SIZE
			/ 2.0
		)

	else:

		offset.x = (
			(current_ship.length - 1)
			* CELL_SIZE
			/ 2.0
		)

	current_ship.global_position = (
		tile_map.to_global(pixel_pos)
		+ offset
	)
	
	if is_current_position_valid():
		current_ship.modulate = Color.WHITE
	else:
		current_ship.modulate = Color(1, 0.4, 0.4)


func clamp_to_grid_bounds(
	head: Vector2i
) -> Vector2i:

	var clamped_head = head

	var max_x = GRID_SIZE - (
		1 if current_ship.is_vertical
		else current_ship.length
	)

	var max_y = GRID_SIZE - (
		current_ship.length if current_ship.is_vertical
		else 1
	)

	clamped_head.x = clampi(
		clamped_head.x,
		0,
		max_x
	)

	clamped_head.y = clampi(
		clamped_head.y,
		0,
		max_y
	)

	return clamped_head


func _check_ready() -> bool:
	for check_ship in ships.values():
		if !check_ship.is_placed:
			return false
	return true

func _on_ready_button_pressed() -> void:
	if _check_ready():
		ownself_ready = true
		var curr_layout = {
			"Cruiser": {
				"positions": ships["cruiser"].positions,
				"is_vertical": ships["cruiser"].is_vertical
			},
			"Submarine": {
				"positions": ships["submarine"].positions,
				"is_vertical": ships["submarine"].is_vertical
			},
			"Destroyer": {
				"positions": ships["destroyer"].positions,
				"is_vertical": ships["destroyer"].is_vertical
			}
		}
		
		PlayerBoard.curr_layout = curr_layout
		
		rpc_id(NetworkManager.opponent_id, "send_layout_to_enemy", curr_layout)
		rpc_id(NetworkManager.opponent_id, "notify_ready_to_opponent")
		
		proceed_to_main()

@rpc("any_peer", "call_remote")
func notify_ready_to_opponent() -> void:
	opponent_ready = true
	proceed_to_main()

@rpc("any_peer", "call_remote")
func send_layout_to_enemy(opponent_layout: Dictionary) -> void:
	EnemyBoard.opp_layout = opponent_layout
	
func proceed_to_main() -> void:
	if ownself_ready and opponent_ready:
		print("Transitioning into the game arena...")
		get_tree().call_deferred("change_scene_to_file", "res://Main.tscn")
		

	

func _on_cruiser_initialise_pressed() -> void:

	start_placing("cruiser")

func _on_submarine_initialise_pressed() -> void:

	start_placing("submarine")

func _on_destroyer_initialise_pressed() -> void:

	start_placing("destroyer")
