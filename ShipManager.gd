extends Node

var grid_size: int = 15

var ocean_grid: Dictionary = {}

func place_ship(
	ship: Ship,
	positions: Array[Vector2i]
) -> bool:

	if not are_positions_valid(positions, ship):
		return false

	remove_ship(ship)

	ship.positions = positions

	ship.is_placed = true

	for pos in positions:
		ocean_grid[pos] = ship

	return true

func remove_ship(ship: Ship) -> void:

	for pos in ship.positions:

		if ocean_grid.has(pos):
			ocean_grid.erase(pos)

func are_positions_valid(
	positions: Array[Vector2i],
	ship: Ship
) -> bool:

	for pos in positions:

		if pos.x < 0 or pos.x >= grid_size:
			return false

		if pos.y < 0 or pos.y >= grid_size:
			return false

		if ocean_grid.has(pos):

			if ocean_grid[pos] != ship:
				return false

	return true
