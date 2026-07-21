extends Node

var match_log : Array[String] = []
var total_movements = 0
var energy_used = 0
var normal_attacks = 0
var special_attacks = 0
var hits = 0
var misses = 0

func add_entry(entry : String):
	match_log.append(entry)


func save_match():
	
	var file_path = "user://match_history.txt"
	var file = null
	
	if FileAccess.file_exists(file_path):
		file = FileAccess.open(file_path, FileAccess.READ_WRITE)
		if file:
			file.seek_end()
	else:

		file = FileAccess.open(file_path, FileAccess.WRITE)

	file.store_line("===== MATCH SUMMARY =====")

	file.store_line("Movements: %d" % total_movements)
	file.store_line("Energy Used: %d" % energy_used)

	file.store_line("Normal Attacks: %d" % normal_attacks)
	file.store_line("Special Attacks: %d" % special_attacks)

	file.store_line("Hits: %d" % hits)
	file.store_line("Misses: %d" % misses)

	if hits + misses > 0:
		var accuracy = (float(hits) / float(hits + misses)) * 100
		file.store_line("Accuracy: %.1f%%" % accuracy)

	file.store_line("")
	file.store_line("===== TIMELINE =====")

	for line in match_log:
		file.store_line(line)

	file.store_line("")

	file.close()
	match_log.clear()
	
func _ready():
	print("History file location:")
	print(ProjectSettings.globalize_path("user://match_history.txt"))



func _reset_counters() -> void:
	total_movements = 0
	energy_used = 0
	normal_attacks = 0
	special_attacks = 0
	hits = 0
	misses = 0
