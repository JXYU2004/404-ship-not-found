extends Node

var currTurn := 1

var maxEnergy := 4

var myTurnEnd := false

var opponentTurnEnd := false

var selfLost := false

var oppLost := false



var attacking_pos := Vector2i(-1, -1)
var attack_mode := "normal"

@onready var EventManager = $"../EventManager"

@onready var player_board: Node2D = $"../PlayerBoard"

@onready var enemy_board: Node2D = $"../EnemyBoard"

@onready var history = MatchHistoryManager

@onready var undo = $"../UNDO BUTTON"

@onready var ready_button = $"../Button"

var currEnergy = 4:
	set(value):
		currEnergy = clamp(value, 0, maxEnergy)


var energy_surge_active = false
var energy_surge_used = false

func _ready() -> void:
	GlobalTimer.time_up.connect(_on_turn_time_up)
	if NetworkManager.is_syncing:
		rpc_id(NetworkManager.opponent_id, "request_board_state")
	else:
		GlobalTimer.start_timer()

func end_my_turn() -> void:
	myTurnEnd = true
	
	player_board.moving = false
	player_board.dis_able_buttons(true)
	enemy_board.dis_able_buttons(true)
	enemy_board.attacking = false
	
	if NetworkManager.has_valid_opponent():
		rpc_id(NetworkManager.opponent_id, "notify_turn_end_to_opponent")
	
	next_turn()

func setlost() -> void:
	selfLost = true
	
	rpc_id(NetworkManager.opponent_id, "notify_lost_to_opponent")

@rpc("any_peer", "call_remote")
func notify_lost_to_opponent() -> void:
	oppLost = true

@rpc("any_peer", "call_remote")
func notify_turn_end_to_opponent() -> void:
	opponentTurnEnd = true
	next_turn()

func next_turn() -> void:
	if myTurnEnd and opponentTurnEnd:
		player_board.declare_final_pos()
		
		await get_tree().create_timer(0.2).timeout
		
		enemy_board.check_hit_miss()
		player_board.update_radar()
		
		await get_tree().create_timer(0.2).timeout
		
		
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
				
				
		await get_tree().create_timer(0.2).timeout
		
		player_board.check_shrink_zone_damage()
		
		await get_tree().create_timer(0.2).timeout
		
		player_board.check_lose()
		
		await get_tree().create_timer(0.2).timeout
		
		declare_winner(selfLost, oppLost)
		
		if selfLost or oppLost:
			return
		
		player_board.update_health()
		
		currEnergy = maxEnergy
		undo.clear_actions()
		myTurnEnd = false
		opponentTurnEnd = false
		
		ready_button.text = "READY"
		
		player_board.dis_able_buttons(false)
		enemy_board.dis_able_buttons(false)
		GlobalTimer.start_timer()


func consume_energy(amount):

	if currEnergy >= amount:

		currEnergy -= amount
		history.energy_used += amount

		if energy_surge_active \
		and not energy_surge_used \
		and currEnergy <= 2:

			currEnergy += 2

			energy_surge_used = true

			print("Energy Surge Triggered!")
			print("Energy:", currEnergy)

		return true

	return false
		

@rpc("any_peer", "call_remote", "reliable")
func map_shrink_all(side: int) -> void:
	player_board._decrease_map_size(side)
	enemy_board._decrease_map_size(side)

@rpc("any_peer", "call_remote", "reliable")
func trigger_random_event():
	EventManager.trigger_random_event()


func declare_winner(i_lost: bool, opp_lost: bool) -> void:
	
	if !i_lost and !opp_lost:
		return 
		
	myTurnEnd = true
	opponentTurnEnd = true
	
	if i_lost and opp_lost:
		EndScene.is_draw = true
		history.add_entry("Winner: Draw")
	else:
		var winner_id: int
		if i_lost:
			EndScene.host_won = false
			winner_id = NetworkManager.opponent_id
		else:
			EndScene.host_won = true
			winner_id = multiplayer.get_unique_id()
		
		var winner_name = NetworkManager.get_player_steam_name(winner_id)
		history.add_entry("Winner: " + winner_name)
	
	history.add_entry(
		"Total Turns: %d"
		% currTurn
	)
	
	history.save_final_stats(currTurn)
	history.save_match()
	NetworkManager.set_curr_scene("res://end_scene.tscn")
	get_tree().change_scene_to_file("res://end_scene.tscn")


func _on_button_pressed() -> void:
	if !myTurnEnd:
		ready_button.text = "WAITING..."
		GlobalTimer.reset_idle_count()
		end_my_turn()
			
func _on_turn_time_up() -> void:
	if NetworkManager.has_valid_opponent() == false:
		NetworkManager.auto_win_no_opponent()
		return
	if myTurnEnd:
		return
 
	GlobalTimer.idle_counter += 1
	print("Turn timed out. idle_counter: ", GlobalTimer.idle_counter)
 
	if GlobalTimer.idle_counter >= GlobalTimer.max_idle_count:
		print("Idle limit reached, forfeiting match")
		setlost()
		_on_button_pressed()
	else:
		ready_button.text = "WAITING..."
		end_my_turn()

func on_opponent_reconnect_timeout() -> void:
	EndScene.host_won = true
	EndScene.is_draw = false
	
	history.add_entry("Opponent disconnected and did not reconnect")
	history.add_entry("Winner: " + Steam.getPersonaName())
	history.add_entry("Total Turns: %d" % currTurn)
	history.save_match()
	
	get_tree().change_scene_to_file("res://end_scene.tscn")

@rpc("any_peer", "call_remote", "reliable")
func request_board_state() -> void:
	var state = {
		"currTurn": currTurn,
		"has_end_turn": myTurnEnd,
		"player_board": player_board.get_player_state(),
		"enemy_board": enemy_board.get_enemy_state()
	}
	rpc_id(NetworkManager.opponent_id, "receive_board_state", state)

@rpc("any_peer", "call_remote", "reliable")
func receive_board_state(state: Dictionary) -> void:
	
	currTurn = state["currTurn"]
	player_board.load_player_state(state["enemy_board"])
	enemy_board.load_enemy_state(state["player_board"])
	opponentTurnEnd = state["has_end_turn"]
	NetworkManager.is_syncing = false
