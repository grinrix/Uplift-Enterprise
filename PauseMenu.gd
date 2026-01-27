extends Control

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
	print("Uruchamianie trybu symulacji...")
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://SecurityRoom.tscn")

func _on_exit_pressed():
	print("Zamykanie...")
	get_tree().quit()
