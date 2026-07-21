extends Node

signal match_ready
signal lobby_created_success
signal host_failed
signal join_failed

var lobby_id :int = 0
var peer: SteamMultiplayerPeer = null
var opponent_id := -1

var searching_match := false

var current_lobby_type := -1

var tries := 0

var max_tries := randi_range(2, 7)

const SAVE_PATH := "user://lobby_save.dat"

var curr_scene := ""

var is_syncing := false

func _ready() -> void:
	
	get_tree().set_auto_accept_quit(false)
	
	print(get_path())
	
	var init_res: Dictionary = Steam.steamInitEx()
	if init_res["status"] > 0:
		print("failed")
		return
	
	
	Steam.lobby_created.connect(on_lobby_created)
	Steam.lobby_joined.connect(on_lobby_joined)
	Steam.join_requested.connect(on_join_requested)
	Steam.lobby_match_list.connect(on_lobby_match_list)
	
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	
	await get_tree().process_frame
	
	var saved_id := load_saved_lobby_id()
	if saved_id != 0:
		print("Found saved lobby, attempting rejoin: ", saved_id)
		Steam.joinLobby(saved_id)

func _process(_delta: float) -> void:
	Steam.run_callbacks()
	

func host_lobby(lobby_type: int) -> void:
	print("creating lobby")
	current_lobby_type = lobby_type
	Steam.createLobby(lobby_type, 2)

func on_lobby_created(connect_result: int, new_lobby_id: int) -> void:
	if connect_result == 1:
		lobby_id = new_lobby_id
		print("lobby created, id: ", lobby_id)
		
		if searching_match:
			Steam.setLobbyData(lobby_id, "quick_match", "true")
			Steam.setLobbyData(lobby_id, "version", "1.0")
		
		peer = SteamMultiplayerPeer.new()
		var error = peer.create_host(0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
			lobby_created_success.emit()
		else:
			searching_match = false
			host_failed.emit()
			print("failed to host")

func quick_match() -> void:
	tries = 0
	searching_match = true
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE) 
	Steam.addRequestLobbyListStringFilter("quick_match", "true", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.addRequestLobbyListStringFilter("version", "1.0", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func on_lobby_match_list(lobbies: Array) -> void:
	print("Found ", lobbies.size(), " lobbies")
	
	for lobby in lobbies:
		var check_owner = Steam.getLobbyOwner(lobby)
		
		if check_owner == Steam.getSteamID():
			continue
			
		var members = Steam.getNumLobbyMembers(lobby)
		
		if members < 2:
			print("Joining lobby ", lobby)
			Steam.joinLobby(lobby)
			return
	
	tries += 1
	
	if tries >= max_tries:
		print("No available lobbies")
		host_lobby(Steam.LOBBY_TYPE_PUBLIC)
	else:
		var delay := randf_range(1.0, 2.5) 
		await get_tree().create_timer(delay).timeout
		if not searching_match:
			return
		Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE) 
		Steam.addRequestLobbyListStringFilter("quick_match", "true", Steam.LOBBY_COMPARISON_EQUAL)
		Steam.addRequestLobbyListStringFilter("version", "1.0", Steam.LOBBY_COMPARISON_EQUAL)
		Steam.requestLobbyList()

func open_invite_overlay() -> void:
	if lobby_id != 0:
		Steam.activateGameOverlayInviteDialog(lobby_id)
	
func on_join_requested(requested_lobby_id: int, _friend_id: int) -> void:
	print("Accepted invite! Joining lobby: ", requested_lobby_id)
	Steam.joinLobby(requested_lobby_id)

func on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == 1:
		if multiplayer.multiplayer_peer != null:
			multiplayer.multiplayer_peer.close()
		
		searching_match = false
		
		lobby_id = joined_lobby_id
		var host_id = Steam.getLobbyOwner(joined_lobby_id)
		peer = SteamMultiplayerPeer.new() 
		var error = peer.create_client(host_id, 0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
		else:
			join_failed.emit() 
			clear_saved_lobby_id()
			print("Failed to start client: ", error)
	else:
		join_failed.emit()
		clear_saved_lobby_id()
		print("failed to join lobby")
	
func on_peer_connected(id: int) -> void:
	if id == multiplayer.get_unique_id():
		return
	
	
	opponent_id = id
	
	searching_match = false
	
	print("Opponent connected! Peer ID: ", id)
	
	if is_host():
		Steam.setLobbyData(lobby_id, "quick_match", "false")
	
	save_lobby_id(lobby_id)
	
	rpc_id(id, "receive_scene_sync", curr_scene)
	
	await get_tree().process_frame
	match_ready.emit()

func get_steam_id_for_peer(peer_id: int) -> int:
	return peer.get_peer_steam_id(peer_id)
	
func on_peer_disconnected(id: int) -> void:
	print("Opponent disconnected. Peer id:", id)
	#reset_match()
	#get_tree().change_scene_to_file("res://menu.tscn")

func is_host() -> bool:
	return Steam.getSteamID() == Steam.getLobbyOwner(lobby_id)

func reset_match() -> void:
	searching_match = false
	opponent_id = -1
	current_lobby_type = -1

	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	peer = null

	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
	
	
	GlobalTimer.reset_idle_count()
	
	curr_scene = ""

func get_player_steam_name(id: int) -> String:
	if id == multiplayer.get_unique_id():
		return Steam.getPersonaName()
		
	var opponent_steam_id: int = 0
	if is_host():
		opponent_steam_id = Steam.getLobbyMemberByIndex(lobby_id, 1)
	else:
		opponent_steam_id = Steam.getLobbyOwner(lobby_id)

	if opponent_steam_id != 0:
		return Steam.getFriendPersonaName(opponent_steam_id)
		
	return "Unknown opponent"
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		#reset_match()
		get_tree().quit()

func save_lobby_id(id: int) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"lobby_id": str(id)}))
		file.close()

func load_saved_lobby_id() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	if typeof(data) == TYPE_DICTIONARY and data.has("lobby_id"):
		return int(data["lobby_id"])
	return 0

func clear_saved_lobby_id() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var err := DirAccess.remove_absolute(SAVE_PATH)
		if err != OK:
			print("Failed to clear saved lobby id, error: ", err)

func set_curr_scene(current_scene: String) -> void:
	curr_scene = current_scene
	
@rpc("any_peer", "call_remote", "reliable")
func receive_scene_sync(path: String) -> void:
	if path != "":
		curr_scene = path
		is_syncing = true
		get_tree().call_deferred("change_scene_to_file", path)

func has_valid_opponent() -> bool:
	return opponent_id in multiplayer.get_peers()

func auto_win_no_opponent() -> void:
	EndScene.host_won = true
	EndScene.is_draw = false
	
	MatchHistoryManager.add_entry("Opponent disconnected during placement")
	MatchHistoryManager.add_entry("Winner: " + Steam.getPersonaName())
	MatchHistoryManager.save_match()
	
	get_tree().change_scene_to_file("res://end_scene.tscn")
