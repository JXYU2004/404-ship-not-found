extends Node

var match_log : Array[String] = []

func add_entry(entry : String):
	match_log.append(entry)

func save_match():

	var file = FileAccess.open(
		"user://match_history.txt",
		FileAccess.READ_WRITE
	)

	file.seek_end()

	file.store_line("===================")
	file.store_line("New Match")

	for line in match_log:
		file.store_line(line)

	file.store_line("")

	file.close()

	match_log.clear()
	
func _ready():
	print("History file location:")
	print(ProjectSettings.globalize_path("user://match_history.txt"))
