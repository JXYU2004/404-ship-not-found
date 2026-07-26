extends Node2D

class_name EndScene
static var host_won = false
static var is_draw = false


@onready var turns = $VBoxContainer/TurnsLabel
@onready var movement = $VBoxContainer2/MovementLabel
@onready var energy = $VBoxContainer/EnergyLabel
@onready var attacks = $VBoxContainer2/AttackLabel
@onready var special = $VBoxContainer/SpecialAttackLabel
@onready var accuracy = $VBoxContainer2/AccuracyLabel

@onready var label = $TitleLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if NetworkManager.is_syncing:
		rpc_id(NetworkManager.opponent_id, "request_match_result")
	else:
		finalize_result()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func request_match_result() -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	rpc_id(sender_id, "receive_match_result", is_draw, host_won)

@rpc("any_peer", "call_remote", "reliable")
func receive_match_result(opp_is_draw: bool, opp_host_won: bool) -> void:
	is_draw = opp_is_draw
	host_won = opp_is_draw or not opp_host_won

	NetworkManager.is_syncing = false
	finalize_result()

func finalize_result() -> void:
	if is_draw:
		label.text = "DRAW"
	elif host_won:
		label.text = "VICTORY"
	else:
		label.text = "DEFEAT..."
	
	turns.text = "Turns Played: %d" % MatchHistoryManager.final_turns

	movement.text = "Movements: %d" % MatchHistoryManager.final_movements

	energy.text = "Energy Used: %d" % MatchHistoryManager.final_energy_used

	attacks.text = "Normal Attacks: %d" % MatchHistoryManager.final_normal_attacks

	special.text = "Special Attacks: %d" % MatchHistoryManager.final_special_attacks

	accuracy.text = "Accuracy: %.1f%%" % MatchHistoryManager.final_accuracy
	
	NetworkManager.clear_saved_lobby_id()
	NetworkManager.reset_match()
	MatchHistoryManager.reset_counters()
	
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
	
