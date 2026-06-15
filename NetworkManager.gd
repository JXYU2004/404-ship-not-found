extends Node

signal match_ready
signal lobby_created_success

var lobby_id :int = 0
var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
var processed_peers: Array[int] = []

func _ready() -> void:
	
	print(get_path())
	
	var init_res: Dictionary = Steam.steamInitEx()
	if init_res["status"] > 0:
		print("failed")
		return
	
	Steam.lobby_created.connect(on_lobby_created)
	Steam.lobby_joined.connect(on_lobby_joined)
	Steam.join_requested.connect(on_join_requested)
	
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func host_lobby() -> void:
	print("creating lobby")
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 2)

func on_lobby_created(connect_result: int, new_lobby_id: int) -> void:
	if connect_result == 1:
		lobby_id = new_lobby_id
		print("lobby created, id: ", lobby_id)
		
		var error = peer.create_host(0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
			lobby_created_success.emit()
		else:
			print("failed to host")

func open_invite_overlay() -> void:
	if lobby_id != 0:
		Steam.activateGameOverlayInviteDialog(lobby_id)
	
func on_join_requested(requested_lobby_id: int, _friend_id: int) -> void:
	print("Accepted invite! Joining lobby: ", requested_lobby_id)
	Steam.joinLobby(requested_lobby_id)

func on_lobby_joined(joined_lobby_id, _permissions, _locked, response):
	if response == 1:
		if multiplayer.multiplayer_peer != null:
			multiplayer.multiplayer_peer.close()
		
		var host_id = Steam.getLobbyOwner(joined_lobby_id)
		var error = peer.create_client(host_id, 0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
		else:
			print("Failed to start client: ", error)
	
func on_peer_connected(id: int) -> void:
	if id == multiplayer.get_unique_id():
		return
	if id in processed_peers:
		return
	processed_peers.append(id)
	
	print("Opponent connected! Peer ID: ", id)
	await get_tree().process_frame
	match_ready.emit()
	
func on_peer_disconnected() -> void:
	print("Opponent disconnected.")
	get_tree().change_scene_to_file("res://menu.tscn")
