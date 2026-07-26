extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not GlobalTimer.running:
		text = "--"
		return
	
	var seconds_left : int = ceil(GlobalTimer.time)
	text = "%d" % seconds_left
	
	if seconds_left <= 10:
		modulate = Color.RED
	else:
		modulate = Color.BLACK
