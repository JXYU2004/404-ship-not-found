extends Node2D

@onready var host_button = $"Host Button"
@onready var join_button = $"Join Button"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkManager.match_ready.connect(_on_match_ready)

func _disable_buttons() -> void:
	host_button.disabled = true
	join_button.disabled = true
	host_button.text = "Connecting..."

func _on_match_ready() -> void:
	print("Moving to PLacement scene")
	get_tree().change_scene_to_file("res://Placement.tscn")


func _on_host_button_pressed() -> void:
	NetworkManager.host_game()
	_disable_buttons()


func _on_join_button_pressed() -> void:
	NetworkManager.join_game() 
	_disable_buttons()
