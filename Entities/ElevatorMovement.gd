extends Sprite2D
signal floor_reached(floor_number)
enum AlgorithmMode { HEURISTIC, DYNAMIC }
var current_mode = AlgorithmMode.HEURISTIC

# konfiguracja
var current_floor: int = 0
var total_floors: int = 5
var floor_height: float = 100.0 # odległość w pikselach między piętrami
var base_y_position: float = 0.0 # pozycja Y piętra 0
var travel_speed: float = 0.5 # czas przejazdu jednego piętra w sekundach

# stan windy
var is_moving: bool = false
var target_queue: Array = [] # piętra do których winda musi pojechać
var doors_open: bool = false

var has_power: bool = true

func set_power_state(status: bool):
	has_power = status
	if not has_power:
		print("Winda zatrzymana z braku prądu!")

# przełączanie między trybami
func set_mode(is_dp: bool):
	if is_dp:
		current_mode = AlgorithmMode.DYNAMIC
		print("Mode: Dynamic")
	else:
		current_mode = AlgorithmMode.HEURISTIC
		print("Mode: Heuristic")
	
	# po zmianie trybu przeliczy kolejkę
	recalculate_path()
	
	
func _ready():
	# zapamiętuje pozycję startową jako parter
	base_y_position = position.y

func _process(delta):
	if not has_power: 
		return 
	## sterowanie windy klawiaturą
	#if Input.is_action_just_pressed("ui_up") and not is_moving:
		#go_to_floor(current_floor + 1)
	#if Input.is_action_just_pressed("ui_down") and not is_moving:
		#go_to_floor(current_floor - 1)
	## sterowanie automatyczne
	if not is_moving and not doors_open and target_queue.size() > 0:
		# wyciąga pierwszy cel z listy FIFO
		var next_floor = target_queue.pop_front()
		go_to_floor(next_floor)
		
# STARA WERSCJA
#func add_stop(floor_idx: int):
	#if floor_idx not in target_queue and floor_idx != current_floor: # sprawdza czy już piętra nie ma w kolejce
		#target_queue.append(floor_idx)
		#print("Winda przyjęła zgłoszenie na piętro: ", floor_idx)
		#print("Aktualna kolejka: ", target_queue)
		
func add_stop(floor_number: int):
	# 1. Jeśli winda już tu jest, stoi w miejscu i ma zamknięte drzwi -> OTWÓRZ NATYCHMIAST
	if floor_number == current_floor and not is_moving and not doors_open:
		print("Winda już jest na piętrze ", floor_number, " -> Otwieram drzwi.")
		# Symulujemy dotarcie na piętro
		floor_reached.emit(current_floor)
		doors_open = true
		return

	# 2. Jeśli winda już tu jest i ma OTWARTE drzwi -> Ignoruj (już obsługuje to piętro)
	if floor_number == current_floor and doors_open:
		return

	# 3. Standardowe dodanie do kolejki (jeśli piętro jest inne)
	if floor_number not in target_queue:
		target_queue.append(floor_number)
		target_queue.sort() # Sortowanie (dla trybu heurystycznego)
		
		# Jeśli jesteśmy w trybie dynamicznym, przelicz trasę
		if current_mode == AlgorithmMode.DYNAMIC:
			recalculate_path()
			
func recalculate_path():
	if target_queue.is_empty(): return
	match current_mode:
		AlgorithmMode.HEURISTIC:
			optimize_heuristic()
		AlgorithmMode.DYNAMIC:
			optimize_dynamic()
			
	print("Zoptymalizowana kolejka: ", target_queue)

# funkcja zlecająca ruch windy
func go_to_floor(target_floor_idx: int):
	# zabezpieczenie przed wyjazdem poza budynek
	if target_floor_idx < 0 or target_floor_idx > total_floors:
		print("Błąd: Nie ma takiego piętra!")
		return
	
	if target_floor_idx == current_floor:
		return

	is_moving = true
	print("Jadę na piętro: ", target_floor_idx)
	
	# obliczanie nową pozycję Y
	var new_y = base_y_position - (target_floor_idx * floor_height)
	# im wyższe piętro tym mniejszy Y
		
	# obliczanie czas podróży
	var distance = abs(target_floor_idx - current_floor)
	var travel_time = distance * travel_speed
	
	# płynny ruch windy
	var tween = create_tween()
	# "property" to co zmieniamy "final_val" na co
	# "duration" ile czasu
	tween.tween_property(self, "position:y", new_y, travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	current_floor = target_floor_idx
	is_moving = false
	print("Dojechałem na piętro: ", current_floor)
	doors_open = true 
	floor_reached.emit(current_floor)
	
	
func close_doors():
	if not doors_open: return # żeby nie zamykać dwa razy
	
	await get_tree().create_timer(0.5).timeout
	doors_open = false
	print("Drzwi zamknięte. Gotowy do jazdy.")

# HEURISTIC
func optimize_heuristic():
	# kolejka jest sortowana tak aby następny cel był zawsze najbliżej poprzedniego
	
	var sorted_queue = []
	var temp_queue = target_queue.duplicate() # tymczasowa lista dla pięter
	var current_pos = current_floor
	
	while not temp_queue.is_empty():
		var nearest_idx = -1
		var min_dist = 99
		
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
	
# DYNAMICZNE
var min_path_sum = 99
var best_path = []
var priority_weight: float = 100
# cache dla danych o tłumie
var current_crowd_data = {}

func optimize_dynamic():
	# pobieramy dane o tłumie przed obliczeniami
	var gm = get_tree().root.find_child("GameManager", true, false)
	if gm:
		current_crowd_data = gm.get_crowd_stats()
	else:
		current_crowd_data = {0:0, 1:0, 2:0, 3:0, 4:0, 5:0}
	# start algorytmu
	min_path_sum = 99999
	best_path = []
	
	# rekurencja
	_solve_dynamic(current_floor, target_queue.duplicate(), 0.0, [])
	
	if not best_path.is_empty():
		target_queue = best_path
	
	print("Dynamiczna trasa (z priorytetami): ", target_queue)


func _solve_dynamic(current_node, nodes_to_visit, current_score, path_so_far):
	if nodes_to_visit.is_empty():
		if current_score < min_path_sum:
			min_path_sum = current_score
			best_path = path_so_far.duplicate()
		return

	# jeśli wynik jest okropny to przerywamy
	if current_score >= min_path_sum:
		return

	for i in range(nodes_to_visit.size()):
		var next_node = nodes_to_visit[i]
		# odległość
		var dist = abs(next_node - current_node)
		
		# priorytet
		var people_count = current_crowd_data.get(next_node, 0)
		var priority_bonus = people_count * priority_weight
		
		# jeżeli dużo ludzi czeka to tam jedziemy
		var step_cost = dist - priority_bonus
		var new_nodes = nodes_to_visit.duplicate()
		new_nodes.remove_at(i)
		var new_path = path_so_far.duplicate()
		new_path.append(next_node)
		_solve_dynamic(next_node, new_nodes, current_score + step_cost, new_path)
