extends TextureButton

var actions_stack := []

@onready var game_manager = get_node_or_null("../GameManager")
@onready var player_board = get_node_or_null("../PlayerBoard")
@onready var enemy_board = get_node_or_null("../EnemyBoard")
@onready var ship_manager = get_node_or_null("../ShipManager")

func store_action(data: Dictionary) -> void:
	actions_stack.push_back(data)

func clear_actions() -> void:
	actions_stack.clear()
	
func _on_pressed() -> void:
	if actions_stack.is_empty():
		print("No actions")
		return
		
	var action = actions_stack.pop_back()
	
	match action["type"]:
		
		"movement":
			
			var ship = action["ship"]
			
			ship.set_ship_pos(action["old_pos"])
			
			player_board.animate_ship_to(ship, action["old_global_pos"])
			
			game_manager.currEnergy = action["old_energy"]
			
		"radar":
			
			player_board.clear_all_scans()
			
			player_board.scanned = false
			
			game_manager.currEnergy = action["old_energy"]
		
		
		"attack":
			
			var cells = action["positions"]
			var attacked_before_list = action["attacked_before_list"]
			for cell in cells:
				enemy_board.reset_cover(cell, attacked_before_list[cell])

				enemy_board.remove_attack(cell)
			
			game_manager.currEnergy = action["old_energy"]
		
		"placement":
			
			var ship = action["ship"]
			
			ship_manager.remove_ship(ship)
			
			ship.is_placed = false
			
			ship.positions.clear()
			
			ship.visible = false
			
			
		
			
			
			
	
