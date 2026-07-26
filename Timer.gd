extends Node

signal time_up


var time := 60.0

var idle_counter := 0

var max_idle_count := 3

var running := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not running:
		return
	time -= delta
	if time <= 0:
		time = 0
		running = false
		print("Times up")
		time_up.emit()
	

func start_timer() -> void:
	time = 60
	running = true

func add_idle_count() -> void:
	idle_counter += 1

func reset_idle_count() -> void:
	idle_counter = 0
