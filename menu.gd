extends Node2D

@onready var host_button = $"Host Button"
@onready var invite_button = $"Join Button"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkManager.lobby_created_success.connect(_on_lobby_created)
	NetworkManager.match_ready.connect(_on_match_ready)

func _on_match_ready() -> void:
	print("Moving to PLacement scene")
	get_tree().change_scene_to_file("res://Placement.tscn")

func _on_lobby_created() -> void:
	host_button.hide()
	invite_button.show()

func _on_host_button_pressed() -> void:
	host_button.disabled = true
	NetworkManager.host_lobby()


func _on_join_button_pressed() -> void:
	NetworkManager.open_invite_overlay()
