extends Control

# Referencje do UI
@onready var spins_diff = [
	$VBoxContainer/GridContainer/Spin0,
	$VBoxContainer/GridContainer/Spin1,
	$VBoxContainer/GridContainer/Spin2,
	$VBoxContainer/GridContainer/Spin3,
	$VBoxContainer/GridContainer/Spin4,
	$VBoxContainer/GridContainer/Spin5
]
@onready var button_reset = $VBoxContainer/ButtonReset
@onready var spin_from = $VBoxContainer/HBoxContainer/FromSpin
@onready var spin_to = $VBoxContainer/HBoxContainer/ToSpin
@onready var button_spawn = $VBoxContainer/HBoxContainer/ButtonSpawn

var game_manager = null

func _ready():
	# szukamy GameManagera
	await get_tree().process_frame
	await get_tree().process_frame
	
	# próbujemy znaleźć w głównym drzewie
	game_manager = get_tree().root.find_child("GameManager", true, false)
	var clock = find_child("Clock", true, false)
	
	if clock:
		clock.visible = false
		print("[SIM ROOM] Zegar został ukryty.")
	else:
		print("[SIM ROOM] BŁĄD: Nie znaleziono węzła o nazwie 'Clock'!")
		
	if game_manager:
		print("[PANEL] Połączono z GameManagerem!")
		game_manager.is_simulation_mode = true
		game_manager.floor_difficulties = [0, 0, 0, 0, 0, 0]
		game_manager.clear_all_passengers()
		# wczytuje początkowe wartości
		for i in range(6):
			if i < game_manager.floor_difficulties.size():
				spins_diff[i].value = game_manager.floor_difficulties[i]
				
		# sygnał jest podłączany
		if not button_reset.pressed.is_connected(_on_reset):
			button_reset.pressed.connect(_on_reset)
			button_spawn.pressed.connect(_on_spawn)
			
			for i in range(6):
				# stare połączenia są odłączone
				if not spins_diff[i].value_changed.is_connected(_on_diff_changed):
					spins_diff[i].value_changed.connect(_on_diff_changed.bind(i))
	else:
		print("[PANEL] BŁĄD KRYTYCZNY: paniel nie widzi game managera")

func _on_diff_changed(val, idx):
	if game_manager:
		game_manager.set_floor_difficulty(idx, int(val))

func _on_reset():
	if game_manager:
		game_manager.clear_all_passengers()

func _on_spawn():
	if game_manager:
		game_manager.force_spawn_passenger(int(spin_from.value), int(spin_to.value))
