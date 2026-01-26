extends Node
var score: int = 0
var mistakes: int = 0
var current_day: int = 1
var is_game_over: bool = false
var game_over_reason: String = ""
var is_simulation: bool = false
# staty
var statusPassangersCount: int = 0
var statusTotalWaitTime: float = 0
var statusMaxWaitTime: float = 0



# KONFIGURACJA DNI:
# target_score: ile pkt trzeba zdobyć
# shift_time: czas trwania dnia w sekundach
# passenger_difficulty: szanse na spawn pasażerów na piętrach od 0 do 5

var days_config = {
	1: { # DZIEŃ 1
		"target_score": 10, 
		"shift_time": 123, 
		"passenger_difficulty": [20, 20, 20, 20, 20, 20]
	},
	2: { # DZIEŃ 2
		"target_score": 10, 
		"shift_time": 10, 
		"passenger_difficulty": [8, 8, 5, 2, 0, 0]
	},
	3: { # DZIEŃ 3
		"target_score": 1800, 
		"shift_time": 180, 
		"passenger_difficulty": [6, 6, 6, 5, 2, 0]
	},
	4: { # DZIEŃ 4
		"target_score": 2800, 
		"shift_time": 210, 
		"passenger_difficulty": [5, 5, 5, 5, 5, 5]
	},
	5: { # DZIEŃ 5
		"target_score": 4000, 
		"shift_time": 240, 
		"passenger_difficulty": [3, 3, 3, 10, 3, 3]
	},
	6: { # DZIEŃ 6
		"target_score": 4000, 
		"shift_time": 240, 
		"passenger_difficulty": [20, 20, 20, 20, 20, 20]
	}
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset_stats():
	score = 0
	mistakes = 0
	is_game_over = false
	game_over_reason = ""
	print("[GLOBAL] Statystyki zresetowane na nowy dzień.")

func add_score(amount: int):
	score += amount

func add_mistake(reason: String):
	mistakes += 1
	if mistakes >= 3:
		game_over("Zbyt wiele błędów (3/3)!")

func game_over(reason: String):
	print("GAME OVER: ", reason)
	is_game_over = true
	game_over_reason = reason
	get_tree().change_scene_to_file("res://UI/ResultScreen.tscn")

func end_day_check():
	var day_settings = days_config.get(current_day, days_config[1])
	
	if score >= day_settings["target_score"]:
		is_game_over = false
		get_tree().change_scene_to_file("res://UI/ResultScreen.tscn")
	else:
		# nie zaliczone
		game_over("Skill issue.")
# pomocnicza funkcja do pobierania trudności dla obecnego dnia
func get_current_difficulty():
	return days_config.get(current_day, days_config[1])["passenger_difficulty"]
	
func get_grade() -> String:
	# pobieramy cel punktowy na dzisiaj
	var day_settings = days_config.get(current_day, days_config[1])
	var target = day_settings["target_score"]
	
	# ocenianie
	if mistakes >= 3: return "F" # JEDZIESZ DO BYDGOSZCZY
	
	if score >= target * 1.5: return "S" # SUPER!!!
	if score >= target * 1.2: return "A" # DOBRZE
	if score >= target: return "B"       # OK
	if score >= target * 0.8: return "C" # MOŻE BYĆ
	return "D"                           # JESCZĘ UJDZIE
