extends Control

func _ready():
	$"Przyciski/new game".pressed.connect(_on_start_game_pressed)

	$"Przyciski/simulation mode".pressed.connect(_on_simulation_pressed)
	$Przyciski/exit.pressed.connect(_on_exit_pressed)

func _on_start_game_pressed():
	print("Uruchamianie gry...")
	get_tree().change_scene_to_file("res://Maps/SecurityRoom3D.tscn")

func _on_simulation_pressed():
	
	print("Uruchamianie trybu symulacji...")
	get_tree().change_scene_to_file("res://Maps/SimulationSecurityRoom3D.tscn")

func _on_exit_pressed():
	print("Zamykanie...")
	get_tree().quit()
