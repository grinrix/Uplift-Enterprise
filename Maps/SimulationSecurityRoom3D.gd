extends Node3D

# Zmienne globalne
var is_dynamic_mode = false
@onready var bg_rect = $Hardware/SwitchViewport/StatusBackground
@onready var mode_label = $Hardware/SwitchViewport/ModeSwitch
@onready var elevator = find_child("Elevator", true, false)
@onready var switch_viewport = $Hardware/SwitchViewport
@onready var switch_sprite = $SwitchMode

func _ready():
	await get_tree().process_frame
	# KONFIGURACJE
	# viewport
	switch_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	switch_sprite.texture = switch_viewport.get_texture()
	bg_rect.color = Color.RED
	mode_label.text = "Mode: Heuristic"
	# global
	Global.is_simulation = true
	# zegar
	var cam = find_child("Camera3D", true, false)
	if cam and cam.has_method("move_clock_to_side"):
		cam.move_clock_to_side()
		cam.shift_time_left = -1.0 
	else:
		print("BŁĄD: Nie znaleziono kamery lub funkcji move_clock_to_side!")
	# game manager
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager:
		print("[SIM ROOM] Ustawiam tryb symulacji w Managerze.")
		game_manager.is_simulation_mode = true
		game_manager.floor_difficulties = [0, 0, 0, 0, 0, 0]
		game_manager.clear_all_passengers()

# obsługa wyjścia z symulacji
func _exit_tree():
	Global.is_simulation = false

# zmiana trybu
func on_switch_clicked():
	is_dynamic_mode = !is_dynamic_mode
	mode_label.button_pressed = is_dynamic_mode
	
	if is_dynamic_mode:
		bg_rect.color = Color.GREEN
		mode_label.text = "Mode: Dynamic"
		if elevator: elevator.set_mode(true)
	else:
		bg_rect.color = Color.RED
		mode_label.text = "Mode: Heuristic"
		if elevator: elevator.set_mode(false)
