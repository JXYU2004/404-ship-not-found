extends Node
@onready var game_manager = $"../GameManager"

@onready var player_board = $"../PlayerBoard"

@onready var history = $"../MatchHistoryManager"

func trigger_random_current():

	print("Random Ocean Current Activated!")
	
	history.add_entry(
		"Turn %d: Ocean Current activated"
		% game_manager.currTurn
	)

	var direction = randi_range(0,3)
	var distance = randi_range(1,2)

	move_all_ships(direction, distance)
	
func trigger_energy_surge():

	print("Energy Surge Activated!")
	
	history.add_entry(
		"Turn %d: Energy Surge activated"
		% game_manager.currTurn
	)

	game_manager.energy_surge_active = true
	game_manager.energy_surge_used = false
		
func trigger_random_event():

	var event_id = randi_range(0,1)

	match event_id:

		0:
			trigger_random_current()

		1:
			trigger_energy_surge()

func move_all_ships(direction: int, distance: int):
	var ships = [
		player_board.submarine,
		player_board.cruiser,
		player_board.destroyer
	]

	for ship in ships:
		move_ship_random(ship, direction, distance)

	player_board.prepare_ship(player_board.submarine)
	player_board.prepare_ship(player_board.cruiser)
	player_board.prepare_ship(player_board.destroyer)

func move_ship_random(ship, direction: int, distance: int):
	for i in range(distance):
		if can_move_ship(ship, direction):
			ship.move(direction)

func can_move_ship(ship, direction: int) -> bool:
	var add = Vector2i.ZERO

	match direction:
		0:
			add = Vector2i(-1,0)
		1:
			add = Vector2i(0,-1)
		2:
			add = Vector2i(1,0)
		3:
			add = Vector2i(0,1)

	for pos in ship.get_ship_pos():
		var new_pos = pos + add

		if not player_board._inside_board(new_pos):
			return false

	return true
	
