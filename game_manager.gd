extends Node

var currTurn := 1

var maxEnergy := 4

var myTurnEnd := false

var opponentTurnEnd := false

var attacking_pos := Vector2i(-1, -1)
var attack_mode := "normal"

@onready var EventManager = $"../EventManager"

@onready var player_board: Node2D = $"../PlayerBoard"

@onready var enemy_board: Node2D = $"../EnemyBoard"

@onready var history = $"../MatchHistoryManager"

@onready var undo = $"../UNDO BUTTON"

var currEnergy = 4:
	set(value):
		currEnergy = clamp(value, 0, maxEnergy)
		if currEnergy <= 0 and !myTurnEnd:
			end_my_turn()
			

var energy_surge_active = false
var energy_surge_used = false

func end_my_turn() -> void:
	myTurnEnd = true
	
	player_board.moving = false
	enemy_board.attacking = false
	
	
	rpc_id(NetworkManager.opponent_id, "notify_turn_end_to_opponent")
	
	next_turn()

@rpc("any_peer", "call_remote")
func notify_turn_end_to_opponent() -> void:
	opponentTurnEnd = true
	next_turn()

func next_turn() -> void:
	if myTurnEnd and opponentTurnEnd:
		player_board.declare_final_pos()
		
		await get_tree().create_timer(0.1).timeout
		
		enemy_board.check_hit_miss()
		player_board.update_radar()
		
		await get_tree().create_timer(0.1).timeout
	
		
		
		currTurn += 1
		
		history.add_entry(
			"Turn %d started"
			% currTurn
		)
		
		energy_surge_active = false
		energy_surge_used = false
		print("currTurn: ", currTurn)
		
		if NetworkManager.is_host():
			if currTurn > 1 and currTurn % 4 == 0:
				trigger_random_event()
				rpc_id(NetworkManager.opponent_id, "trigger_random_event")
			
			if currTurn > 1 and currTurn % 2 == 1:
				var side = randi_range(0, 3)
				
				map_shrink_all(side)
				
				rpc_id(NetworkManager.opponent_id, "map_shrink_all", side)
				
		player_board.check_shrink_zone_damage()
		
		await get_tree().create_timer(0.1).timeout
		
		player_board.update_health()
		
		currEnergy = maxEnergy
		undo.clear_actions()
		myTurnEnd = false
		opponentTurnEnd = false

func consume_energy(amount):

	if currEnergy >= amount:

		currEnergy -= amount

		if energy_surge_active \
		and not energy_surge_used \
		and currEnergy <= 2:

			currEnergy += 2

			energy_surge_used = true

			print("Energy Surge Triggered!")
			print("Energy:", currEnergy)

		return true

	return false
		

@rpc("any_peer", "call_remote")
func map_shrink_all(side: int) -> void:
	player_board._decrease_map_size(side)
	enemy_board._decrease_map_size(side)

@rpc("any_peer", "call_remote")
func trigger_random_event():
	EventManager.trigger_random_event()

@rpc("any_peer", "call_local", "reliable")
func declare_winner(loser: int) -> void:
	myTurnEnd = true
	opponentTurnEnd = true
	
	if loser == multiplayer.get_unique_id():
		EndScene.host_won = false
	else:
		EndScene.host_won = true
	
	NetworkManager.reset_match()
	get_tree().change_scene_to_file("res://end_scene.tscn")
