extends Node

var currTurn := 1

var maxEnergy := 4

var myTurnEnd := false

var opponentTurnEnd := false

var attacking_pos := Vector2i(-1, -1)
var attack_mode := "normal"

@onready var player_board: Node2D = $"../PlayerBoard"

@onready var enemy_board: Node2D = $"../EnemyBoard"


var currEnergy = 4:
	set(value):
		currEnergy = clamp(value, 0, maxEnergy)
		if currEnergy <= 0 and !myTurnEnd:
			end_my_turn()
			

func end_my_turn() -> void:
	myTurnEnd = true
	
	player_board.moving = false
	enemy_board.attacking = false
	
	
	rpc("notify_turn_end_to_opponent")
	
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
		
		await get_tree().create_timer(0.1).timeout
		
		player_board.update_health()
		
		currTurn += 1
		print("currTurn: ", currTurn)
		
		if currTurn > 1 and currTurn % 2 == 1:
			if multiplayer.is_server():
				var side = randi_range(0, 3)
				rpc("map_shrink_all", side)
		
		currEnergy = maxEnergy
		myTurnEnd = false
		opponentTurnEnd = false

func consume_energy(amount: int) -> bool:
	if currEnergy >= amount:
		currEnergy -= amount
		print("Energy remained:", currEnergy)
		return true
	else:
		print("Not enough")
		return false
		

@rpc("any_peer", "call_local")
func map_shrink_all(side: int) -> void:
	player_board._decrease_map_size(side)
	enemy_board._decrease_map_size(side)
	

@rpc("any_peer", "call_local", "reliable")
func declare_winner(loser: int) -> void:
	myTurnEnd = true
	opponentTurnEnd = true
	
	if loser == multiplayer.get_unique_id():
		EndScene.host_won = false
	else:
		EndScene.host_won = true
		
	get_tree().change_scene_to_file("res://end_scene.tscn")
