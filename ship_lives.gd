extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_up(health: int) -> void:
	var life = get_children()
	for i in range(life.size()):
		if i >= health:
			life[i].queue_free()

func update_health(new_health: int) -> void:
	var life = get_children()
	for i in range(life.size()):
		life[i].visible = (i < new_health)
