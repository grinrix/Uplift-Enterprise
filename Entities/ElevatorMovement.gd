extends Sprite2D

signal floor_reached(floor_number)

enum AlgorithmMode { HEURISTIC, DYNAMIC }
var current_mode = AlgorithmMode.HEURISTIC

# konfiguracja
var current_floor: int = 0
var total_floors: int = 5
var floor_height: float = 100.0 
var base_y_position: float = 0.0 
var travel_speed: float = 0.5 

# stan windy
var is_moving: bool = false
var target_queue: Array = [] 
var doors_open: bool = false
var has_power: bool = true

# zmienna do memoizacji (cache dla dynamic)
var memo = {}
# waga priorytetu
var priority_weight: float = 100.0
# cache dla danych o tłumie
var current_crowd_data = {}


func _ready():
	base_y_position = position.y

func set_power_state(status: bool):
	has_power = status
	if not has_power:
		print("winda zatrzymana z braku prądu!")

func set_mode(is_dp: bool):
	if is_dp:
		current_mode = AlgorithmMode.DYNAMIC
		print("Mode: Dynamic")
	else:
		current_mode = AlgorithmMode.HEURISTIC
		print("Mode: Heuristic")
	recalculate_path()

func _process(delta):
	if not has_power: return 
	
	# automatyczna obsługa kolejki
	if not is_moving and not doors_open and target_queue.size() > 0:
		var next_floor = target_queue.pop_front()
		go_to_floor(next_floor)

func add_stop(floor_number: int):
	#  jeśli winda już tu jest i stoi to otwórz drzwi
	if floor_number == current_floor and not is_moving and not doors_open:
		print("Winda już jest na piętrze ", floor_number, " -> Otwieram drzwi.")
		floor_reached.emit(current_floor)
		doors_open = true
		return

	# jeśli winda już tu jest i ma otwarte drzwi to ignoruj
	if floor_number == current_floor and doors_open:
		return

	# dodanie do kolejki jeśli piętro nie jest duplikatem w kolejce
	if floor_number not in target_queue:
		target_queue.append(floor_number)
		
		# w trybie heurystycznym wstępnie sortujemy
		# w dynamicznym przeliczamy całość
		if current_mode == AlgorithmMode.HEURISTIC:
			target_queue.sort() 
		
		recalculate_path()

func recalculate_path():
	if target_queue.is_empty(): return
	
	match current_mode:
		AlgorithmMode.HEURISTIC:
			optimize_heuristic()
		AlgorithmMode.DYNAMIC:
			optimize_dynamic()
			
	print("Zoptymalizowana kolejka: ", target_queue)

func go_to_floor(target_floor_idx: int):
	if target_floor_idx < 0 or target_floor_idx > total_floors:
		return
	
	if target_floor_idx == current_floor:
		return

	is_moving = true
	# print("jadę na piętro: ", target_floor_idx)
	
	var new_y = base_y_position - (target_floor_idx * floor_height)
	var distance = abs(target_floor_idx - current_floor)
	var travel_time = distance * travel_speed
	
	var tween = create_tween()
	tween.tween_property(self, "position:y", new_y, travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	current_floor = target_floor_idx
	is_moving = false
	# print("dojechałem na piętro: ", current_floor)
	doors_open = true 
	floor_reached.emit(current_floor)

func close_doors():
	if not doors_open: return
	await get_tree().create_timer(0.5).timeout
	doors_open = false
	print("drzwi zamknięte.")

# ALGORYTM HEURYSTYCZNY (Najbliższy Sąsiad)
func optimize_heuristic():
	# kolejka jest sortowana tak aby następny cel był zawsze najbliżej poprzedniego
	var sorted_queue = []
	var temp_queue = target_queue.duplicate()
	var current_pos = current_floor
	
	while not temp_queue.is_empty():
		var nearest_idx = -1
		var min_dist = 9999
		# znajduje najbliższe piętro
		for i in range(temp_queue.size()):
			var dist = abs(temp_queue[i] - current_pos)
			if dist < min_dist:
				min_dist = dist
				nearest_idx = i
				
		# dodaje znalezione do posortowanej i usuwa z tymczasowej		
		var next_floor = temp_queue[nearest_idx]
		sorted_queue.append(next_floor)
		temp_queue.remove_at(nearest_idx)
		# aktualizacja pozycji (symulujemy że winda tam pojechała)
		current_pos = next_floor
		
	target_queue = sorted_queue

# ALGORYTM DYNAMICZNY
func optimize_dynamic():
	# pobierz dane o pasażerach
	var gm = get_tree().root.find_child("GameManager", true, false)
	if gm and gm.has_method("get_crowd_stats"):
		current_crowd_data = gm.get_crowd_stats()
	else:
		# jeśli nie ma gamemanager
		current_crowd_data = {} 
	
	# wyczyść cache przed nowym obliczaniem
	memo.clear()
	
	# uruchom algorytm
	# kopia kolejki jest potrzebna bo będzie modyfikowana w rekurencji
	var result = _solve_dp(current_floor, target_queue.duplicate())
	
	# zastosuj wynik
	if result["path"].size() > 0:
		target_queue = result["path"]
		print("DP Koszt: ", result["cost"], " Trasa: ", target_queue)

# funkcja rekurencyjna z memoizacją
func _solve_dp(curr_node: int, nodes_to_visit: Array) -> Dictionary:
	# brak węzłów do odwiedzenia
	if nodes_to_visit.is_empty():
		return {"cost": 0.0, "path": []}
	
	# sprawdza cache
	# klucz musi być unikalny dla stanu (gdzie jest i co zostało do odwiedzenia)
	# żeby [1,3] i [3,1] było tym samym zbiorze
	var state_key_nodes = nodes_to_visit.duplicate()
	state_key_nodes.sort()
	var state_key = str(curr_node) + "_" + str(state_key_nodes)
	
	if memo.has(state_key):
		return memo[state_key]
	
	# zzukanie najlepszej ścieżki
	var best_solution = {
		"cost": 999999.0, # bardzo duża liczba na start
		"path": []
	}
	
	for i in range(nodes_to_visit.size()):
		var next_node = nodes_to_visit[i]
		
		# obliczanie kosztu kroku
		var dist = abs(next_node - curr_node)
		var people_count = current_crowd_data.get(next_node, 0)
		var priority_bonus = people_count * priority_weight
		var step_cost = dist - priority_bonus
		
		#przygotowanie następnego kroku rekurencji
		var remaining_nodes = nodes_to_visit.duplicate()
		remaining_nodes.remove_at(i)
		# rekurencja
		var sub_problem_result = _solve_dp(next_node, remaining_nodes)
		
		# całkowity koszt tej opcji
		var total_cost = step_cost + sub_problem_result["cost"]
		
		# wybór lepszej opcji
		# sprawdzamy wszystkie opcje
		if total_cost < best_solution["cost"]:
			best_solution["cost"] = total_cost
			# budowanie ścieżki
			var new_path = [next_node]
			new_path.append_array(sub_problem_result["path"])
			best_solution["path"] = new_path
	
	# wynik zapisany w cache i zwrócony
	memo[state_key] = best_solution
	return best_solution
