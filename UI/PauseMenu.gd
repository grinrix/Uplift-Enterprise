extends Control
@onready var sim_btn = $"PanelContainer/Przyciski/simulation mode"

func _ready():
	$"PanelContainer/Przyciski/resume".pressed.connect(_on_resume_pressed)
	$"PanelContainer/Przyciski/simulation mode".pressed.connect(_on_simulation_pressed)
	$"PanelContainer/Przyciski/exit".pressed.connect(_on_exit_pressed)
	visible = false 
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	testEsc()

func resume():
	get_tree().paused = false
	visible = false
	
func pause():
	get_tree().paused = true
	var current_path = get_tree().current_scene.scene_file_path
	if "Simulation" in current_path:
		sim_btn.text = "Main Menu"
	else:
		sim_btn.text = "Simulation Mode"
	visible = true
	
func testEsc():
	if Input.is_action_just_pressed("escape"):
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_resume_pressed():
	resume()

func _on_simulation_pressed():
	var current_path = get_tree().current_scene.scene_file_path
	
	get_tree().paused = false 
	
	if "Simulation" in current_path:
		print("Wracam do Menu Głównego...")
		get_tree().change_scene_to_file("res://UI/MainMenu.tscn") 
	else:
		print("Uruchamianie trybu symulacji...")
		get_tree().change_scene_to_file("res://Maps/SimulationSecurityRoom3D.tscn")
		
func _on_exit_pressed():
	print("Zamykanie...")
	get_tree().quit()
