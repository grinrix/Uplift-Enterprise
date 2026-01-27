extends Node

# --- ZMIENNE STANU GRY ---
var score: int = 0
var mistakes: int = 0
var current_day: int = 1
var is_game_over: bool = false
var game_over_reason: String = ""
# Konfiguracja Dni (Poziomy Trudności)
# target_score: ile pkt trzeba zdobyć
# shift_time: czas trwania dnia w sekundach
# passenger_difficulty: szanse na spawn pasażerów na piętrach [0..5]
# Konfiguracja Dni
var days_config = {
	1: { 
		"target_score": 10, 
		"shift_time": 10000, 
		"passenger_difficulty": [20, 0, 0, 0, 0, 0] # Głównie parter i 1 piętro
	},
	2: { 
		"target_score": 10, 
		"shift_time": 10, 
		"passenger_difficulty": [8, 8, 5, 2, 0, 0] # Dochodzą piętra 2-3
	},
	3: { 
		"target_score": 1800, 
		"shift_time": 180, 
		"passenger_difficulty": [6, 6, 6, 5, 2, 0] # Średnio trudno
	},
	4: { 
		"target_score": 2800, 
		"shift_time": 210, 
		"passenger_difficulty": [5, 5, 5, 5, 5, 5] # Pełny ruch na wszystkich piętrach
	},
	5: { 
		"target_score": 4000, 
		"shift_time": 240, 
		"passenger_difficulty": [3, 3, 3, 10, 3, 3] # SZCZYT RUCHU (Piętro 3 zalewane falą)
	},
	6: { 
		"target_score": 4000, 
		"shift_time": 240, 
		"passenger_difficulty": [20, 20, 20, 20, 20, 20] # SZCZYT RUCHU (Piętro 3 zalewane falą)
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
	# Przełączamy na scenę wyników
	get_tree().change_scene_to_file("res://ResultScreen.tscn")

func end_day_check():
	var day_settings = days_config.get(current_day, days_config[1])
	
	if score >= day_settings["target_score"]:
		# Dzień zaliczony - idziemy do ekranu podsumowania
		is_game_over = false
		get_tree().change_scene_to_file("res://ResultScreen.tscn")
	else:
		# Nie zaliczone
		game_over("Skill issue.")
# Pomocnicza funkcja do pobierania trudności dla obecnego dnia
func get_current_difficulty():
	return days_config.get(current_day, days_config[1])["passenger_difficulty"]
	
func get_grade() -> String:
	# Pobieramy cel punktowy na dzisiaj
	var day_settings = days_config.get(current_day, days_config[1])
	var target = day_settings["target_score"]
	
	# Logika oceniania
	if mistakes >= 3: return "F" # Jeśli prawie wyleciałeś
	
	if score >= target * 1.5: return "S" # Super wynik (150% normy)
	if score >= target * 1.2: return "A" # Bardzo dobry (120% normy)
	if score >= target: return "B"       # Norma wykonana
	if score >= target * 0.8: return "C" # Prawie, prawie
	return "D"                           # Słabo, ale zaliczone
