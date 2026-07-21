extends Node2D

class_name EndScene
static var host_won = false
static var is_draw = false

@onready var label = $Label

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
	NetworkManager.clear_saved_lobby_id()
	NetworkManager.reset_match()
	MatchHistoryManager._reset_counters()
	if is_draw:
		label.text = "DRAW"
	elif host_won:
		label.text = "VICTORY"
	else:
		label.text = "DEFEAT..."
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
