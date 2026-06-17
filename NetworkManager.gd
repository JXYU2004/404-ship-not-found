extends Node

signal match_ready
signal lobby_created_success

var lobby_id :int = 0
var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
var opponent_id := -1

var searching_match := false

func _ready() -> void:
	
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

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func host_lobby(lobby_type: int) -> void:
	print("creating lobby")
	Steam.createLobby(lobby_type, 2)

func on_lobby_created(connect_result: int, new_lobby_id: int) -> void:
	if connect_result == 1:
		lobby_id = new_lobby_id
		print("lobby created, id: ", lobby_id)
		
		if searching_match:
			Steam.setLobbyData(lobby_id, "quick_match", "true")
			Steam.setLobbyData(lobby_id, "version", "1.0")
			
		var error = peer.create_host(0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
			lobby_created_success.emit()
		else:
			searching_match = false
			print("failed to host")

func quick_match() -> void:
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
	
	print("No available lobbies")
	host_lobby(Steam.LOBBY_TYPE_PUBLIC)

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
		
		var host_id = Steam.getLobbyOwner(joined_lobby_id)
		var error = peer.create_client(host_id, 0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
		else:
			print("Failed to start client: ", error)
	
func on_peer_connected(id: int) -> void:
	if id == multiplayer.get_unique_id():
		return
	opponent_id = id
	
	searching_match = false
	
	print("Opponent connected! Peer ID: ", id)
	await get_tree().process_frame
	match_ready.emit()
	
func on_peer_disconnected() -> void:
	print("Opponent disconnected.")
	get_tree().change_scene_to_file("res://menu.tscn")
