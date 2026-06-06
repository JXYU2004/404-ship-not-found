extends Node

signal match_ready

const DEFAULT_PORT = 9999
const DEFAULT_IP = "127.0.0.1"

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT, 2) 
	if error != OK:
		print("Failed to host game: ", error)
		return
	multiplayer.multiplayer_peer = peer

func join_game(ip_address: String = DEFAULT_IP) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, DEFAULT_PORT)
	if error != OK:
		print("Failed to join game: ", error)
		return
	multiplayer.multiplayer_peer = peer

func _on_peer_connected(id: int) -> void:
	print("Opponent connected. Peer ID: ", id)
	match_ready.emit()

func _on_peer_disconnected(id: int) -> void:
	print("Opponent disconnected. Peer ID: ", id)

func _on_server_disconnected() -> void:
	print("Host disconnected.")
	get_tree().change_scene_to_file("res://menu.tscn")

	
