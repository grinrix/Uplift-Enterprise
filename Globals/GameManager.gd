extends Node
@onready var elevator = get_parent().get_node("Elevator")
# poziomy trudności dla każdego z 6 pięter
var floor_difficulties = Global.get_current_difficulty() 

# odwołanie do sceny z pasażerami
var passenger_scene = preload("res://Entities/Passenger.tscn")
var floor_height = 100.0 # to samo co w windzie
var base_y = 0.0
# timer
var spawn_timer = Timer.new()

# statystyki
var statusPassangersCount := 0
var statusTotalWaitTime := 0.0
var statusMaxWaitTime := 0.0

var is_simulation_mode: bool = false

func _ready():
	base_y = elevator.position.y
	
	# konfiguracja timera
	add_child(spawn_timer)
	spawn_timer.wait_time = 5.0 # losowanie co 5 sekund
	spawn_timer.timeout.connect(_on_spawn_timer_tick)
	spawn_timer.start()
	elevator.floor_reached.connect(_on_elevator_arrival)
	var switch = get_parent().get_node("ModeSwitch")
	switch.text = "Tryb: Heurystyka"
	switch.toggled.connect(_on_mode_toggled)
	

func _on_mode_toggled(button_pressed: bool):
	var switch = get_parent().get_node("ModeSwitch")
	
	if button_pressed:
		switch.text = "Mode: Dynamic"
		elevator.set_mode(true)
	else:
		switch.text = "Mode: Heurystic"
		elevator.set_mode(false)

func _on_spawn_timer_tick():
	if not is_simulation_mode:
		floor_difficulties = Global.get_current_difficulty()
	print("LOSOWANIE:")
	# pętla dla każdeko piętra
	for floor_idx in range(6):
		var difficulty = floor_difficulties[floor_idx]
		var roll = randi() % 21 # losowana liczba od 0 do 20
		if roll < difficulty:
			spawn_passenger(floor_idx)
			print("Piętro ", floor_idx, ": nowy pasażer! (Roll: ", roll, " < Diff: ", difficulty, ")")
		elif roll == 20 and difficulty == 20: # to jest takie combo 
			for i in range(5):
				spawn_passenger(floor_idx)
			print("Piętro ", floor_idx, ": FALA PASAŻERÓW! (Roll: 20)")

func spawn_passenger(floor_idx):
	var new_passenger = passenger_scene.instantiate()
	get_parent().add_child(new_passenger)
	
	var target_floor = randi() % 6 # losuje piętra
	
	# żeby nie wylosowało tego samego
	while target_floor == floor_idx:
		target_floor = randi() % 6
	
	# dane idą do pasażera
	new_passenger.setup_passenger(floor_idx, target_floor)
	
	var spawn_y = base_y - (floor_idx * floor_height) # obliczanie Y dla pasażera
	
	# to zatrzymuje pasażera w losowe miejsce obok windy (żeby było bardziej naturalnie, a nie że każdy czeka w tym samym punktcie)
	var shaft_x = get_parent().get_node("ElevatorShaft").position.x
	var waiting_spot_x = shaft_x - 60 - (randi() % 60)
	
	var start_x = -50.0 # punkt startowy (poza mapą) 
	
	new_passenger.position = Vector2(start_x, spawn_y)
	new_passenger.walk_to(waiting_spot_x)
	new_passenger.button_pressed.connect(_on_passenger_button_pressed)

func _on_passenger_button_pressed(floor_number, passenger):
	print("Pasażer zgłasza się na piętrze: ", floor_number)
	
	# sprawdza czy winda już tu jest i czy ma otwarte drzwi
	if elevator.current_floor == floor_number and elevator.doors_open:
		print(">> Winda jest na miejscu! Pasażer wsiada z biegu.")
		_start_boarding_sequence(passenger)
	else:
		print(">> Winda wezwana.")
		elevator.add_stop(floor_number)

# licznik ile pasażerów właśnie wsiada
var passengers_boarding_count: int = 0

# gdy winda przyjedzie na piętro
func _on_elevator_arrival(floor_idx):
	print("Winda otwiera drzwi na: ", floor_idx)
	passengers_boarding_count = 0 # Reset licznika
	
	# wysiadanie
	for passenger in elevator.get_children():
		if passenger.has_method("leave_elevator"):
			if passenger.target_floor == floor_idx:
				passenger.leave_elevator()
	
	# wsiadanie
	var waiting_passengers = get_parent().get_children()
	var anyone_waiting = false
	
	for passenger in waiting_passengers:
		if passenger.has_method("start_boarding"):
			# sprawdza czy ktoś czeka
			if passenger.start_floor == floor_idx and passenger.current_state == passenger.State.WAITING:
				_start_boarding_sequence(passenger)
				anyone_waiting = true
	
	# jak nikt nie czeka to zamykamy drzwi
	# jeśli ktoś się lekko spoźni ale zdąży wcisnąć guzi to _on_passenger_button_pressed otworzy je z powrotem
	if not anyone_waiting:
		elevator.close_doors()


# funkcja obsługująca pojedynczego pasażera
func _start_boarding_sequence(passenger):
	# zwiększamy licznik aby winda wiedziała że musi czekać
	passengers_boarding_count += 1
	
	# podłączamy sygnał zakończenia wchodzenia
	if not passenger.boarded.is_connected(_on_passenger_entered):
		passenger.boarded.connect(_on_passenger_entered.bind(passenger), CONNECT_ONE_SHOT)
	# pasażer wchodzi
	passenger.start_boarding(elevator)
	elevator.add_stop(passenger.target_floor) # dodajemy cel pasażera do kolejki windy


# gdy pasażer znajdzie się w środku
func _on_passenger_entered(passenger):
	passengers_boarding_count -= 1
	print("Pasażer wsiadł. Pozostało do wejścia: ", passengers_boarding_count)
	
	# drzwi są zamykane jeżeli licznik spada do zera
	if passengers_boarding_count <= 0:
		await get_tree().create_timer(0.2).timeout
		# sprawdzamy ponownie czy ktoś kolejny nie zaczął wsiadać
		if passengers_boarding_count <= 0:
			elevator.close_doors()

# do statystyk
func register_passenger(passenger):
	var wait_time = passenger.on_enter_elevator()

	statusPassangersCount += 1
	statusTotalWaitTime += wait_time

	if wait_time > statusMaxWaitTime:
		statusMaxWaitTime = wait_time
		
func get_crowd_stats() -> Dictionary:
	var crowd = {0:0, 1:0, 2:0, 3:0, 4:0, 5:0}
	
	# liczymy ludzi czekających NA KORYTARZACH
	for child in get_parent().get_children():
		if child.has_method("start_boarding"): # pasażer
			if child.current_state == 1: # 1 to WAITING
				# dodajemy wagę do piętra na którym stoi
				var floor_idx = child.start_floor
				if crowd.has(floor_idx):
					crowd[floor_idx] += 1

	# liczymy ludzi W ŚRODKU WINDY
	for passenger in elevator.get_children():
		# sprawdzamy czy to pasażer
		if "target_floor" in passenger:
			var dest_floor = passenger.target_floor
			# dodajemy wagę do piętra do którego jadą
			if crowd.has(dest_floor):
				crowd[dest_floor] += 1
	
	return crowd

# reset pasażerów
func clear_all_passengers():
	print("[SIM] Usuwanie wszystkich pasażerów...")
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
	# -1 losowe
	if from_floor == -1:
		from_floor = randi() % 6
	
	# jak jest -1 to losowe
	if to_floor == -1:
		to_floor = randi() % 6
		# aby nie jechał na to samo piętro
		while to_floor == from_floor:
			to_floor = randi() % 6
			
	print("Ręczny spawn: ", from_floor, " -> ", to_floor)
	
	var new_passenger = passenger_scene.instantiate()
	get_parent().add_child(new_passenger)
	new_passenger.setup_passenger(from_floor, to_floor)
	
	var spawn_y = base_y - (from_floor * floor_height)
	var shaft_node = get_parent().get_node_or_null("ElevatorShaft")
	var shaft_x = 1077
	if shaft_node:
		shaft_x = shaft_node.position.x
		
	var waiting_spot_x = shaft_x - 60 - (randi() % 60)
	
	new_passenger.position = Vector2(-50, spawn_y)
	new_passenger.walk_to(waiting_spot_x)
	new_passenger.button_pressed.connect(_on_passenger_button_pressed)

# zmiana trudności w symulacji
func set_floor_difficulty(floor_idx: int, value: int):
	if floor_idx >= 0 and floor_idx < floor_difficulties.size():
		floor_difficulties[floor_idx] = value
		print("Trudność piętra ", floor_idx, " ustawiona na ", value)
