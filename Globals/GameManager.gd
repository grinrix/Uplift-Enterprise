extends Node
@onready var elevator = get_parent().get_node("Elevator")
# poziomy trudności dla każdego z 6 pięter
var floor_difficulties = Global.get_current_difficulty() 

# odwołanie do sceny z pasażerami
var passenger_scene = preload("res://Entities/Passenger.tscn")
var floor_height = 100 # to samo co w windzie
var base_y = 0
# timer
var spawn_timer = Timer.new()

# statystyki
var statusPassangersCount := 0
var statusTotalWaitTime := 0
var statusMaxWaitTime := 0

var is_simulation_mode: bool = false

# zmienne do zleceń
signal task_assigned 
var task_timer = Timer.new()       # odlicza czas do zlecenia
var task_deadline_timer = Timer.new() # czas na wykonanie
var is_task_active = false

func _ready():
	base_y = elevator.position.y
	
	# konfiguracja timera
	add_child(spawn_timer)
	spawn_timer.wait_time = 5 # losowanie co 5 sekund
	spawn_timer.timeout.connect(_on_spawn_timer_tick)
	spawn_timer.start()
	elevator.floor_reached.connect(_on_elevator_arrival)
	var switch = get_parent().get_node("ModeSwitch")
	if switch:
		switch.text = "Tryb: Heurystyka"
		switch.toggled.connect(_on_mode_toggled)
	
	# konfiguracja tasków
	add_child(task_timer)
	task_timer.one_shot = true
	task_timer.timeout.connect(_on_task_timer_timeout)
	
	add_child(task_deadline_timer)
	task_deadline_timer.one_shot = true
	task_deadline_timer.timeout.connect(_on_task_deadline_missed)
	
	schedule_next_task()

# logika tasków
func schedule_next_task():
	if Global.is_game_over: return
	is_task_active = false
	# losowy czas np 15-30 sekund
	var wait_time = randf_range(15, 30) 
	task_timer.start(wait_time)

func _on_task_timer_timeout():
	if Global.is_game_over: return
	print("SZEF: Nowe zlecenie, otwórz tablet!")
	is_task_active = true
	emit_signal("task_assigned")
	# 15 sekund na reakcję
	task_deadline_timer.start(15)

func _on_task_deadline_missed():
	if is_task_active:
		print("SZEF: Ignorujesz mnie? Strajk!")
		Global.add_strike("Zignorowanie zlecenia")
		is_task_active = false
		schedule_next_task()

# wywoływane z tabletu po grze
func complete_task_cycle():
	is_task_active = false
	task_deadline_timer.stop()
	schedule_next_task()

# reszta logiki gry
func _on_mode_toggled(button_pressed: bool):
	var switch = get_parent().get_node("ModeSwitch")
	
	if button_pressed:
		switch.text = "Mode: Dynamic"
		elevator.set_mode(true)
	else:
		switch.text = "Mode: Heuristic"
		elevator.set_mode(false)

func _on_spawn_timer_tick():
	# w symulacji nie nadpisujemy trudności z globala
	if not is_simulation_mode:
		floor_difficulties = Global.get_current_difficulty()
		
	# dla każdego piętra sprawdzamy czy zespawnować pasażera
	for floor_idx in range(6):
		var difficulty = floor_difficulties[floor_idx]
		# losujemy liczbę od 0 do 20
		var roll = randi() % 21 
		
		# jeśli wylosowano mniej niż trudność -> spawn
		if roll < difficulty:
			spawn_passenger(floor_idx)
		
		# opcja "szczyt" - jeśli trudność max (20) i wylosowano 20 -> spawnuj 5 na raz
		elif roll == 20 and difficulty == 20: 
			for i in range(5):
				spawn_passenger(floor_idx)

func spawn_passenger(floor_idx):
	var new_passenger = passenger_scene.instantiate()
	get_parent().add_child(new_passenger)
	
	# losuj piętro docelowe (inne niż startowe)
	var target_floor = randi() % 6
	while target_floor == floor_idx:
		target_floor = randi() % 6
		
	new_passenger.setup_passenger(floor_idx, target_floor)
	
	# ustaw pozycję (poza ekranem po lewej)
	var spawn_y = base_y - (floor_idx * floor_height) 
	
	# losowa pozycja w kolejce
	var shaft_x = get_parent().get_node("ElevatorShaft").position.x
	var waiting_spot_x = shaft_x - 60 - (randi() % 60)
	
	var start_x = -50
	new_passenger.position = Vector2(start_x, spawn_y)
	
	# idź do windy
	new_passenger.walk_to(waiting_spot_x)
	
	# podłącz sygnał przycisku
	new_passenger.button_pressed.connect(_on_passenger_button_pressed)

func _on_passenger_button_pressed(floor_number, passenger):
	# jeśli winda jest na tym piętrze i otwarta -> wsiadaj
	if elevator.current_floor == floor_number and elevator.doors_open:
		_start_boarding_sequence(passenger)
	else:
		# dodaj wezwanie do windy
		elevator.add_stop(floor_number)

func _on_elevator_arrival(floor_idx):
	# pasażerowie w windzie wychodzą
	passengers_boarding_count = 0 
	for passenger in elevator.get_children():
		if passenger.has_method("leave_elevator"):
			if passenger.target_floor == floor_idx:
				passenger.leave_elevator()
	
	# pasażerowie na piętrze wsiadają
	var waiting_passengers = get_parent().get_children()
	var anyone_waiting = false
	
	for passenger in waiting_passengers:
		if passenger.has_method("start_boarding"):
			# sprawdzamy czy jest na tym piętrze i czy czeka
			if passenger.start_floor == floor_idx and passenger.current_state == passenger.State.WAITING:
				_start_boarding_sequence(passenger)
				anyone_waiting = true
	
	# jeśli nikt nie wsiada, zamykamy drzwi od razu (chyba że winda ma inne cele)
	if not anyone_waiting:
		elevator.close_doors()

var passengers_boarding_count = 0

func _start_boarding_sequence(passenger):
	passengers_boarding_count += 1
	
	# podłączamy sygnał 'boarded' jednorazowo
	if not passenger.boarded.is_connected(_on_passenger_entered):
		passenger.boarded.connect(_on_passenger_entered.bind(passenger), CONNECT_ONE_SHOT)
	
	passenger.start_boarding(elevator)
	elevator.add_stop(passenger.target_floor) 

func _on_passenger_entered(passenger):
	passengers_boarding_count -= 1
	# jeśli wszyscy wsiedli
	if passengers_boarding_count <= 0:
		# małe opóźnienie dla naturalności
		await get_tree().create_timer(0.2).timeout
		if passengers_boarding_count <= 0:
			elevator.close_doors()

# zbieranie statystyk (wywoływane przez pasażera)
func register_passenger(passenger):
	var wait_time = passenger.on_enter_elevator()
	statusPassangersCount += 1
	statusTotalWaitTime += wait_time
	if wait_time > statusMaxWaitTime:
		statusMaxWaitTime = wait_time
		
# statystyki tłumu (dla trybu dynamicznego)
func get_crowd_stats() -> Dictionary:
	var crowd = {0:0, 1:0, 2:0, 3:0, 4:0, 5:0}
	
	# liczymy ludzi czekających na piętrach
	for child in get_parent().get_children():
		if child.has_method("start_boarding"):
			if child.current_state == 1: # WAITING
				var floor_idx = child.start_floor
				if crowd.has(floor_idx):
					crowd[floor_idx] += 1
					
	# liczymy ludzi w windzie (wg piętra docelowego)
	for passenger in elevator.get_children():
		if "target_floor" in passenger:
			var dest_floor = passenger.target_floor
			if crowd.has(dest_floor):
				crowd[dest_floor] += 1
				
	return crowd

func clear_all_passengers():
	print("Czyszczenie wszystkich pasażerów...")
	# usuwa czekających na korytarzu
	for child in get_parent().get_children():
		if child.has_method("start_boarding"): # To pasażer
			child.queue_free()
	# usuwa tych w windzie
	for passenger in elevator.get_children():
		if passenger.has_method("leave_elevator"): # To pasażer
			passenger.queue_free()
			
	# resetuj zmienne windy/kolejki
	elevator.target_queue.clear()
	elevator.is_moving = false
	elevator.doors_open = true # zresetuj drzwi
	passengers_boarding_count = 0

# ręczne dodanie pasażera
func force_spawn_passenger(from_floor: int, to_floor: int):
	# jeśli wybrano -1 (losowe) wylosuj
	if to_floor == -1:
		to_floor = randi() % 6
		while to_floor == from_floor:
			to_floor = randi() % 6
			
	print("Ręczny spawn: ", from_floor, " -> ", to_floor)
	
	var new_passenger = passenger_scene.instantiate()
	get_parent().add_child(new_passenger)
	new_passenger.setup_passenger(from_floor, to_floor)
	
	var spawn_y = base_y - (from_floor * floor_height)
	var shaft_x = get_parent().get_node("ElevatorShaft").position.x
	var waiting_spot_x = shaft_x - 60 - (randi() % 60)
	
	new_passenger.position = Vector2(-50, spawn_y)
	new_passenger.walk_to(waiting_spot_x)
	new_passenger.button_pressed.connect(_on_passenger_button_pressed)

# ustawianie trudności (dla symulacji)
func set_floor_difficulty(floor_idx: int, value: int):
	if floor_idx >= 0 and floor_idx < floor_difficulties.size():
		floor_difficulties[floor_idx] = value
# tymczasowe do testów
func _input(event):
	# jak wciśniesz T na klawiaturze -> szef dzwoni
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		print("DEBUG: Wymuszam zadanie!")
		_on_task_timer_timeout()
